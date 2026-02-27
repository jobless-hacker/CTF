from __future__ import annotations

from typing import Any
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.settings import get_settings
from app.models.challenge import Challenge
from app.models.challenge_flag import ChallengeFlag
from app.models.role import Role
from app.models.submission_rate_limit import SubmissionRateLimit
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


@pytest.fixture(autouse=True)
def _clear_settings_cache() -> None:
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.fixture(autouse=True)
def _cleanup_rate_limit_rows(test_session: Session) -> None:
    test_session.query(SubmissionRateLimit).delete()
    test_session.flush()
    yield
    test_session.query(SubmissionRateLimit).delete()
    test_session.flush()


def _promote_to_admin(test_session: Session, email: str) -> None:
    user = test_session.execute(select(User).where(User.email == email)).scalar_one()
    admin_role = test_session.execute(select(Role).where(Role.name == "admin")).scalar_one()
    if not any(role.name == "admin" for role in user.roles):
        user.roles.append(admin_role)
    test_session.flush()


def _seed_track(test_session: Session, *, slug_prefix: str = "linux-rate-limit") -> Track:
    suffix = uuid4().hex[:8]
    track = Track(
        name=f"Linux {suffix}",
        slug=f"{slug_prefix}-{suffix}",
        description="Linux fundamentals and system exploitation",
        is_active=True,
    )
    test_session.add(track)
    test_session.flush()
    return track


