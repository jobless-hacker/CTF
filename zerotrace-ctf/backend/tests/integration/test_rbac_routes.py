from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.role import Role
from app.repositories import user_repository


def _register(client: TestClient, email: str, password: str) -> None:
    response = client.post(
        "/auth/register",
        json={"email": email, "password": password},
    )
    assert response.status_code == 201


def _login(client: TestClient, email: str, password: str) -> str:
    response = client.post(
        "/auth/login",
        json={"email": email, "password": password},
    )
    assert response.status_code == 200
    return response.json()["access_token"]


def _promote_to_admin(test_session: Session, email: str) -> None:
    user = user_repository.get_by_email(test_session, email)
    assert user is not None

    admin_role = test_session.execute(select(Role).where(Role.name == "admin")).scalar_one()

    if not any(role.name == "admin" for role in user.roles):
        user.roles.append(admin_role)

    test_session.flush()


def test_admin_route_access_with_admin(
    client: TestClient,
    test_session: Session,
    seed_roles: dict[str, object],
) -> None:
    _ = seed_roles
    email = "admin-user@example.com"
    password = "StrongPassword!123"
    _register(client, email, password)
    _promote_to_admin(test_session, email)
    token = _login(client, email, password)

    response = client.get("/admin/ping", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_admin_route_forbidden_for_player(
    client: TestClient,
    seed_roles: dict[str, object],
) -> None:
    _ = seed_roles
    email = "player-user@example.com"
    password = "StrongPassword!123"
    _register(client, email, password)
    token = _login(client, email, password)

    response = client.get("/admin/ping", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 403
    assert response.json() == {"detail": "Insufficient permissions"}


def test_admin_route_requires_token(client: TestClient) -> None:
    response = client.get("/admin/ping")

    assert response.status_code == 401
    assert response.json() == {"detail": "Authentication required."}
