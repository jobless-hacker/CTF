from __future__ import annotations

from typing import Any
from uuid import UUID, uuid4

from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.challenge import Challenge
from app.models.role import Role
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


def _promote_to_admin(test_session: Session, email: str) -> None:
    user = test_session.execute(select(User).where(User.email == email)).scalar_one()
    admin_role = test_session.execute(select(Role).where(Role.name == "admin")).scalar_one()
    if not any(role.name == "admin" for role in user.roles):
        user.roles.append(admin_role)
    test_session.flush()


def _seed_track(test_session: Session) -> Track:
    suffix = uuid4().hex[:8]
    track = Track(
        name=f"Linux {suffix}",
        slug=f"linux-{suffix}",
        description="Linux fundamentals and system exploitation",
        is_active=True,
    )
    test_session.add(track)
    test_session.flush()
    return track


def _auth_users(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> dict[str, str]:
    _ = seed_roles
    suffix = uuid4().hex
    password = "StrongPassword!123"
    admin_email = f"admin.contract+{suffix}@example.com"
    player_email = f"player.contract+{suffix}@example.com"

    register_user(client, admin_email, password)
    register_user(client, player_email, password)
    _promote_to_admin(test_session, admin_email)

    return {
        "admin_token": login_user(client, admin_email, password),
        "player_token": login_user(client, player_email, password),
        "admin_email": admin_email,
        "player_email": player_email,
    }


def _assert_error(response, expected_status: int) -> dict[str, Any]:
    assert response.status_code == expected_status
    body = response.json()
    assert "detail" in body
    return body


def _challenge_count(test_session: Session) -> int:
    return int(test_session.execute(select(func.count()).select_from(Challenge)).scalar_one())


def _create_challenge_http(
    client: TestClient,
    admin_token: str,
    track_id: str,
    *,
    slug: str,
    title: str = "Contract Challenge",
    description: str = "Challenge contract validation target.",
    difficulty: str = "easy",
    points: int = 100,
) -> dict[str, Any]:
    response = client.post(
        "/admin/challenges",
        json={
            "track_id": track_id,
            "title": title,
            "slug": slug,
            "description": description,
            "difficulty": difficulty,
            "points": points,
        },
        headers=auth_headers(admin_token),
    )
    assert response.status_code == 200
    return response.json()


def _set_flag_http(client: TestClient, admin_token: str, challenge_id: str, flag: str) -> None:
    response = client.post(
        f"/admin/challenges/{challenge_id}/flag",
        json={"flag": flag},
        headers=auth_headers(admin_token),
    )
    assert response.status_code == 200


def _publish_http(client: TestClient, admin_token: str, challenge_id: str) -> None:
    response = client.post(
        f"/admin/challenges/{challenge_id}/publish",
        headers=auth_headers(admin_token),
    )
    assert response.status_code == 200


def _create_published_challenge(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> dict[str, str]:
    auth_data = _auth_users(client, test_session, seed_roles)
    track = _seed_track(test_session)
    slug = f"contract-submit-{uuid4().hex[:8]}"
    created = _create_challenge_http(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug=slug,
    )
    _set_flag_http(client, auth_data["admin_token"], created["id"], f"ZTCTF{{{slug}}}")
    _publish_http(client, auth_data["admin_token"], created["id"])
    return {
        "slug": slug,
        "challenge_id": created["id"],
        "admin_token": auth_data["admin_token"],
        "player_token": auth_data["player_token"],
    }


def test_create_challenge_missing_required_fields(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    auth_data = _auth_users(client, test_session, seed_roles)
    before = _challenge_count(test_session)

    response = client.post(
        "/admin/challenges",
        json={"title": "Missing Fields"},
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = _assert_error(response, 422)

    assert isinstance(body["detail"], list)
    assert _challenge_count(test_session) == before


def test_create_challenge_invalid_difficulty_value(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    auth_data = _auth_users(client, test_session, seed_roles)
    track = _seed_track(test_session)
    slug = f"invalid-difficulty-{uuid4().hex[:8]}"
    before = _challenge_count(test_session)

    response = client.post(
        "/admin/challenges",
        json={
            "track_id": str(track.id),
            "title": "Invalid Difficulty",
            "slug": slug,
            "description": "desc",
            "difficulty": "expert",
            "points": 100,
        },
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = _assert_error(response, 422)

    assert isinstance(body["detail"], list)
    assert _challenge_count(test_session) == before
    assert test_session.execute(select(Challenge).where(Challenge.slug == slug)).scalar_one_or_none() is None


def test_create_challenge_points_negative(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    auth_data = _auth_users(client, test_session, seed_roles)
    track = _seed_track(test_session)
    slug = f"negative-points-{uuid4().hex[:8]}"
    before = _challenge_count(test_session)

    response = client.post(
        "/admin/challenges",
        json={
            "track_id": str(track.id),
            "title": "Negative Points",
            "slug": slug,
            "description": "desc",
            "difficulty": "easy",
            "points": -10,
        },
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = _assert_error(response, 422)

    assert isinstance(body["detail"], list)
    assert _challenge_count(test_session) == before


def test_create_challenge_slug_uppercase_rejected(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    auth_data = _auth_users(client, test_session, seed_roles)
    track = _seed_track(test_session)
    before = _challenge_count(test_session)

    response = client.post(
        "/admin/challenges",
        json={
            "track_id": str(track.id),
            "title": "Upper Slug",
            "slug": "UpperCase-Slug",
            "description": "desc",
            "difficulty": "easy",
            "points": 100,
        },
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = _assert_error(response, 400)

    assert body == {"detail": "Challenge creation failed."}
    assert _challenge_count(test_session) == before
    assert "flag_hash" not in body


def test_create_challenge_slug_too_long(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    auth_data = _auth_users(client, test_session, seed_roles)
    track = _seed_track(test_session)
    before = _challenge_count(test_session)

    response = client.post(
        "/admin/challenges",
        json={
            "track_id": str(track.id),
            "title": "Long Slug",
            "slug": "a" * 101,
            "description": "desc",
            "difficulty": "easy",
            "points": 100,
        },
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = _assert_error(response, 422)

    assert isinstance(body["detail"], list)
    assert _challenge_count(test_session) == before


def test_create_challenge_invalid_uuid_track_id(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    auth_data = _auth_users(client, test_session, seed_roles)
    before = _challenge_count(test_session)

    response = client.post(
        "/admin/challenges",
        json={
            "track_id": "not-a-uuid",
            "title": "Bad UUID",
            "slug": f"bad-uuid-{uuid4().hex[:8]}",
            "description": "desc",
            "difficulty": "easy",
            "points": 100,
        },
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = _assert_error(response, 422)

    assert isinstance(body["detail"], list)
    assert _challenge_count(test_session) == before


def test_set_flag_missing_flag_field(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    auth_data = _auth_users(client, test_session, seed_roles)
    track = _seed_track(test_session)
    created = _create_challenge_http(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug=f"flag-missing-{uuid4().hex[:8]}",
    )

    response = client.post(
        f"/admin/challenges/{created['id']}/flag",
        json={},
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = _assert_error(response, 422)

    assert isinstance(body["detail"], list)


def test_set_flag_empty_string(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    auth_data = _auth_users(client, test_session, seed_roles)
    track = _seed_track(test_session)
    created = _create_challenge_http(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug=f"flag-empty-{uuid4().hex[:8]}",
    )

    response = client.post(
        f"/admin/challenges/{created['id']}/flag",
        json={"flag": ""},
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = _assert_error(response, 400)

    assert body == {"detail": "Flag update failed."}
    assert "flag_hash" not in body


def test_submit_flag_missing_field(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    setup = _create_published_challenge(client, test_session, seed_roles)

    response = client.post(
        f"/challenges/{setup['slug']}/submit",
        json={},
        headers=auth_headers(setup["player_token"]),
    )
    body = _assert_error(response, 422)

    assert isinstance(body["detail"], list)


def test_submit_flag_empty_string(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    setup = _create_published_challenge(client, test_session, seed_roles)

    response = client.post(
        f"/challenges/{setup['slug']}/submit",
        json={"flag": ""},
        headers=auth_headers(setup["player_token"]),
    )
    body = _assert_error(response, 400)

    assert body == {"detail": "Invalid flag submission."}
    assert "flag_hash" not in body


def test_admin_flag_invalid_uuid_path(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    auth_data = _auth_users(client, test_session, seed_roles)

    response = client.post(
        "/admin/challenges/not-a-uuid/flag",
        json={"flag": "ZTCTF{irrelevant}"},
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = _assert_error(response, 422)

    assert isinstance(body["detail"], list)


def test_publish_invalid_uuid_path(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    auth_data = _auth_users(client, test_session, seed_roles)

    response = client.post(
        "/admin/challenges/not-a-uuid/publish",
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = _assert_error(response, 422)

    assert isinstance(body["detail"], list)
