from __future__ import annotations

from typing import Any
from uuid import UUID, uuid4

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.challenge import Challenge
from app.models.challenge_attempt import ChallengeAttempt
from app.models.challenge_flag import ChallengeFlag
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


def _create_challenge(
    client: TestClient,
    token: str,
    track_id: str,
    *,
    title: str = "Linux Logs 101",
    slug: str = "linux-logs-101",
    description: str = "Inspect the logs and extract the flag.",
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
        headers=auth_headers(token),
    )
    assert response.status_code == 200
    return response.json()


def _set_flag(client: TestClient, token: str, challenge_id: str, flag: str) -> None:
    response = client.post(
        f"/admin/challenges/{challenge_id}/flag",
        json={"flag": flag},
        headers=auth_headers(token),
    )
    assert response.status_code == 200
    assert response.json() == {"message": "Flag set successfully"}


def _publish_challenge(client: TestClient, token: str, challenge_id: str) -> None:
    response = client.post(
        f"/admin/challenges/{challenge_id}/publish",
        headers=auth_headers(token),
    )
    assert response.status_code == 200
    assert response.json() == {"message": "Challenge published"}


def _create_admin_and_player_tokens(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> dict[str, str]:
    _ = seed_roles
    suffix = uuid4().hex
    admin_email = f"admin.challenge+{suffix}@example.com"
    player_email = f"player.challenge+{suffix}@example.com"
    password = "StrongPassword!123"

    register_user(client, admin_email, password)
    register_user(client, player_email, password)
    _promote_to_admin(test_session, admin_email)

    admin_token = login_user(client, admin_email, password)
    player_token = login_user(client, player_email, password)
    return {
        "admin_token": admin_token,
        "player_token": player_token,
        "admin_email": admin_email,
        "player_email": player_email,
    }


def _get_user_by_email(test_session: Session, email: str) -> User:
    return test_session.execute(select(User).where(User.email == email)).scalar_one()


def _get_challenge_by_slug(test_session: Session, slug: str) -> Challenge:
    return test_session.execute(select(Challenge).where(Challenge.slug == slug)).scalar_one()


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


def test_admin_create_challenge_success(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)

    response = client.post(
        "/admin/challenges",
        json={
            "track_id": str(track.id),
            "title": "Linux Logs 101",
            "slug": "linux-logs-101",
            "description": "Inspect the logs and extract the flag.",
            "difficulty": "easy",
            "points": 100,
        },
        headers=auth_headers(auth_data["admin_token"]),
    )
    body = response.json()

    assert response.status_code == 200
    assert set(body.keys()) == {"id", "slug", "is_published"}
    assert body["slug"] == "linux-logs-101"
    assert body["is_published"] is False
    assert "flag_hash" not in body
    assert "password_hash" not in body

    challenge = _get_challenge_by_slug(test_session, "linux-logs-101")
    assert challenge.track_id == track.id
    assert challenge.points == 100


def test_admin_set_flag_success(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug="set-flag-challenge",
        title="Set Flag Challenge",
    )

    response = client.post(
        f"/admin/challenges/{created['id']}/flag",
        json={"flag": "ZTCTF{linux_flag}"},
        headers=auth_headers(auth_data["admin_token"]),
    )

    assert response.status_code == 200
    assert response.json() == {"message": "Flag set successfully"}

    challenge_id = UUID(created["id"])
    flag_row = test_session.execute(
        select(ChallengeFlag).where(ChallengeFlag.challenge_id == challenge_id)
    ).scalar_one()
    assert flag_row.flag_hash != "ZTCTF{linux_flag}"


def test_admin_publish_success(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug="publish-me",
        title="Publish Me",
    )
    _set_flag(client, auth_data["admin_token"], created["id"], "ZTCTF{publish_me}")

    response = client.post(
        f"/admin/challenges/{created['id']}/publish",
        headers=auth_headers(auth_data["admin_token"]),
    )

    assert response.status_code == 200
    assert response.json() == {"message": "Challenge published"}

    challenge = _get_challenge_by_slug(test_session, "publish-me")
    assert challenge.is_published is True


def test_admin_unpublish_success(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug="unpublish-me",
        title="Unpublish Me",
    )
    _set_flag(client, auth_data["admin_token"], created["id"], "ZTCTF{unpublish_me}")
    _publish_challenge(client, auth_data["admin_token"], created["id"])

    response = client.post(
        f"/admin/challenges/{created['id']}/unpublish",
        headers=auth_headers(auth_data["admin_token"]),
    )

    assert response.status_code == 200
    assert response.json() == {"message": "Challenge unpublished"}

    challenge = _get_challenge_by_slug(test_session, "unpublish-me")
    assert challenge.is_published is False


def test_player_cannot_create_challenge(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)

    response = client.post(
        "/admin/challenges",
        json={
            "track_id": str(track.id),
            "title": "Forbidden Create",
            "slug": "forbidden-create",
            "description": "Should not be allowed.",
            "difficulty": "easy",
            "points": 50,
        },
        headers=auth_headers(auth_data["player_token"]),
    )

    assert response.status_code == 403
    assert response.json() == {"detail": "Insufficient permissions"}

    challenge = test_session.execute(
        select(Challenge).where(Challenge.slug == "forbidden-create")
    ).scalar_one_or_none()
    assert challenge is None


def test_player_list_published_challenges(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)

    published = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        title="Published Challenge",
        slug="published-challenge",
    )
    _set_flag(client, auth_data["admin_token"], published["id"], "ZTCTF{published}")
    _publish_challenge(client, auth_data["admin_token"], published["id"])

    _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        title="Hidden Challenge",
        slug="hidden-challenge",
    )

    response = client.get(
        f"/tracks/{track.slug}/challenges",
        headers=auth_headers(auth_data["player_token"]),
    )
    body = response.json()

    assert response.status_code == 200
    assert isinstance(body, list)
    assert len(body) == 1
    assert body[0]["slug"] == "published-challenge"
    assert body[0]["is_published"] is True
    assert body[0]["lab_available"] is False
    assert body[0]["attachment_url"] is None
    assert "description" not in body[0]
    assert "flag_hash" not in body[0]
    assert "password_hash" not in body[0]


