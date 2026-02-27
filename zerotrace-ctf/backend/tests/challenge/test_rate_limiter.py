from __future__ import annotations

from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.settings import get_settings
from app.models.submission_rate_limit import SubmissionRateLimit
from app.services.rate_limiter import DbSubmissionRateLimiter


def _override_rate_limit_settings(
    monkeypatch: pytest.MonkeyPatch,
    *,
    enabled: bool | None = None,
    max_attempts: int | None = None,
    window_seconds: int | None = None,
    lock_seconds: int | None = None,
) -> None:
    if enabled is not None:
        monkeypatch.setenv("SUBMISSION_RATE_LIMIT_ENABLED", "true" if enabled else "false")
    if max_attempts is not None:
        monkeypatch.setenv("SUBMISSION_RATE_LIMIT_MAX_ATTEMPTS", str(max_attempts))
    if window_seconds is not None:
        monkeypatch.setenv("SUBMISSION_RATE_LIMIT_WINDOW_SECONDS", str(window_seconds))
    if lock_seconds is not None:
        monkeypatch.setenv("SUBMISSION_RATE_LIMIT_LOCK_SECONDS", str(lock_seconds))
    get_settings.cache_clear()


def _get_rate_limit_row(session: Session, user_id, challenge_id) -> SubmissionRateLimit | None:
    stmt = select(SubmissionRateLimit).where(
        SubmissionRateLimit.user_id == user_id,
        SubmissionRateLimit.challenge_id == challenge_id,
    )
    return session.execute(stmt).scalar_one_or_none()


def _as_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None or dt.utcoffset() is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def test_under_limit_allowed(
    monkeypatch: pytest.MonkeyPatch,
    session: Session,
    seed_user,
    create_basic_challenge,
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=3, window_seconds=60, lock_seconds=5)
    limiter = DbSubmissionRateLimiter()
    challenge = create_basic_challenge()
    now = datetime(2026, 1, 1, 12, 0, tzinfo=timezone.utc)

    first = limiter.check_and_consume(session, seed_user.id, challenge.id, now)
    second = limiter.check_and_consume(session, seed_user.id, challenge.id, now + timedelta(seconds=1))
    session.flush()

    assert first.allowed is True and first.retry_after_seconds is None
    assert second.allowed is True and second.retry_after_seconds is None

    row = _get_rate_limit_row(session, seed_user.id, challenge.id)
    assert row is not None
    assert row.attempt_count == 2
    assert row.violation_count == 0
    assert row.lock_until is None
    get_settings.cache_clear()


def test_at_limit_allowed(
    monkeypatch: pytest.MonkeyPatch,
    session: Session,
    seed_user,
    create_basic_challenge,
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=2, window_seconds=60, lock_seconds=5)
    limiter = DbSubmissionRateLimiter()
    challenge = create_basic_challenge()
    now = datetime(2026, 1, 1, 12, 0, tzinfo=timezone.utc)

    limiter.check_and_consume(session, seed_user.id, challenge.id, now)
    second = limiter.check_and_consume(session, seed_user.id, challenge.id, now + timedelta(seconds=1))
    session.flush()

    assert second.allowed is True
    row = _get_rate_limit_row(session, seed_user.id, challenge.id)
    assert row is not None
    assert row.attempt_count == 2
    assert row.lock_until is None
    get_settings.cache_clear()


def test_exceed_limit_blocked(
    monkeypatch: pytest.MonkeyPatch,
    session: Session,
    seed_user,
    create_basic_challenge,
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=2, window_seconds=60, lock_seconds=5)
    limiter = DbSubmissionRateLimiter()
    challenge = create_basic_challenge()
    now = datetime(2026, 1, 1, 12, 0, tzinfo=timezone.utc)

    limiter.check_and_consume(session, seed_user.id, challenge.id, now)
    limiter.check_and_consume(session, seed_user.id, challenge.id, now + timedelta(seconds=1))
    blocked = limiter.check_and_consume(session, seed_user.id, challenge.id, now + timedelta(seconds=2))
    session.flush()

    assert blocked.allowed is False
    assert blocked.retry_after_seconds == 10

    row = _get_rate_limit_row(session, seed_user.id, challenge.id)
    assert row is not None
    assert row.attempt_count == 3
    assert row.violation_count == 1
    assert row.lock_until is not None
    assert row.last_blocked_at is not None
    get_settings.cache_clear()


