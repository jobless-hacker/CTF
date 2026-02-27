from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.challenge import Challenge, ChallengeDifficulty
from app.models.challenge_attempt import ChallengeAttempt
from app.models.challenge_flag import ChallengeFlag
from app.models.challenge_solve import ChallengeSolve
from app.models.track import Track
from app.models.user import User


def create_challenge(
    session: Session,
    track_id: UUID,
    title: str,
    slug: str,
    description: str,
    difficulty: ChallengeDifficulty,
    points: int,
) -> Challenge:
    challenge = Challenge(
        track_id=track_id,
        title=title,
        slug=slug,
        description=description,
        difficulty=difficulty,
        points=points,
    )
    session.add(challenge)
    return challenge


def get_by_slug(session: Session, slug: str) -> Challenge | None:
    stmt = (
        select(Challenge)
        .options(
            selectinload(Challenge.track),
            selectinload(Challenge.flag),
        )
        .where(Challenge.slug == slug)
    )
    return session.execute(stmt).scalar_one_or_none()


def get_by_id(session: Session, challenge_id: UUID) -> Challenge | None:
    stmt = (
        select(Challenge)
        .options(
            selectinload(Challenge.track),
            selectinload(Challenge.flag),
        )
        .where(Challenge.id == challenge_id)
    )
    return session.execute(stmt).scalar_one_or_none()


def set_flag_hash(session: Session, challenge: Challenge, flag_hash: str) -> ChallengeFlag:
    challenge_flag = ChallengeFlag(challenge=challenge, flag_hash=flag_hash)
    session.add(challenge_flag)
    return challenge_flag


def record_attempt(
    session: Session,
    user: User,
    challenge: Challenge,
    submitted_flag: str,
    is_correct: bool,
) -> ChallengeAttempt:
    attempt = ChallengeAttempt(
        user=user,
        challenge=challenge,
        submitted_flag=submitted_flag,
        is_correct=is_correct,
    )
    session.add(attempt)
    return attempt


def create_challenge_solve(
    session: Session,
    user: User,
    challenge: Challenge,
    points_awarded: int,
    is_first_blood: bool,
) -> ChallengeSolve:
    solve = ChallengeSolve(
        user=user,
        challenge=challenge,
        points_awarded=points_awarded,
        is_first_blood=is_first_blood,
    )
    session.add(solve)
    return solve


def get_solve_by_user_and_challenge(
    session: Session,
    user_id: UUID,
    challenge_id: UUID,
) -> ChallengeSolve | None:
    stmt = select(ChallengeSolve).where(
        ChallengeSolve.user_id == user_id,
        ChallengeSolve.challenge_id == challenge_id,
    )
    return session.execute(stmt).scalar_one_or_none()


def get_first_blood_solve_by_challenge(
    session: Session,
    challenge_id: UUID,
) -> ChallengeSolve | None:
    stmt = select(ChallengeSolve).where(
        ChallengeSolve.challenge_id == challenge_id,
        ChallengeSolve.is_first_blood.is_(True),
    )
    return session.execute(stmt).scalar_one_or_none()


def list_published_by_track(session: Session, track_slug: str) -> list[Challenge]:
    stmt = (
        select(Challenge)
        .join(Track, Challenge.track_id == Track.id)
        .options(selectinload(Challenge.track))
        .where(
            Track.slug == track_slug,
            Challenge.is_published.is_(True),
        )
        .order_by(Challenge.created_at.asc(), Challenge.id.asc())
    )
    return list(session.execute(stmt).scalars().all())
