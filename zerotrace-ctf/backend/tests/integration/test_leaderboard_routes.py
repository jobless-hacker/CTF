from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import delete
from sqlalchemy.orm import Session

from app.models.challenge import Challenge, ChallengeDifficulty
from app.models.challenge_solve import ChallengeSolve
from app.models.track import Track
from app.models.user import User


def register_user(client: TestClient, email: str, password: str) -> None:
    response = client.post("/auth/register", json={"email": email, "password": password})
    assert response.status_code == 201


def login_user(client: TestClient, email: str, password: str) -> str:
    response = client.post("/auth/login", json={"email": email, "password": password})
    assert response.status_code == 200
    return response.json()["access_token"]


def auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _dt(day: int, hour: int = 0, minute: int = 0) -> datetime:
    return datetime(2026, 1, day, hour, minute, tzinfo=timezone.utc)


@pytest.fixture(autouse=True)
def _isolate_leaderboard_solves(test_session: Session):
    test_session.execute(delete(ChallengeSolve))
    test_session.flush()
    yield
    test_session.execute(delete(ChallengeSolve))
    test_session.flush()


def _auth_requester_token(
    client: TestClient,
    seed_roles: dict[str, object],
) -> str:
    _ = seed_roles
    suffix = uuid4().hex
    email = f"leaderboard.viewer+{suffix}@example.com"
    password = "StrongPassword!123"
    register_user(client, email, password)
    return login_user(client, email, password)


def _create_track(
    test_session: Session,
    *,
    slug: str,
    name: str | None = None,
) -> Track:
    track = Track(
        name=name or slug.title(),
        slug=slug,
        description=f"{slug} track",
        is_active=True,
    )
    test_session.add(track)
    test_session.flush()
    return track


def _create_challenge(
    test_session: Session,
    *,
    track: Track,
    slug: str,
    points: int = 100,
) -> Challenge:
    challenge = Challenge(
        track_id=track.id,
        title=f"Challenge {slug}",
        slug=slug,
        description="Leaderboard integration test challenge",
        difficulty=ChallengeDifficulty.EASY,
        points=points,
        is_published=True,
    )
    test_session.add(challenge)
    test_session.flush()
    return challenge


def _create_user(
    test_session: Session,
    *,
    email: str | None = None,
    is_active: bool = True,
) -> User:
    user = User(
        email=email or f"user-{uuid4()}@example.com",
        password_hash="placeholder-hash",
        is_active=is_active,
    )
    test_session.add(user)
    test_session.flush()
    return user


