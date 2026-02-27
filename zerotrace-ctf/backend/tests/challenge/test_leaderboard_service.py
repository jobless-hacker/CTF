from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID, uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.challenge import Challenge, ChallengeDifficulty
from app.models.challenge_solve import ChallengeSolve
from app.models.track import Track
from app.models.user import User
from app.services.leaderboard_service import LeaderboardEntry, LeaderboardService


def _dt(day: int, hour: int = 0, minute: int = 0) -> datetime:
    return datetime(2026, 1, day, hour, minute, tzinfo=timezone.utc)


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _create_track(session: Session, slug: str, name: str | None = None) -> Track:
    track = Track(
        name=name or slug.title(),
        slug=slug,
        description=f"{slug} track",
        is_active=True,
    )
    session.add(track)
    session.flush()
    return track


def _create_challenge(
    session: Session,
    track: Track,
    slug: str,
    *,
    points: int = 100,
) -> Challenge:
    challenge = Challenge(
        track_id=track.id,
        title=f"Challenge {slug}",
        slug=slug,
        description="Leaderboard test challenge",
        difficulty=ChallengeDifficulty.EASY,
        points=points,
        is_published=True,
    )
    session.add(challenge)
    session.flush()
    return challenge


def _create_user(
    session: Session,
    email: str,
    *,
    user_id: UUID | None = None,
    is_active: bool = True,
) -> User:
    user_kwargs = {
        "email": email,
        "password_hash": "placeholder-hash",
        "is_active": is_active,
    }
    if user_id is not None:
        user_kwargs["id"] = user_id

    user = User(**user_kwargs)
    session.add(user)
    session.flush()
    return user


def _create_solve(
    session: Session,
    *,
    user: User,
    challenge: Challenge,
    points_awarded: int,
    created_at: datetime,
    is_first_blood: bool = False,
) -> ChallengeSolve:
    solve = ChallengeSolve(
        user_id=user.id,
        challenge_id=challenge.id,
        points_awarded=points_awarded,
        is_first_blood=is_first_blood,
        created_at=created_at,
    )
    session.add(solve)
    session.flush()
    return solve


def test_empty_leaderboard(session: Session) -> None:
    service = LeaderboardService()

    entries = service.get_global_leaderboard(session, limit=50, offset=0)

    assert entries == []


def test_single_user_leaderboard(session: Session) -> None:
    service = LeaderboardService()
    track = _create_track(session, "linux")
    challenge = _create_challenge(session, track, "single-user")
    user = _create_user(session, f"user-{uuid4()}@example.com")
    _create_solve(session, user=user, challenge=challenge, points_awarded=120, created_at=_dt(1))

    entries = service.get_global_leaderboard(session, limit=50, offset=0)

    assert len(entries) == 1
    assert entries[0].user_id == user.id
    assert entries[0].total_xp == 120
    assert _as_utc(entries[0].first_solve_at) == _dt(1)
    assert entries[0].rank == 1


def test_multiple_users_ranking_order(session: Session) -> None:
    service = LeaderboardService()
    track = _create_track(session, "linux")
    c1 = _create_challenge(session, track, "multi-1")
    c2 = _create_challenge(session, track, "multi-2")
    c3 = _create_challenge(session, track, "multi-3")

    u1 = _create_user(session, f"user-a-{uuid4()}@example.com")
    u2 = _create_user(session, f"user-b-{uuid4()}@example.com")
    u3 = _create_user(session, f"user-c-{uuid4()}@example.com")

    _create_solve(session, user=u1, challenge=c1, points_awarded=100, created_at=_dt(1))
    _create_solve(session, user=u1, challenge=c2, points_awarded=80, created_at=_dt(2))
    _create_solve(session, user=u2, challenge=c3, points_awarded=150, created_at=_dt(1, 1))
    _create_solve(session, user=u3, challenge=c2, points_awarded=90, created_at=_dt(1, 2))

    entries = service.get_global_leaderboard(session, limit=50, offset=0)

    assert [entry.user_id for entry in entries] == [u1.id, u2.id, u3.id]
    assert [entry.total_xp for entry in entries] == [180, 150, 90]
    assert [entry.rank for entry in entries] == [1, 2, 3]


def test_tie_breaking_by_first_solve_at(session: Session) -> None:
    service = LeaderboardService()
    track = _create_track(session, "linux")
    c1 = _create_challenge(session, track, "tie-time-1")
    c2 = _create_challenge(session, track, "tie-time-2")
    c3 = _create_challenge(session, track, "tie-time-3")
    c4 = _create_challenge(session, track, "tie-time-4")

    early_user = _create_user(session, f"early-{uuid4()}@example.com")
    late_user = _create_user(session, f"late-{uuid4()}@example.com")

    _create_solve(session, user=early_user, challenge=c1, points_awarded=50, created_at=_dt(1))
    _create_solve(session, user=early_user, challenge=c2, points_awarded=50, created_at=_dt(5))
    _create_solve(session, user=late_user, challenge=c3, points_awarded=50, created_at=_dt(2))
    _create_solve(session, user=late_user, challenge=c4, points_awarded=50, created_at=_dt(6))

    entries = service.get_global_leaderboard(session, limit=50, offset=0)

    assert [entry.user_id for entry in entries] == [early_user.id, late_user.id]
    assert [entry.total_xp for entry in entries] == [100, 100]
    assert [_as_utc(entry.first_solve_at) for entry in entries] == [_dt(1), _dt(2)]
    assert [entry.rank for entry in entries] == [1, 2]


