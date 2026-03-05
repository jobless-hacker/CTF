from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field
from hashlib import sha256
from math import ceil
from threading import Lock
from time import monotonic, time
from typing import Any, Protocol
from uuid import uuid4

from app.core.settings import get_settings


@dataclass(frozen=True, slots=True)
class InMemoryRateLimitDecision:
    allowed: bool
    retry_after_seconds: int | None


class SlidingWindowRateLimiter(Protocol):
    def check_and_consume(
        self,
        *,
        key: str,
        max_attempts: int,
        window_seconds: int,
        lock_seconds: int,
    ) -> InMemoryRateLimitDecision: ...

    def reset(self) -> None: ...


@dataclass(slots=True)
class _KeyRateLimitState:
    attempts: deque[float] = field(default_factory=deque)
    lock_until: float | None = None


class InMemorySlidingWindowRateLimiter:
    def __init__(self) -> None:
        self._states: dict[str, _KeyRateLimitState] = {}
        self._lock = Lock()

    def check_and_consume(
        self,
        *,
        key: str,
        max_attempts: int,
        window_seconds: int,
        lock_seconds: int,
    ) -> InMemoryRateLimitDecision:
        _validate_rate_limit_params(
            key=key,
            max_attempts=max_attempts,
            window_seconds=window_seconds,
            lock_seconds=lock_seconds,
        )

        now = monotonic()
        window_floor = now - window_seconds
        normalized_key = key.strip()

        with self._lock:
            state = self._states.setdefault(normalized_key, _KeyRateLimitState())
            self._prune_attempts(state.attempts, window_floor)

            if state.lock_until is not None:
                if state.lock_until > now:
                    retry_after_seconds = self._retry_after_seconds(state.lock_until, now)
                    return InMemoryRateLimitDecision(
                        allowed=False,
                        retry_after_seconds=retry_after_seconds,
                    )
                state.lock_until = None

            if len(state.attempts) >= max_attempts:
                state.lock_until = now + lock_seconds
                return InMemoryRateLimitDecision(
                    allowed=False,
                    retry_after_seconds=lock_seconds,
                )

            state.attempts.append(now)
            return InMemoryRateLimitDecision(allowed=True, retry_after_seconds=None)

    def reset(self) -> None:
        with self._lock:
            self._states.clear()

    @staticmethod
    def _prune_attempts(attempts: deque[float], window_floor: float) -> None:
        while attempts and attempts[0] <= window_floor:
            attempts.popleft()

    @staticmethod
    def _retry_after_seconds(lock_until: float, now: float) -> int:
        return max(1, ceil(lock_until - now))


class RedisSlidingWindowRateLimiter:
    _SLIDING_WINDOW_SCRIPT = """
local attempts_key = KEYS[1]
local lock_key = KEYS[2]

local now_ms = tonumber(ARGV[1])
local window_ms = tonumber(ARGV[2])
local max_attempts = tonumber(ARGV[3])
local lock_ms = tonumber(ARGV[4])
local member = ARGV[5]
local data_ttl_ms = tonumber(ARGV[6])

local lock_ttl = redis.call('PTTL', lock_key)
if lock_ttl > 0 then
  return {0, lock_ttl}
end

redis.call('ZREMRANGEBYSCORE', attempts_key, '-inf', now_ms - window_ms)
local count = redis.call('ZCARD', attempts_key)
if count >= max_attempts then
  redis.call('PSETEX', lock_key, lock_ms, '1')
  redis.call('PEXPIRE', attempts_key, data_ttl_ms)
  return {0, lock_ms}
end

redis.call('ZADD', attempts_key, now_ms, member)
redis.call('PEXPIRE', attempts_key, data_ttl_ms)
return {1, 0}
""".strip()

    def __init__(self, *, redis_client: Any, key_prefix: str, scope: str) -> None:
        self._redis = redis_client
        self._key_prefix = key_prefix.strip() or "zerotrace:rate_limit"
        self._scope = scope.strip()
        self._script = self._redis.register_script(self._SLIDING_WINDOW_SCRIPT)

    def check_and_consume(
        self,
        *,
        key: str,
        max_attempts: int,
        window_seconds: int,
        lock_seconds: int,
    ) -> InMemoryRateLimitDecision:
        _validate_rate_limit_params(
            key=key,
            max_attempts=max_attempts,
            window_seconds=window_seconds,
            lock_seconds=lock_seconds,
        )

        normalized_key = key.strip()
        key_digest = sha256(normalized_key.encode("utf-8")).hexdigest()
        attempts_key = f"{self._key_prefix}:{self._scope}:{key_digest}:attempts"
        lock_key = f"{self._key_prefix}:{self._scope}:{key_digest}:lock"

        now_ms = int(time() * 1000)
        window_ms = window_seconds * 1000
        lock_ms = lock_seconds * 1000
        # keep temporary key state slightly longer than window+lock
        data_ttl_ms = (window_seconds + lock_seconds + 5) * 1000
        member = f"{now_ms}:{uuid4().hex}"

        result = self._script(
            keys=[attempts_key, lock_key],
            args=[now_ms, window_ms, max_attempts, lock_ms, member, data_ttl_ms],
        )
        allowed = bool(int(result[0]))
        retry_after_ms = int(result[1])
        retry_after_seconds = max(1, ceil(retry_after_ms / 1000)) if retry_after_ms > 0 else None

        return InMemoryRateLimitDecision(
            allowed=allowed,
            retry_after_seconds=retry_after_seconds,
        )

    def reset(self) -> None:
        match_pattern = f"{self._key_prefix}:{self._scope}:*"
        cursor: int = 0
        while True:
            cursor, keys = self._redis.scan(cursor=cursor, match=match_pattern, count=500)
            if keys:
                self._redis.delete(*keys)
            if cursor == 0:
                break


