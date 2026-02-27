from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from math import ceil
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.settings import get_settings
from app.models.submission_rate_limit import SubmissionRateLimit
from app.observability.logger import log_event
from app.observability.metrics import metrics


@dataclass(frozen=True, slots=True)
class RateLimitDecision:
    allowed: bool
    retry_after_seconds: int | None


class SubmissionRateLimiter:
    def check_and_consume(
        self,
        session: Session,
        user_id: UUID,
        challenge_id: UUID,
        now: datetime,
    ) -> RateLimitDecision:
        raise NotImplementedError


class DbSubmissionRateLimiter(SubmissionRateLimiter):
    _MAX_BACKOFF_SECONDS = 3600

    def check_and_consume(
        self,
        session: Session,
        user_id: UUID,
        challenge_id: UUID,
        now: datetime,
    ) -> RateLimitDecision:
        settings = get_settings()
        if not settings.SUBMISSION_RATE_LIMIT_ENABLED:
            return RateLimitDecision(allowed=True, retry_after_seconds=None)

        metrics.increment(
            "zerotrace_rate_limit_checks_total",
            labels={"scope": "user_challenge"},
        )
        current_time = self._normalize_now(now)
        rate_limit_row, was_created = self._get_or_create_rate_limit_row(
            session=session,
            user_id=user_id,
            challenge_id=challenge_id,
            now=current_time,
        )
        if was_created:
            return RateLimitDecision(allowed=True, retry_after_seconds=None)

        lock_until = (
            self._normalize_now(rate_limit_row.lock_until)
            if rate_limit_row.lock_until is not None
            else None
        )
        if lock_until is not None and lock_until > current_time:
            rate_limit_row.last_blocked_at = current_time
            retry_after_seconds = self._retry_after_seconds(lock_until, current_time)
            metrics.increment(
                "zerotrace_rate_limit_blocks_total",
                labels={"scope": "user_challenge", "reason": "active_lock"},
            )
            log_event(
                "submission_blocked",
                outcome="rate_limited",
                reason="active_lock",
                user_id=user_id,
                challenge_id=challenge_id,
                retry_after_seconds=retry_after_seconds,
            )
            return RateLimitDecision(
                allowed=False,
                retry_after_seconds=retry_after_seconds,
            )

        window_seconds = settings.SUBMISSION_RATE_LIMIT_WINDOW_SECONDS
        window_started_at = self._normalize_now(rate_limit_row.window_started_at)
        window_elapsed_seconds = (current_time - window_started_at).total_seconds()
        if window_elapsed_seconds >= window_seconds:
            rate_limit_row.window_started_at = current_time
            rate_limit_row.attempt_count = 1
            rate_limit_row.lock_until = None
        else:
            rate_limit_row.attempt_count += 1

        rate_limit_row.last_attempt_at = current_time

        if rate_limit_row.attempt_count > settings.SUBMISSION_RATE_LIMIT_MAX_ATTEMPTS:
            rate_limit_row.violation_count += 1
            lock_seconds = self._compute_lock_seconds(
                base_lock_seconds=settings.SUBMISSION_RATE_LIMIT_LOCK_SECONDS,
                violation_count=rate_limit_row.violation_count,
            )
            rate_limit_row.lock_until = current_time + timedelta(seconds=lock_seconds)
            rate_limit_row.last_blocked_at = current_time
            metrics.increment(
                "zerotrace_rate_limit_violations_total",
                labels={"scope": "user_challenge"},
            )
            metrics.increment(
                "zerotrace_rate_limit_blocks_total",
                labels={"scope": "user_challenge", "reason": "window_exceeded"},
            )
            metrics.observe(
                "zerotrace_rate_limit_lock_seconds",
                lock_seconds,
                labels={"scope": "user_challenge"},
            )
            log_event(
                "rate_limit_violation",
                outcome="blocked",
                user_id=user_id,
                challenge_id=challenge_id,
                attempt_count=rate_limit_row.attempt_count,
                violation_count=rate_limit_row.violation_count,
                lock_seconds=lock_seconds,
            )
            log_event(
                "submission_blocked",
                outcome="rate_limited",
                reason="window_exceeded",
                user_id=user_id,
                challenge_id=challenge_id,
                retry_after_seconds=lock_seconds,
            )
            return RateLimitDecision(allowed=False, retry_after_seconds=lock_seconds)

        return RateLimitDecision(allowed=True, retry_after_seconds=None)

    def _get_or_create_rate_limit_row(
        self,
        session: Session,
        user_id: UUID,
        challenge_id: UUID,
        now: datetime,
    ) -> tuple[SubmissionRateLimit, bool]:
        existing_row = self._select_for_update(session, user_id=user_id, challenge_id=challenge_id)
        if existing_row is not None:
            return existing_row, False

        created_row = self._try_insert_initial_row(
            session=session,
            user_id=user_id,
            challenge_id=challenge_id,
            now=now,
        )
        if created_row is not None:
            return created_row, True

        existing_row = self._select_for_update(session, user_id=user_id, challenge_id=challenge_id)
        if existing_row is None:
            raise RuntimeError("Failed to load submission rate limit state after insert race.")
        return existing_row, False

    @staticmethod
    def _select_for_update(
        session: Session,
        *,
        user_id: UUID,
        challenge_id: UUID,
    ) -> SubmissionRateLimit | None:
        stmt = (
            select(SubmissionRateLimit)
            .where(
                SubmissionRateLimit.user_id == user_id,
                SubmissionRateLimit.challenge_id == challenge_id,
            )
            .with_for_update()
        )
        return session.execute(stmt).scalar_one_or_none()

    @staticmethod
    def _try_insert_initial_row(
        session: Session,
        *,
        user_id: UUID,
        challenge_id: UUID,
        now: datetime,
    ) -> SubmissionRateLimit | None:
        row = SubmissionRateLimit(
            user_id=user_id,
            challenge_id=challenge_id,
            window_started_at=now,
            attempt_count=1,
            violation_count=0,
            lock_until=None,
            last_attempt_at=now,
            last_blocked_at=None,
        )
        try:
            with session.begin_nested():
                session.add(row)
                session.flush()
        except IntegrityError:
            return None

        return row

    @classmethod
    def _compute_lock_seconds(cls, *, base_lock_seconds: int, violation_count: int) -> int:
        lock_seconds = base_lock_seconds * (2 ** violation_count)
        if lock_seconds > cls._MAX_BACKOFF_SECONDS:
            return cls._MAX_BACKOFF_SECONDS
        return lock_seconds

    @staticmethod
    def _retry_after_seconds(lock_until: datetime, now: datetime) -> int:
        return max(1, ceil((lock_until - now).total_seconds()))

    @staticmethod
    def _normalize_now(now: datetime) -> datetime:
        if now.tzinfo is None or now.utcoffset() is None:
            return now.replace(tzinfo=timezone.utc)
        return now.astimezone(timezone.utc)