def test_player_cannot_view_unpublished(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        title="Draft Challenge",
        slug="draft-challenge",
    )

    response = client.get(
        "/challenges/draft-challenge",
        headers=auth_headers(auth_data["player_token"]),
    )

    assert response.status_code == 400
    assert response.json() == {"detail": "Challenge unavailable."}


def test_player_view_published_success(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        title="Viewable Challenge",
        slug="viewable-challenge",
        description="Find the flag in the provided artifact.",
        difficulty="medium",
        points=150,
    )
    _set_flag(client, auth_data["admin_token"], created["id"], "ZTCTF{view_me}")
    _publish_challenge(client, auth_data["admin_token"], created["id"])

    response = client.get(
        "/challenges/viewable-challenge",
        headers=auth_headers(auth_data["player_token"]),
    )
    body = response.json()

    assert response.status_code == 200
    assert body["slug"] == "viewable-challenge"
    assert body["title"] == "Viewable Challenge"
    assert body["difficulty"] == "medium"
    assert body["points"] == 150
    assert body["is_published"] is True
    assert body["lab_available"] is False
    assert body["attachment_url"] is None
    assert "description" in body
    assert "created_at" in body
    assert "updated_at" in body
    assert "flag_hash" not in body
    assert "password_hash" not in body


def test_player_submit_correct_flag(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug="submit-correct",
        title="Submit Correct",
    )
    _set_flag(client, auth_data["admin_token"], created["id"], "ZTCTF{correct_one}")
    _publish_challenge(client, auth_data["admin_token"], created["id"])

    response = client.post(
        "/challenges/submit-correct/submit",
        json={"flag": "ZTCTF{correct_one}"},
        headers=auth_headers(auth_data["player_token"]),
    )
    body = response.json()

    assert response.status_code == 200
    assert body["correct"] is True
    assert body["xp_awarded"] > 0
    assert body["first_blood"] is True
    assert set(body.keys()) == {"correct", "xp_awarded", "first_blood"}
    assert "challenge_id" not in body
    assert "flag_hash" not in body


def test_player_submit_incorrect_flag(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug="submit-incorrect",
        title="Submit Incorrect",
    )
    _set_flag(client, auth_data["admin_token"], created["id"], "ZTCTF{real_flag}")
    _publish_challenge(client, auth_data["admin_token"], created["id"])

    response = client.post(
        "/challenges/submit-incorrect/submit",
        json={"flag": "ZTCTF{wrong_flag}"},
        headers=auth_headers(auth_data["player_token"]),
    )
    body = response.json()

    assert response.status_code == 200
    assert body == {"correct": False, "xp_awarded": 0, "first_blood": False}
    assert "challenge_id" not in body