def _create_admin_and_player_tokens(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> dict[str, str]:
    _ = seed_roles
    suffix = uuid4().hex
    password = "StrongPassword!123"
    admin_email = f"admin.ratelimit+{suffix}@example.com"
    player_email = f"player.ratelimit+{suffix}@example.com"

    register_user(client, admin_email, password)
    register_user(client, player_email, password)
    _promote_to_admin(test_session, admin_email)

    return {
        "admin_token": login_user(client, admin_email, password),
        "player_token": login_user(client, player_email, password),
        "admin_email": admin_email,
        "player_email": player_email,
        "password": password,
    }


def _create_challenge(
    client: TestClient,
    admin_token: str,
    track_id: str,
    *,
    slug: str,
    title: str,
    points: int = 100,
) -> dict[str, Any]:
    response = client.post(
        "/admin/challenges",
        json={
            "track_id": track_id,
            "title": title,
            "slug": slug,
            "description": "Rate limit test challenge.",
            "difficulty": "easy",
            "points": points,
        },
        headers=auth_headers(admin_token),
    )
    assert response.status_code == 200
    return response.json()


def _set_flag(client: TestClient, admin_token: str, challenge_id: str, flag: str) -> None:
    response = client.post(
        f"/admin/challenges/{challenge_id}/flag",
        json={"flag": flag},
        headers=auth_headers(admin_token),
    )
    assert response.status_code == 200
    assert response.json() == {"message": "Flag set successfully"}


def _publish_challenge(client: TestClient, admin_token: str, challenge_id: str) -> None:
    response = client.post(
        f"/admin/challenges/{challenge_id}/publish",
        headers=auth_headers(admin_token),
    )
    assert response.status_code == 200
    assert response.json() == {"message": "Challenge published"}


def _create_ready_challenge(
    client: TestClient,
    admin_token: str,
    test_session: Session,
    *,
    slug_prefix: str = "rate-limit-challenge",
) -> dict[str, str]:
    track = _seed_track(test_session)
    slug = f"{slug_prefix}-{uuid4().hex[:8]}"
    created = _create_challenge(
        client,
        admin_token,
        str(track.id),
        slug=slug,
        title=f"Rate Limit {uuid4().hex[:6]}",
    )
    _set_flag(client, admin_token, created["id"], "ZTCTF{rate_limit_real}")
    _publish_challenge(client, admin_token, created["id"])
    return {"challenge_id": created["id"], "slug": slug, "track_slug": track.slug}


def test_under_limit_returns_200(
    monkeypatch: pytest.MonkeyPatch,
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=2, window_seconds=60, lock_seconds=5)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    ready = _create_ready_challenge(client, auth_data["admin_token"], test_session, slug_prefix="under-limit")

    response = client.post(
        f"/challenges/{ready['slug']}/submit",
        json={"flag": "ZTCTF{wrong}"},
        headers=auth_headers(auth_data["player_token"]),
    )
    body = response.json()

    assert response.status_code == 200
    assert body == {"correct": False, "xp_awarded": 0, "first_blood": False}
    assert "flag_hash" not in body


def test_exceed_limit_returns_429_with_retry_after(
    monkeypatch: pytest.MonkeyPatch,
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=1, window_seconds=60, lock_seconds=5)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    ready = _create_ready_challenge(client, auth_data["admin_token"], test_session, slug_prefix="exceed-limit")

    first_response = client.post(
        f"/challenges/{ready['slug']}/submit",
        json={"flag": "ZTCTF{wrong-1}"},
        headers=auth_headers(auth_data["player_token"]),
    )
    second_response = client.post(
        f"/challenges/{ready['slug']}/submit",
        json={"flag": "ZTCTF{wrong-2}"},
        headers=auth_headers(auth_data["player_token"]),
    )

    assert first_response.status_code == 200
    assert second_response.status_code == 429
    assert second_response.json() == {"detail": "Too many submissions. Try again later."}
    retry_after = second_response.headers.get("Retry-After")
    assert retry_after is not None
    assert int(retry_after) > 0


def test_missing_auth_still_returns_401(
    monkeypatch: pytest.MonkeyPatch,
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=1, window_seconds=60, lock_seconds=5)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    ready = _create_ready_challenge(client, auth_data["admin_token"], test_session, slug_prefix="no-auth")

    response = client.post(
        f"/challenges/{ready['slug']}/submit",
        json={"flag": "ZTCTF{wrong}"},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Authentication required."}


def test_rate_limit_is_per_challenge(
    monkeypatch: pytest.MonkeyPatch,
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=1, window_seconds=60, lock_seconds=5)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    challenge_a = _create_ready_challenge(client, auth_data["admin_token"], test_session, slug_prefix="limit-a")
    challenge_b = _create_ready_challenge(client, auth_data["admin_token"], test_session, slug_prefix="limit-b")

    first_a = client.post(
        f"/challenges/{challenge_a['slug']}/submit",
        json={"flag": "ZTCTF{wrong-a1}"},
        headers=auth_headers(auth_data["player_token"]),
    )
    second_a = client.post(
        f"/challenges/{challenge_a['slug']}/submit",
        json={"flag": "ZTCTF{wrong-a2}"},
        headers=auth_headers(auth_data["player_token"]),
    )
    first_b = client.post(
        f"/challenges/{challenge_b['slug']}/submit",
        json={"flag": "ZTCTF{wrong-b1}"},
        headers=auth_headers(auth_data["player_token"]),
    )

    assert first_a.status_code == 200
    assert second_a.status_code == 429
    assert first_b.status_code == 200


def test_rate_limit_is_per_user(
    monkeypatch: pytest.MonkeyPatch,
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    _override_rate_limit_settings(monkeypatch, max_attempts=1, window_seconds=60, lock_seconds=5)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    ready = _create_ready_challenge(client, auth_data["admin_token"], test_session, slug_prefix="per-user")

    second_player_email = f"player2.ratelimit+{uuid4().hex}@example.com"
    register_user(client, second_player_email, auth_data["password"])
    second_player_token = login_user(client, second_player_email, auth_data["password"])

    first_user_first = client.post(
        f"/challenges/{ready['slug']}/submit",
        json={"flag": "ZTCTF{wrong-u1-1}"},
        headers=auth_headers(auth_data["player_token"]),
    )
    first_user_second = client.post(
        f"/challenges/{ready['slug']}/submit",
        json={"flag": "ZTCTF{wrong-u1-2}"},
        headers=auth_headers(auth_data["player_token"]),
    )
    second_user_first = client.post(
        f"/challenges/{ready['slug']}/submit",
        json={"flag": "ZTCTF{wrong-u2-1}"},
        headers=auth_headers(second_player_token),
    )

    assert first_user_first.status_code == 200
    assert first_user_second.status_code == 429
    assert second_user_first.status_code == 200
