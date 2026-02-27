from __future__ import annotations

import asyncio
from contextlib import suppress
from datetime import datetime, timedelta, timezone
from time import perf_counter

from sqlalchemy import create_engine
from sqlalchemy import func, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.settings import get_settings
from app.models.challenge_solve import ChallengeSolve
from app.observability.logger import log_event
from app.observability.metrics import metrics


_INTEGRITY_CHECK_INTERVAL_SECONDS = 600
_XP_SPIKE_WINDOW_SECONDS = 3600
_XP_SPIKE_THRESHOLD = 5000

IntegritySchedulerHandle = tuple[asyncio.Task[None], Engine]


async def run_integrity_check(session: Session) -> None:
    _run_integrity_check_sync(session)


def start_integrity_scheduler() -> IntegritySchedulerHandle | None:
    settings = get_settings()
    if not settings.OBSERVABILITY_ENABLED:
        return None
    if settings.ENVIRONMENT.lower() == "test":
        return None

    engine = create_engine(
        settings.DATABASE_URL,
        future=True,
        pool_pre_ping=True,
    )
    session_factory = sessionmaker(bind=engine, class_=Session, expire_on_commit=False, autoflush=False)
    task = asyncio.create_task(_integrity_scheduler_loop(session_factory), name="integrity-check-scheduler")
    log_event(
        "integrity_scheduler_started",
        interval_seconds=_INTEGRITY_CHECK_INTERVAL_SECONDS,
    )
    return task, engine


async def stop_integrity_scheduler(handle: IntegritySchedulerHandle | None) -> None:
    if handle is None:
        return

    task, engine = handle
    task.cancel()
    with suppress(asyncio.CancelledError):
        await task
    engine.dispose()
    log_event("integrity_scheduler_stopped")


async def _integrity_scheduler_loop(session_factory: sessionmaker[Session]) -> None:
    while True:
        started = perf_counter()
        try:
            await asyncio.to_thread(_run_integrity_check_with_session, session_factory)
        except Exception as exc:
            log_event(
                "integrity_check_failed",
                outcome="error",
                error_type=type(exc).__name__,
            )
        finally:
            elapsed_ms = (perf_counter() - started) * 1000
            metrics.observe("zerotrace_integrity_check_latency_ms", elapsed_ms)

        await asyncio.sleep(_INTEGRITY_CHECK_INTERVAL_SECONDS)


def _run_integrity_check_with_session(session_factory: sessionmaker[Session]) -> None:
    with session_factory() as session:
        _run_integrity_check_sync(session)


def _run_integrity_check_sync(session: Session) -> None:
    now = datetime.now(timezone.utc)
    one_hour_ago = now - timedelta(seconds=_XP_SPIKE_WINDOW_SECONDS)

    duplicate_solves_subquery = (
        select(ChallengeSolve.user_id, ChallengeSolve.challenge_id)
        .group_by(ChallengeSolve.user_id, ChallengeSolve.challenge_id)
        .having(func.count() > 1)
        .subquery()
    )
    duplicate_solves = session.execute(
        select(func.count()).select_from(duplicate_solves_subquery)
    ).scalar_one()

    negative_points = session.execute(
        select(func.count())
        .select_from(ChallengeSolve)
        .where(ChallengeSolve.points_awarded < 0)
    ).scalar_one()

    multiple_first_blood_subquery = (
        select(ChallengeSolve.challenge_id)
        .where(ChallengeSolve.is_first_blood.is_(True))
        .group_by(ChallengeSolve.challenge_id)
        .having(func.count() > 1)
        .subquery()
    )
    multiple_first_blood = session.execute(
        select(func.count()).select_from(multiple_first_blood_subquery)
    ).scalar_one()

    xp_spike_subquery = (
        select(ChallengeSolve.user_id)
        .where(ChallengeSolve.created_at >= one_hour_ago)
        .group_by(ChallengeSolve.user_id)
        .having(func.sum(ChallengeSolve.points_awarded) > _XP_SPIKE_THRESHOLD)
        .subquery()
    )
    xp_spike_users = session.execute(select(func.count()).select_from(xp_spike_subquery)).scalar_one()

    outcome = "ok"
    total_violations = duplicate_solves + negative_points + multiple_first_blood + xp_spike_users
    if total_violations > 0:
        outcome = "violation"

    log_event(
        "integrity_check_result",
        outcome=outcome,
        duplicate_solves=duplicate_solves,
        negative_points=negative_points,
        multiple_first_blood=multiple_first_blood,
        xp_spike_users=xp_spike_users,
    )

    if duplicate_solves > 0:
        log_event(
            "integrity_violation_detected",
            violation_type="duplicate_solves",
            count=duplicate_solves,
        )
    if negative_points > 0:
        log_event(
            "integrity_violation_detected",
            violation_type="negative_points",
            count=negative_points,
        )
    if multiple_first_blood > 0:
        log_event(
            "integrity_violation_detected",
            violation_type="multiple_first_blood",
            count=multiple_first_blood,
        )
    if xp_spike_users > 0:
        log_event(
            "integrity_violation_detected",
            violation_type="xp_spike_users",
            count=xp_spike_users,
        )
