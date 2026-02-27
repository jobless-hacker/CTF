from __future__ import annotations

from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest
from sqlalchemy import select
from sqlalchemy.orm import Session as OrmSession

from app.core.settings import get_settings
from app.models.challenge import Challenge
from app.models.challenge_attempt import ChallengeAttempt
from app.models.challenge_flag import ChallengeFlag
from app.models.challenge_solve import ChallengeSolve
from app.models.submission_rate_limit import SubmissionRateLimit
from app.models.track import Track
from app.models.user import User
from app.services.challenge_exceptions import (
    ChallengeRateLimitedError,
    ChallengeNotPublishedError,
    InvalidFlagSubmissionError,
)
from app.services.challenge_service import ChallengeService


def _attempts_for_challenge(session: OrmSession, challenge_id):
    stmt = (
        select(ChallengeAttempt)
        .where(ChallengeAttempt.challenge_id == challenge_id)
        .order_by(ChallengeAttempt.created_at.asc(), ChallengeAttempt.id.asc())
    )
    return list(session.execute(stmt).scalars().all())


def _solves_for_challenge(session: OrmSession, challenge_id):
    stmt = (
        select(ChallengeSolve)
        .where(ChallengeSolve.challenge_id == challenge_id)
        .order_by(ChallengeSolve.created_at.asc(), ChallengeSolve.id.asc())
    )
    return list(session.execute(stmt).scalars().all())


def _override_xp_settings(
    monkeypatch: pytest.MonkeyPatch,
    *,
    enabled: bool | None = None,
    mode: str | None = None,
    value: int | None = None,
) -> None:
    if enabled is not None:
        monkeypatch.setenv("XP_FIRST_BLOOD_ENABLED", "true" if enabled else "false")
    if mode is not None:
        monkeypatch.setenv("XP_FIRST_BLOOD_BONUS_MODE", mode)
    if value is not None:
        monkeypatch.setenv("XP_FIRST_BLOOD_BONUS_VALUE", str(value))
    get_settings.cache_clear()


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


def _rate_limit_rows_for_challenge(session: OrmSession, challenge_id):
    return list(
        session.execute(
            select(SubmissionRateLimit).where(SubmissionRateLimit.challenge_id == challenge_id)
        ).scalars()
    )


def test_submit_correct_flag(
    session: OrmSession,
    seed_user,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{correct-flag}",
    )

    result = challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{correct-flag}",
    )
    session.flush()

    assert result == {"correct": True, "xp_awarded": 120, "first_blood": True}

    attempts = _attempts_for_challenge(session, challenge.id)
    assert len(attempts) == 1
    assert attempts[0].is_correct is True
    assert attempts[0].submitted_flag == "ZTCTF{correct-flag}"

    solves = _solves_for_challenge(session, challenge.id)
    assert len(solves) == 1
    assert solves[0].user_id == seed_user.id
    assert solves[0].points_awarded == 120
    assert solves[0].is_first_blood is True


def test_submit_incorrect_flag(
    session: OrmSession,
    seed_user,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{correct-flag}",
    )

    result = challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{wrong-flag}",
    )
    session.flush()

    assert result == {"correct": False, "xp_awarded": 0, "first_blood": False}
    assert _solves_for_challenge(session, challenge.id) == []


def test_submit_unpublished_challenge_raises(
    session: OrmSession,
    seed_user,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(with_flag=True, flag_value="ZTCTF{hidden-flag}")

    with pytest.raises(ChallengeNotPublishedError):
        challenge_service.submit_flag(
            session=session,
            user=seed_user,
            challenge_slug=challenge.slug,
            submitted_flag="ZTCTF{hidden-flag}",
        )

    assert _attempts_for_challenge(session, challenge.id) == []


def test_submit_records_attempt_even_if_incorrect(
    session: OrmSession,
    seed_user,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{expected-flag}",
    )

    challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{first-wrong}",
    )
    challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{second-wrong}",
    )
    session.flush()

    attempts = _attempts_for_challenge(session, challenge.id)
    assert len(attempts) == 2
    assert [attempt.is_correct for attempt in attempts] == [False, False]
    assert sorted(attempt.submitted_flag for attempt in attempts) == [
        "ZTCTF{first-wrong}",
        "ZTCTF{second-wrong}",
    ]