def test_window_reset(
    monkeypatch: pytest.MonkeyPatch,
    session: Session,
    seed_user,
    create_basic_challenge,
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=5, window_seconds=2, lock_seconds=5)
    limiter = DbSubmissionRateLimiter()
    challenge = create_basic_challenge()
    now = datetime(2026, 1, 1, 12, 0, tzinfo=timezone.utc)

    limiter.check_and_consume(session, seed_user.id, challenge.id, now)
    limiter.check_and_consume(session, seed_user.id, challenge.id, now + timedelta(seconds=1))
    reset_result = limiter.check_and_consume(session, seed_user.id, challenge.id, now + timedelta(seconds=3))
    session.flush()

    assert reset_result.allowed is True

    row = _get_rate_limit_row(session, seed_user.id, challenge.id)
    assert row is not None
    assert row.attempt_count == 1
    assert _as_utc(row.window_started_at) == now + timedelta(seconds=3)
    get_settings.cache_clear()


def test_progressive_backoff_doubles(
    monkeypatch: pytest.MonkeyPatch,
    session: Session,
    seed_user,
    create_basic_challenge,
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=1, window_seconds=1, lock_seconds=5)
    limiter = DbSubmissionRateLimiter()
    challenge = create_basic_challenge()
    base = datetime(2026, 1, 1, 12, 0, tzinfo=timezone.utc)

    limiter.check_and_consume(session, seed_user.id, challenge.id, base)
    first_block = limiter.check_and_consume(session, seed_user.id, challenge.id, base + timedelta(milliseconds=500))
    second_allow = limiter.check_and_consume(session, seed_user.id, challenge.id, base + timedelta(seconds=11))
    second_block = limiter.check_and_consume(
        session,
        seed_user.id,
        challenge.id,
        base + timedelta(seconds=11, milliseconds=500),
    )
    session.flush()

    assert first_block.allowed is False
    assert first_block.retry_after_seconds == 10
    assert second_allow.allowed is True
    assert second_block.allowed is False
    assert second_block.retry_after_seconds == 20

    row = _get_rate_limit_row(session, seed_user.id, challenge.id)
    assert row is not None
    assert row.violation_count == 2
    get_settings.cache_clear()


def test_lock_active_blocks_without_incrementing_attempt_count(
    monkeypatch: pytest.MonkeyPatch,
    session: Session,
    seed_user,
    create_basic_challenge,
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=1, window_seconds=60, lock_seconds=5)
    limiter = DbSubmissionRateLimiter()
    challenge = create_basic_challenge()
    now = datetime(2026, 1, 1, 12, 0, tzinfo=timezone.utc)

    limiter.check_and_consume(session, seed_user.id, challenge.id, now)
    blocked = limiter.check_and_consume(session, seed_user.id, challenge.id, now + timedelta(seconds=1))
    row_after_block = _get_rate_limit_row(session, seed_user.id, challenge.id)
    assert row_after_block is not None
    attempt_count_after_block = row_after_block.attempt_count
    violation_count_after_block = row_after_block.violation_count
    lock_until = row_after_block.lock_until
    assert lock_until is not None

    blocked_again = limiter.check_and_consume(session, seed_user.id, challenge.id, now + timedelta(seconds=2))
    session.flush()

    assert blocked.allowed is False
    assert blocked_again.allowed is False
    assert blocked_again.retry_after_seconds == 9

    row = _get_rate_limit_row(session, seed_user.id, challenge.id)
    assert row is not None
    assert row.attempt_count == attempt_count_after_block
    assert row.violation_count == violation_count_after_block
    assert row.lock_until == lock_until
    get_settings.cache_clear()


def test_disabled_limiter_bypasses_logic(
    monkeypatch: pytest.MonkeyPatch,
    session: Session,
    seed_user,
    create_basic_challenge,
) -> None:
    _override_rate_limit_settings(monkeypatch, enabled=False)
    limiter = DbSubmissionRateLimiter()
    challenge = create_basic_challenge()
    now = datetime(2026, 1, 1, 12, 0, tzinfo=timezone.utc)

    decision = limiter.check_and_consume(session, seed_user.id, challenge.id, now)
    session.flush()

    assert decision.allowed is True
    assert decision.retry_after_seconds is None
    assert _get_rate_limit_row(session, seed_user.id, challenge.id) is None
    get_settings.cache_clear()