def test_second_solver_gets_base_only_and_no_first_blood_via_http(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug="submit-second-solver",
        title="Submit Second Solver",
        points=150,
    )
    _set_flag(client, auth_data["admin_token"], created["id"], "ZTCTF{second_solver}")
    _publish_challenge(client, auth_data["admin_token"], created["id"])

    second_player_email = f"player.second+{uuid4().hex}@example.com"
    password = "StrongPassword!123"
    register_user(client, second_player_email, password)
    second_player_token = login_user(client, second_player_email, password)

    first_response = client.post(
        "/challenges/submit-second-solver/submit",
        json={"flag": "ZTCTF{second_solver}"},
        headers=auth_headers(auth_data["player_token"]),
    )
    second_response = client.post(
        "/challenges/submit-second-solver/submit",
        json={"flag": "ZTCTF{second_solver}"},
        headers=auth_headers(second_player_token),
    )

    first_body = first_response.json()
    second_body = second_response.json()

    assert first_response.status_code == 200
    assert second_response.status_code == 200

    assert first_body == {"correct": True, "xp_awarded": 180, "first_blood": True}
    assert second_body == {"correct": True, "xp_awarded": 150, "first_blood": False}
    assert "challenge_id" not in first_body
    assert "challenge_id" not in second_body


def test_duplicate_correct_submit_via_http_returns_zero_xp(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug="submit-duplicate-correct",
        title="Submit Duplicate Correct",
    )
    _set_flag(client, auth_data["admin_token"], created["id"], "ZTCTF{dup_correct}")
    _publish_challenge(client, auth_data["admin_token"], created["id"])

    first_response = client.post(
        "/challenges/submit-duplicate-correct/submit",
        json={"flag": "ZTCTF{dup_correct}"},
        headers=auth_headers(auth_data["player_token"]),
    )
    second_response = client.post(
        "/challenges/submit-duplicate-correct/submit",
        json={"flag": "ZTCTF{dup_correct}"},
        headers=auth_headers(auth_data["player_token"]),
    )

    assert first_response.status_code == 200
    assert second_response.status_code == 200
    assert first_response.json() == {"correct": True, "xp_awarded": 120, "first_blood": True}
    assert second_response.json() == {"correct": True, "xp_awarded": 0, "first_blood": False}


def test_submission_requires_auth(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug="submit-no-auth",
        title="Submit No Auth",
    )
    _set_flag(client, auth_data["admin_token"], created["id"], "ZTCTF{submit_auth}")
    _publish_challenge(client, auth_data["admin_token"], created["id"])

    response = client.post(
        "/challenges/submit-no-auth/submit",
        json={"flag": "ZTCTF{submit_auth}"},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Authentication required."}


def test_admin_route_requires_token(
    client: TestClient,
    test_session: Session,
) -> None:
    track = _seed_track(test_session)

    response = client.post(
        "/admin/challenges",
        json={
            "track_id": str(track.id),
            "title": "Missing Token",
            "slug": "missing-token",
            "description": "No token provided.",
            "difficulty": "easy",
            "points": 50,
        },
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Authentication required."}


def test_admin_route_forbidden_for_player(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug="player-cannot-publish",
        title="Player Cannot Publish",
    )
    _set_flag(client, auth_data["admin_token"], created["id"], "ZTCTF{no_publish}")

    response = client.post(
        f"/admin/challenges/{created['id']}/publish",
        headers=auth_headers(auth_data["player_token"]),
    )

    assert response.status_code == 403
    assert response.json() == {"detail": "Insufficient permissions"}


def test_submit_records_attempt_via_http(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    track = _seed_track(test_session)
    auth_data = _create_admin_and_player_tokens(client, test_session, seed_roles)
    created = _create_challenge(
        client,
        auth_data["admin_token"],
        str(track.id),
        slug="attempt-recording",
        title="Attempt Recording",
    )
    _set_flag(client, auth_data["admin_token"], created["id"], "ZTCTF{attempt_real}")
    _publish_challenge(client, auth_data["admin_token"], created["id"])

    player = _get_user_by_email(test_session, auth_data["player_email"])
    challenge = _get_challenge_by_slug(test_session, "attempt-recording")

    before_count = test_session.execute(
        select(ChallengeAttempt).where(
            ChallengeAttempt.user_id == player.id,
            ChallengeAttempt.challenge_id == challenge.id,
        )
    ).scalars().all()
    assert len(before_count) == 0

    response = client.post(
        "/challenges/attempt-recording/submit",
        json={"flag": "ZTCTF{wrong_attempt}"},
        headers=auth_headers(auth_data["player_token"]),
    )

    assert response.status_code == 200
    assert response.json() == {"correct": False, "xp_awarded": 0, "first_blood": False}

    attempts = test_session.execute(
        select(ChallengeAttempt).where(
            ChallengeAttempt.user_id == player.id,
            ChallengeAttempt.challenge_id == challenge.id,
        )
    ).scalars().all()

    assert len(attempts) == 1
    assert attempts[0].is_correct is False
    assert attempts[0].submitted_flag == "ZTCTF{wrong_attempt}"