def test_submit_empty_flag_records_attempt_and_raises(
    session: OrmSession,
    seed_user,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{expected-flag}",
    )

    with pytest.raises(InvalidFlagSubmissionError):
        challenge_service.submit_flag(
            session=session,
            user=seed_user,
            challenge_slug=challenge.slug,
            submitted_flag="   ",
        )
    session.flush()

    attempts = _attempts_for_challenge(session, challenge.id)
    assert len(attempts) == 1
    assert attempts[0].is_correct is False
    assert attempts[0].submitted_flag == "   "
    assert _solves_for_challenge(session, challenge.id) == []


def test_second_solver_gets_base_points_only(
    session: OrmSession,
    seed_user: User,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{shared-flag}",
        points=150,
    )
    second_user = User(
        email=f"second-{uuid4()}@example.com",
        password_hash="placeholder-hash",
        is_active=True,
    )
    session.add(second_user)
    session.flush()

    first_result = challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{shared-flag}",
    )
    second_result = challenge_service.submit_flag(
        session=session,
        user=second_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{shared-flag}",
    )
    session.flush()

    assert first_result == {"correct": True, "xp_awarded": 180, "first_blood": True}
    assert second_result == {"correct": True, "xp_awarded": 150, "first_blood": False}

    solves = _solves_for_challenge(session, challenge.id)
    assert len(solves) == 2
    assert sum(1 for solve in solves if solve.is_first_blood) == 1
    assert sorted(solve.points_awarded for solve in solves) == [150, 180]


def test_same_user_double_submit_returns_zero_xp_and_records_attempt(
    session: OrmSession,
    seed_user: User,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{double-submit}",
    )

    first_result = challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{double-submit}",
    )
    second_result = challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{double-submit}",
    )
    session.flush()

    assert first_result == {"correct": True, "xp_awarded": 120, "first_blood": True}
    assert second_result == {"correct": True, "xp_awarded": 0, "first_blood": False}

    attempts = _attempts_for_challenge(session, challenge.id)
    assert len(attempts) == 2
    assert [attempt.is_correct for attempt in attempts] == [True, True]

    solves = _solves_for_challenge(session, challenge.id)
    assert len(solves) == 1
    assert solves[0].points_awarded == 120


def test_first_blood_disabled_grants_base_only(
    monkeypatch: pytest.MonkeyPatch,
    session: OrmSession,
    seed_user: User,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    _override_xp_settings(monkeypatch, enabled=False)
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{no-bonus}",
        points=100,
    )

    result = challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{no-bonus}",
    )
    session.flush()

    assert result == {"correct": True, "xp_awarded": 100, "first_blood": False}
    solves = _solves_for_challenge(session, challenge.id)
    assert len(solves) == 1
    assert solves[0].is_first_blood is False
    assert solves[0].points_awarded == 100
    get_settings.cache_clear()


def test_fixed_bonus_mode_works(
    monkeypatch: pytest.MonkeyPatch,
    session: OrmSession,
    seed_user: User,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    _override_xp_settings(monkeypatch, enabled=True, mode="fixed", value=35)
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{fixed-bonus}",
        points=90,
    )

    result = challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{fixed-bonus}",
    )
    session.flush()

    assert result == {"correct": True, "xp_awarded": 125, "first_blood": True}
    solves = _solves_for_challenge(session, challenge.id)
    assert len(solves) == 1
    assert solves[0].points_awarded == 125
    get_settings.cache_clear()


def test_percent_bonus_rounding_floor_works(
    monkeypatch: pytest.MonkeyPatch,
    session: OrmSession,
    seed_user: User,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    _override_xp_settings(monkeypatch, enabled=True, mode="percent", value=25)
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{percent-floor}",
        points=101,
    )

    result = challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{percent-floor}",
    )
    session.flush()

    assert result == {"correct": True, "xp_awarded": 126, "first_blood": True}
    solves = _solves_for_challenge(session, challenge.id)
    assert len(solves) == 1
    assert solves[0].points_awarded == 126
    get_settings.cache_clear()


