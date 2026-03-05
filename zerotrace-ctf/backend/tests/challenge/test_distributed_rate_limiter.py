from __future__ import annotations

from types import SimpleNamespace
import sys

from app.core.settings import get_settings
from app.services.in_memory_rate_limiter import DistributedSlidingWindowRateLimiter


class _FakeRedisClient:
    def __init__(self) -> None:
        self._attempts: dict[str, list[int]] = {}
        self._locks: dict[str, int] = {}

    def ping(self) -> bool:
        return True

    def register_script(self, _script: str):
        def _runner(*, keys, args):
            attempts_key, lock_key = keys
            now_ms = int(args[0])
            window_ms = int(args[1])
            max_attempts = int(args[2])
            lock_ms = int(args[3])

            lock_until = self._locks.get(lock_key)
            if lock_until is not None and lock_until > now_ms:
                return [0, lock_until - now_ms]
            if lock_until is not None and lock_until <= now_ms:
                self._locks.pop(lock_key, None)

            pruned = [
                timestamp
                for timestamp in self._attempts.get(attempts_key, [])
                if timestamp > now_ms - window_ms
            ]
            if len(pruned) >= max_attempts:
                self._locks[lock_key] = now_ms + lock_ms
                self._attempts[attempts_key] = pruned
                return [0, lock_ms]

            pruned.append(now_ms)
            self._attempts[attempts_key] = pruned
            return [1, 0]

        return _runner

    def scan(self, cursor: int, match: str, count: int = 500):
        _ = count
        prefix = match.rstrip("*")
        keys = [
            key
            for key in [*self._attempts.keys(), *self._locks.keys()]
            if key.startswith(prefix)
        ]
        return (0, keys)

    def delete(self, *keys: str) -> int:
        deleted = 0
        for key in keys:
            if key in self._attempts:
                self._attempts.pop(key, None)
                deleted += 1
            if key in self._locks:
                self._locks.pop(key, None)
                deleted += 1
        return deleted


def test_distributed_limiter_falls_back_without_redis_module(monkeypatch) -> None:
    monkeypatch.setenv("RATE_LIMIT_BACKEND", "redis")
    monkeypatch.setenv("RATE_LIMIT_REDIS_URL", "redis://localhost:6379/0")
    get_settings.cache_clear()

    monkeypatch.setitem(sys.modules, "redis", None)
    limiter = DistributedSlidingWindowRateLimiter(scope="auth")

    first = limiter.check_and_consume(
        key="auth:login:127.0.0.1",
        max_attempts=1,
        window_seconds=60,
        lock_seconds=5,
    )
    second = limiter.check_and_consume(
        key="auth:login:127.0.0.1",
        max_attempts=1,
        window_seconds=60,
        lock_seconds=5,
    )

    assert first.allowed is True
    assert second.allowed is False
    assert second.retry_after_seconds == 5
    get_settings.cache_clear()


def test_distributed_limiter_blocks_across_instances_with_redis_backend(monkeypatch) -> None:
    fake_client = _FakeRedisClient()
    fake_redis_module = SimpleNamespace(
        Redis=SimpleNamespace(from_url=lambda *args, **kwargs: fake_client),
    )

    monkeypatch.setenv("RATE_LIMIT_BACKEND", "redis")
    monkeypatch.setenv("RATE_LIMIT_REDIS_URL", "redis://localhost:6379/0")
    monkeypatch.setenv("RATE_LIMIT_REDIS_KEY_PREFIX", "zerotrace:test:rl")
    get_settings.cache_clear()
    monkeypatch.setitem(sys.modules, "redis", fake_redis_module)

    limiter_one = DistributedSlidingWindowRateLimiter(scope="auth")
    limiter_two = DistributedSlidingWindowRateLimiter(scope="auth")

    first = limiter_one.check_and_consume(
        key="auth:login:203.0.113.10",
        max_attempts=1,
        window_seconds=60,
        lock_seconds=5,
    )
    second = limiter_two.check_and_consume(
        key="auth:login:203.0.113.10",
        max_attempts=1,
        window_seconds=60,
        lock_seconds=5,
    )

    assert first.allowed is True
    assert second.allowed is False
    assert second.retry_after_seconds == 5
    get_settings.cache_clear()