def _create_solve(
    test_session: Session,
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
    test_session.add(solve)
    test_session.flush()
    return solve


def test_empty_leaderboard_returns_empty_results(
    client: TestClient,
    seed_roles: dict[str, object],
) -> None:
    token = _auth_requester_token(client, seed_roles)

    response = client.get("/leaderboard", headers=auth_headers(token))
    body = response.json()

    assert response.status_code == 200
    assert body == {"results": [], "limit": 50, "offset": 0}


def test_global_leaderboard_ranking_correct(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    token = _auth_requester_token(client, seed_roles)
    track = _create_track(test_session, slug=f"linux-{uuid4().hex[:8]}")
    ch1 = _create_challenge(test_session, track=track, slug=f"glb-a-{uuid4().hex[:8]}")
    ch2 = _create_challenge(test_session, track=track, slug=f"glb-b-{uuid4().hex[:8]}")
    ch3 = _create_challenge(test_session, track=track, slug=f"glb-c-{uuid4().hex[:8]}")

    u1 = _create_user(test_session)
    u2 = _create_user(test_session)
    u3 = _create_user(test_session)

    _create_solve(test_session, user=u1, challenge=ch1, points_awarded=100, created_at=_dt(1))
    _create_solve(test_session, user=u1, challenge=ch2, points_awarded=80, created_at=_dt(2))
    _create_solve(test_session, user=u2, challenge=ch3, points_awarded=150, created_at=_dt(1, 1))
    _create_solve(test_session, user=u3, challenge=ch2, points_awarded=90, created_at=_dt(1, 2))

    response = client.get("/leaderboard", headers=auth_headers(token))
    body = response.json()

    assert response.status_code == 200
    assert body["limit"] == 50
    assert body["offset"] == 0
    assert [row["user_id"] for row in body["results"]] == [str(u1.id), str(u2.id), str(u3.id)]
    assert [row["total_xp"] for row in body["results"]] == [180, 150, 90]
    assert [row["rank"] for row in body["results"]] == [1, 2, 3]
    for row in body["results"]:
        assert set(row.keys()) == {"user_id", "total_xp", "first_solve_at", "rank"}
        assert "email" not in row
        assert "challenge_id" not in row


def test_track_leaderboard_filtering_correct(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    token = _auth_requester_token(client, seed_roles)
    linux_track = _create_track(test_session, slug=f"linux-{uuid4().hex[:8]}")
    crypto_track = _create_track(test_session, slug=f"crypto-{uuid4().hex[:8]}", name="Cryptography")
    linux_a = _create_challenge(test_session, track=linux_track, slug=f"linux-a-{uuid4().hex[:8]}")
    linux_b = _create_challenge(test_session, track=linux_track, slug=f"linux-b-{uuid4().hex[:8]}")
    crypto_a = _create_challenge(test_session, track=crypto_track, slug=f"crypto-a-{uuid4().hex[:8]}")

    u1 = _create_user(test_session)
    u2 = _create_user(test_session)
    _create_solve(test_session, user=u1, challenge=linux_a, points_awarded=100, created_at=_dt(1))
    _create_solve(test_session, user=u1, challenge=crypto_a, points_awarded=300, created_at=_dt(2))
    _create_solve(test_session, user=u2, challenge=linux_b, points_awarded=120, created_at=_dt(1, 1))

    response = client.get(
        f"/tracks/{linux_track.id}/leaderboard",
        headers=auth_headers(token),
    )
    body = response.json()

    assert response.status_code == 200
    assert [row["user_id"] for row in body["results"]] == [str(u2.id), str(u1.id)]
    assert [row["total_xp"] for row in body["results"]] == [120, 100]
    assert [row["rank"] for row in body["results"]] == [1, 2]


def test_inactive_user_excluded(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    token = _auth_requester_token(client, seed_roles)
    track = _create_track(test_session, slug=f"linux-{uuid4().hex[:8]}")
    ch1 = _create_challenge(test_session, track=track, slug=f"active-{uuid4().hex[:8]}")
    ch2 = _create_challenge(test_session, track=track, slug=f"inactive-{uuid4().hex[:8]}")

    active_user = _create_user(test_session, is_active=True)
    inactive_user = _create_user(test_session, is_active=False)
    _create_solve(test_session, user=active_user, challenge=ch1, points_awarded=100, created_at=_dt(1))
    _create_solve(test_session, user=inactive_user, challenge=ch2, points_awarded=500, created_at=_dt(1))

    response = client.get("/leaderboard", headers=auth_headers(token))
    body = response.json()

    assert response.status_code == 200
    assert len(body["results"]) == 1
    assert body["results"][0]["user_id"] == str(active_user.id)
    assert body["results"][0]["total_xp"] == 100


def test_pagination_limit_works(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    token = _auth_requester_token(client, seed_roles)
    track = _create_track(test_session, slug=f"linux-{uuid4().hex[:8]}")
    for idx, points in enumerate([300, 200, 100], start=1):
        user = _create_user(test_session)
        challenge = _create_challenge(test_session, track=track, slug=f"limit-{idx}-{uuid4().hex[:8]}")
        _create_solve(test_session, user=user, challenge=challenge, points_awarded=points, created_at=_dt(idx))

    response = client.get("/leaderboard?limit=2", headers=auth_headers(token))
    body = response.json()

    assert response.status_code == 200
    assert body["limit"] == 2
    assert body["offset"] == 0
    assert len(body["results"]) == 2
    assert [row["total_xp"] for row in body["results"]] == [300, 200]
    assert [row["rank"] for row in body["results"]] == [1, 2]


def test_pagination_offset_works(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    token = _auth_requester_token(client, seed_roles)
    track = _create_track(test_session, slug=f"linux-{uuid4().hex[:8]}")
    for idx, points in enumerate([300, 200, 100], start=1):
        user = _create_user(test_session)
        challenge = _create_challenge(test_session, track=track, slug=f"offset-{idx}-{uuid4().hex[:8]}")
        _create_solve(test_session, user=user, challenge=challenge, points_awarded=points, created_at=_dt(idx))

    response = client.get("/leaderboard?limit=2&offset=2", headers=auth_headers(token))
    body = response.json()

    assert response.status_code == 200
    assert body["limit"] == 2
    assert body["offset"] == 2
    assert len(body["results"]) == 1
    assert body["results"][0]["total_xp"] == 100
    assert body["results"][0]["rank"] == 3


def test_invalid_limit_returns_400(
    client: TestClient,
    seed_roles: dict[str, object],
) -> None:
    token = _auth_requester_token(client, seed_roles)

    response = client.get("/leaderboard?limit=0", headers=auth_headers(token))

    assert response.status_code == 400
    assert response.json() == {"detail": "Invalid pagination parameters."}


def test_invalid_offset_returns_400(
    client: TestClient,
    seed_roles: dict[str, object],
) -> None:
    token = _auth_requester_token(client, seed_roles)

    response = client.get("/leaderboard?offset=-1", headers=auth_headers(token))

    assert response.status_code == 400
    assert response.json() == {"detail": "Invalid pagination parameters."}


def test_missing_track_returns_404(
    client: TestClient,
    seed_roles: dict[str, object],
) -> None:
    token = _auth_requester_token(client, seed_roles)

    response = client.get(f"/tracks/{uuid4()}/leaderboard", headers=auth_headers(token))

    assert response.status_code == 404
    assert response.json() == {"detail": "Track not found."}


def test_leaderboard_requires_authentication(client: TestClient) -> None:
    response = client.get("/leaderboard")

    assert response.status_code == 401
    assert response.json() == {"detail": "Authentication required."}