def test_duplicate_solve_in_second_session_returns_zero_xp_and_keeps_attempt(
    test_engine,
) -> None:
    from sqlalchemy.orm import Session as LocalSession

    service = ChallengeService()

    setup_session = LocalSession(bind=test_engine, expire_on_commit=False, autoflush=False)
    try:
        track = Track(
            name=f"Linux-{uuid4().hex[:8]}",
            slug=f"linux-{uuid4().hex[:8]}",
            description="Linux track",
            is_active=True,
        )
        user = User(
            email=f"primary-{uuid4()}@example.com",
            password_hash="placeholder-hash",
            is_active=True,
        )
        setup_session.add_all([track, user])
        setup_session.flush()
        challenge = service.create_challenge(
            session=setup_session,
            track_id=track.id,
            title="Concurrent-ish Challenge",
            slug=f"concurrent-ish-{uuid4().hex[:8]}",
            description="Test duplicate solve across sessions.",
            difficulty="easy",
            points=100,
        )
        setup_session.flush()
        service.set_flag(setup_session, challenge, "ZTCTF{concurrent-ish}")
        service.publish_challenge(setup_session, challenge)
        setup_session.commit()

        challenge_slug = challenge.slug
        user_id = user.id
        challenge_id = challenge.id
    finally:
        setup_session.close()

    first_session = LocalSession(bind=test_engine, expire_on_commit=False, autoflush=False)
    second_session = LocalSession(bind=test_engine, expire_on_commit=False, autoflush=False)
    try:
        user_one = first_session.execute(select(User).where(User.id == user_id)).scalar_one()
        user_two = second_session.execute(select(User).where(User.id == user_id)).scalar_one()

        first_result = service.submit_flag(
            session=first_session,
            user=user_one,
            challenge_slug=challenge_slug,
            submitted_flag="ZTCTF{concurrent-ish}",
        )
        first_session.commit()

        second_result = service.submit_flag(
            session=second_session,
            user=user_two,
            challenge_slug=challenge_slug,
            submitted_flag="ZTCTF{concurrent-ish}",
        )
        second_session.commit()

        assert first_result == {"correct": True, "xp_awarded": 120, "first_blood": True}
        assert second_result == {"correct": True, "xp_awarded": 0, "first_blood": False}

        verify_session = LocalSession(bind=test_engine, expire_on_commit=False, autoflush=False)
        try:
            attempts = list(
                verify_session.execute(
                    select(ChallengeAttempt).where(ChallengeAttempt.challenge_id == challenge_id)
                ).scalars()
            )
            solves = list(
                verify_session.execute(
                    select(ChallengeSolve).where(ChallengeSolve.challenge_id == challenge_id)
                ).scalars()
            )
            assert len(attempts) == 2
            assert len(solves) == 1
        finally:
            verify_session.close()
    finally:
        first_session.close()
        second_session.close()
        cleanup_session = LocalSession(bind=test_engine, expire_on_commit=False, autoflush=False)
        try:
            cleanup_session.query(ChallengeAttempt).delete()
            cleanup_session.query(ChallengeSolve).delete()
            cleanup_session.query(ChallengeFlag).delete()
            cleanup_session.query(Challenge).delete()
            cleanup_session.query(User).delete()
            cleanup_session.query(Track).delete()
            cleanup_session.commit()
        finally:
            cleanup_session.close()


def test_blocked_submission_does_not_create_challenge_attempt_or_solve(
    monkeypatch: pytest.MonkeyPatch,
    session: OrmSession,
    seed_user: User,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=1, window_seconds=60, lock_seconds=5)
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{rlimited}",
    )

    first = challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{wrong-1}",
    )
    with pytest.raises(ChallengeRateLimitedError) as exc_info:
        challenge_service.submit_flag(
            session=session,
            user=seed_user,
            challenge_slug=challenge.slug,
            submitted_flag="ZTCTF{wrong-2}",
        )
    session.flush()

    assert first == {"correct": False, "xp_awarded": 0, "first_blood": False}
    assert exc_info.value.retry_after_seconds == 10

    attempts = _attempts_for_challenge(session, challenge.id)
    assert len(attempts) == 1
    assert attempts[0].submitted_flag == "ZTCTF{wrong-1}"
    assert _solves_for_challenge(session, challenge.id) == []
    assert len(_rate_limit_rows_for_challenge(session, challenge.id)) == 1
    get_settings.cache_clear()


def test_blocked_submission_does_not_interfere_with_first_blood(
    monkeypatch: pytest.MonkeyPatch,
    session: OrmSession,
    seed_user: User,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=1, window_seconds=60, lock_seconds=5)
    challenge = create_basic_challenge(
        published=True,
        flag_value="ZTCTF{first-blood-safe}",
        points=100,
    )
    second_user = User(
        email=f"second-rate-limit-{uuid4()}@example.com",
        password_hash="placeholder-hash",
        is_active=True,
    )
    session.add(second_user)
    session.flush()

    first_wrong = challenge_service.submit_flag(
        session=session,
        user=seed_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{wrong-1}",
    )
    with pytest.raises(ChallengeRateLimitedError):
        challenge_service.submit_flag(
            session=session,
            user=seed_user,
            challenge_slug=challenge.slug,
            submitted_flag="ZTCTF{first-blood-safe}",
        )

    winner_result = challenge_service.submit_flag(
        session=session,
        user=second_user,
        challenge_slug=challenge.slug,
        submitted_flag="ZTCTF{first-blood-safe}",
    )
    session.flush()

    assert first_wrong == {"correct": False, "xp_awarded": 0, "first_blood": False}
    assert winner_result == {"correct": True, "xp_awarded": 120, "first_blood": True}

    solves = _solves_for_challenge(session, challenge.id)
    assert len(solves) == 1
    assert solves[0].user_id == second_user.id
    assert solves[0].is_first_blood is True
    get_settings.cache_clear()