class DistributedSlidingWindowRateLimiter:
    def __init__(self, *, scope: str) -> None:
        self._scope = scope.strip()
        self._memory_backend: SlidingWindowRateLimiter = InMemorySlidingWindowRateLimiter()
        self._redis_backend: SlidingWindowRateLimiter | None = None
        self._backend_identity: tuple[str, str, str, int] | None = None
        self._lock = Lock()

    def check_and_consume(
        self,
        *,
        key: str,
        max_attempts: int,
        window_seconds: int,
        lock_seconds: int,
    ) -> InMemoryRateLimitDecision:
        backend = self._select_backend()
        try:
            return backend.check_and_consume(
                key=key,
                max_attempts=max_attempts,
                window_seconds=window_seconds,
                lock_seconds=lock_seconds,
            )
        except Exception:
            # Keep service availability even if Redis is transiently unavailable.
            return self._memory_backend.check_and_consume(
                key=key,
                max_attempts=max_attempts,
                window_seconds=window_seconds,
                lock_seconds=lock_seconds,
            )

    def reset(self) -> None:
        self._memory_backend.reset()
        with self._lock:
            redis_backend = self._redis_backend
        if redis_backend is None:
            return
        try:
            redis_backend.reset()
        except Exception:
            return

    def _select_backend(self) -> SlidingWindowRateLimiter:
        settings = get_settings()
        backend_name = settings.RATE_LIMIT_BACKEND
        redis_url = (settings.RATE_LIMIT_REDIS_URL or "").strip()
        key_prefix = settings.RATE_LIMIT_REDIS_KEY_PREFIX.strip()
        timeout_ms = settings.RATE_LIMIT_REDIS_SOCKET_TIMEOUT_MS

        if backend_name != "redis" or not redis_url:
            return self._memory_backend

        identity = (backend_name, redis_url, key_prefix, timeout_ms)
        with self._lock:
            if identity != self._backend_identity:
                self._redis_backend = self._build_redis_backend(
                    redis_url=redis_url,
                    key_prefix=key_prefix,
                    timeout_ms=timeout_ms,
                )
                self._backend_identity = identity

            if self._redis_backend is not None:
                return self._redis_backend

        return self._memory_backend

    def _build_redis_backend(
        self,
        *,
        redis_url: str,
        key_prefix: str,
        timeout_ms: int,
    ) -> SlidingWindowRateLimiter | None:
        try:
            import redis
        except Exception:
            return None

        timeout_seconds = max(0.01, timeout_ms / 1000)
        try:
            client = redis.Redis.from_url(
                redis_url,
                decode_responses=True,
                socket_connect_timeout=timeout_seconds,
                socket_timeout=timeout_seconds,
                retry_on_timeout=True,
            )
            client.ping()
        except Exception:
            return None

        return RedisSlidingWindowRateLimiter(
            redis_client=client,
            key_prefix=key_prefix,
            scope=self._scope,
        )


def _validate_rate_limit_params(
    *,
    key: str,
    max_attempts: int,
    window_seconds: int,
    lock_seconds: int,
) -> None:
    normalized_key = key.strip()
    if not normalized_key:
        raise ValueError("Rate limit key must not be empty.")
    if max_attempts < 1:
        raise ValueError("max_attempts must be at least 1.")
    if window_seconds < 1:
        raise ValueError("window_seconds must be at least 1.")
    if lock_seconds < 1:
        raise ValueError("lock_seconds must be at least 1.")


auth_rate_limiter = DistributedSlidingWindowRateLimiter(scope="auth")
lab_command_rate_limiter = DistributedSlidingWindowRateLimiter(scope="lab")