def test_tie_breaking_by_user_id(session: Session) -> None:
    service = LeaderboardService()
    track = _create_track(session, "linux")
    c1 = _create_challenge(session, track, "tie-uuid-1")
    c2 = _create_challenge(session, track, "tie-uuid-2")

    lower_id = UUID("00000000-0000-0000-0000-00000000000a")
    higher_id = UUID("00000000-0000-0000-0000-00000000000b")
    u1 = _create_user(session, f"user-low-{uuid4()}@example.com", user_id=lower_id)
    u2 = _create_user(session, f"user-high-{uuid4()}@example.com", user_id=higher_id)
    same_ts = _dt(3, 3)

    _create_solve(session, user=u1, challenge=c1, points_awarded=100, created_at=same_ts)
    _create_solve(session, user=u2, challenge=c2, points_awarded=100, created_at=same_ts)

    entries = service.get_global_leaderboard(session, limit=50, offset=0)

    assert [entry.user_id for entry in entries] == [lower_id, higher_id]
    assert [entry.total_xp for entry in entries] == [100, 100]
    assert [_as_utc(entry.first_solve_at) for entry in entries] == [same_ts, same_ts]
    assert [entry.rank for entry in entries] == [1, 2]


def test_track_filtering_correctness(session: Session) -> None:
    service = LeaderboardService()
    linux_track = _create_track(session, "linux")
    crypto_track = _create_track(session, "cryptography", name="Cryptography")
    linux_ch1 = _create_challenge(session, linux_track, "linux-a")
    linux_ch2 = _create_challenge(session, linux_track, "linux-b")
    crypto_ch = _create_challenge(session, crypto_track, "crypto-a")

    u1 = _create_user(session, f"user-track1-{uuid4()}@example.com")
    u2 = _create_user(session, f"user-track2-{uuid4()}@example.com")

    _create_solve(session, user=u1, challenge=linux_ch1, points_awarded=100, created_at=_dt(1))
    _create_solve(session, user=u1, challenge=crypto_ch, points_awarded=300, created_at=_dt(2))
    _create_solve(session, user=u2, challenge=linux_ch2, points_awarded=120, created_at=_dt(1, 1))

    global_entries = service.get_global_leaderboard(session, limit=50, offset=0)
    linux_entries = service.get_track_leaderboard(session, linux_track.id, limit=50, offset=0)
    crypto_entries = service.get_track_leaderboard(session, crypto_track.id, limit=50, offset=0)

    assert [entry.total_xp for entry in global_entries] == [400, 120]
    assert [entry.user_id for entry in linux_entries] == [u2.id, u1.id]
    assert [entry.total_xp for entry in linux_entries] == [120, 100]
    assert [entry.user_id for entry in crypto_entries] == [u1.id]
    assert [entry.total_xp for entry in crypto_entries] == [300]


def test_inactive_user_excluded(session: Session) -> None:
    service = LeaderboardService()
    track = _create_track(session, "linux")
    c1 = _create_challenge(session, track, "inactive-1")
    c2 = _create_challenge(session, track, "inactive-2")

    active_user = _create_user(session, f"active-{uuid4()}@example.com", is_active=True)
    inactive_user = _create_user(session, f"inactive-{uuid4()}@example.com", is_active=False)

    _create_solve(session, user=active_user, challenge=c1, points_awarded=100, created_at=_dt(1))
    _create_solve(session, user=inactive_user, challenge=c2, points_awarded=500, created_at=_dt(1))

    entries = service.get_global_leaderboard(session, limit=50, offset=0)

    assert len(entries) == 1
    assert entries[0].user_id == active_user.id
    assert entries[0].total_xp == 100


def test_pagination_limit(session: Session) -> None:
    service = LeaderboardService()
    track = _create_track(session, "linux")

    users: list[User] = []
    for i, points in enumerate([300, 200, 100], start=1):
        challenge = _create_challenge(session, track, f"limit-{i}")
        user = _create_user(session, f"limit-{i}-{uuid4()}@example.com")
        users.append(user)
        _create_solve(session, user=user, challenge=challenge, points_awarded=points, created_at=_dt(i))

    entries = service.get_global_leaderboard(session, limit=2, offset=0)

    assert len(entries) == 2
    assert [entry.total_xp for entry in entries] == [300, 200]
    assert [entry.rank for entry in entries] == [1, 2]


def test_pagination_offset(session: Session) -> None:
    service = LeaderboardService()
    track = _create_track(session, "linux")

    for i, points in enumerate([300, 200, 100], start=1):
        challenge = _create_challenge(session, track, f"offset-{i}")
        user = _create_user(session, f"offset-{i}-{uuid4()}@example.com")
        _create_solve(session, user=user, challenge=challenge, points_awarded=points, created_at=_dt(i))

    entries = service.get_global_leaderboard(session, limit=2, offset=2)

    assert len(entries) == 1
    assert entries[0].total_xp == 100
    assert entries[0].rank == 3


@pytest.mark.parametrize(
    ("limit", "offset"),
    [
        (0, 0),
        (-1, 0),
        (1, -1),
        (501, 0),
    ],
)
def test_invalid_pagination_raises_value_error(limit: int, offset: int, session: Session) -> None:
    service = LeaderboardService()

    with pytest.raises(ValueError):
        service.get_global_leaderboard(session, limit=limit, offset=offset)