def test_concurrent_double_submit_does_not_bypass_limit(
    monkeypatch: pytest.MonkeyPatch,
    test_engine,
) -> None:
    from sqlalchemy.orm import Session as LocalSession

    _override_rate_limit_settings(monkeypatch, max_attempts=1, window_seconds=60, lock_seconds=5)
    service = ChallengeService()

    setup_session = LocalSession(bind=test_engine, expire_on_commit=False, autoflush=False)
    try:
        track = Track(
            name=f"RateLimit-{uuid4().hex[:8]}",
            slug=f"rate-limit-{uuid4().hex[:8]}",
            description="Rate limit track",
            is_active=True,
        )
        user = User(
            email=f"limit-user-{uuid4()}@example.com",
            password_hash="placeholder-hash",
            is_active=True,
        )
        setup_session.add_all([track, user])
        setup_session.flush()
        challenge = service.create_challenge(
            session=setup_session,
            track_id=track.id,
            title="Rate Limited Concurrent-ish Challenge",
            slug=f"rate-limit-concurrent-{uuid4().hex[:8]}",
            description="Test limiter across sessions.",
            difficulty="easy",
            points=100,
        )
        setup_session.flush()
        service.set_flag(setup_session, challenge, "ZTCTF{rl-concurrent}")
        service.publish_challenge(setup_session, challenge)
        setup_session.commit()

        challenge_slug = challenge.slug
        challenge_id = challenge.id
        user_id = user.id
    finally:
        setup_session.close()

    first_session = LocalSession(bind=test_engine, expire_on_commit=False, autoflush=False)
    second_session = LocalSession(bind=test_engine, expire_on_commit=False, autoflush=False)
    try:
        first_user = first_session.execute(select(User).where(User.id == user_id)).scalar_one()
        second_user = second_session.execute(select(User).where(User.id == user_id)).scalar_one()

        first_result = service.submit_flag(
            session=first_session,
            user=first_user,
            challenge_slug=challenge_slug,
            submitted_flag="ZTCTF{wrong-1}",
        )
        first_session.commit()

        with pytest.raises(ChallengeRateLimitedError):
            service.submit_flag(
                session=second_session,
                user=second_user,
                challenge_slug=challenge_slug,
                submitted_flag="ZTCTF{wrong-2}",
            )
        second_session.commit()

        verify_session = LocalSession(bind=test_engine, expire_on_commit=False, autoflush=False)
        try:
            attempts = list(
                verify_session.execute(
                    select(ChallengeAttempt).where(ChallengeAttempt.challenge_id == challenge_id)
                ).scalars()
            )
            solves = list(
                verify_session.execute(
                    select(ChallengeSolve).where(ChallengeSolve.challenge_id == challenge_id)
                ).scalars()
            )
            rate_limits = list(
                verify_session.execute(
                    select(SubmissionRateLimit).where(
                        SubmissionRateLimit.challenge_id == challenge_id,
                        SubmissionRateLimit.user_id == user_id,
                    )
                ).scalars()
            )
            assert first_result == {"correct": False, "xp_awarded": 0, "first_blood": False}
            assert len(attempts) == 1
            assert len(solves) == 0
            assert len(rate_limits) == 1
            assert rate_limits[0].attempt_count == 2
            assert rate_limits[0].lock_until is not None
        finally:
            verify_session.close()
    finally:
        first_session.close()
        second_session.close()
        cleanup_session = LocalSession(bind=test_engine, expire_on_commit=False, autoflush=False)
        try:
            cleanup_session.query(ChallengeAttempt).delete()
            cleanup_session.query(ChallengeSolve).delete()
            cleanup_session.query(SubmissionRateLimit).delete()
            cleanup_session.query(ChallengeFlag).delete()
            cleanup_session.query(Challenge).delete()
            cleanup_session.query(User).delete()
            cleanup_session.query(Track).delete()
            cleanup_session.commit()
        finally:
            cleanup_session.close()
    get_settings.cache_clear()
