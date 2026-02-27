from __future__ import annotations

from datetime import timedelta
from uuid import uuid4

from fastapi.testclient import TestClient

from app.security.jwt import create_access_token


def _register(client: TestClient, email: str, password: str) -> None:
    response = client.post(
        "/auth/register",
        json={"email": email, "password": password},
    )
    assert response.status_code == 201


def _login(client: TestClient, email: str, password: str) -> dict[str, str]:
    response = client.post(
        "/auth/login",
        json={"email": email, "password": password},
    )
    assert response.status_code == 200
    return response.json()


def test_register_success(client: TestClient, seed_roles: dict[str, object]) -> None:
    _ = seed_roles
    response = client.post(
        "/auth/register",
        json={"email": "register@example.com", "password": "StrongPassword!123"},
    )

    assert response.status_code == 201
    assert response.json() == {"message": "User registered successfully"}


def test_register_duplicate_email(client: TestClient, seed_roles: dict[str, object]) -> None:
    _ = seed_roles
    payload = {"email": "duplicate@example.com", "password": "StrongPassword!123"}

    first = client.post("/auth/register", json=payload)
    second = client.post("/auth/register", json=payload)

    assert first.status_code == 201
    assert second.status_code == 400
    assert second.json() == {"detail": "Registration failed."}


def test_login_success(client: TestClient, seed_roles: dict[str, object]) -> None:
    _ = seed_roles
    email = "login@example.com"
    password = "StrongPassword!123"
    _register(client, email, password)

    response = client.post("/auth/login", json={"email": email, "password": password})
    body = response.json()

    assert response.status_code == 200
    assert isinstance(body["access_token"], str)
    assert body["access_token"]
    assert body["token_type"] == "bearer"


def test_login_invalid_password(client: TestClient, seed_roles: dict[str, object]) -> None:
    _ = seed_roles
    email = "bad-password@example.com"
    _register(client, email, "StrongPassword!123")

    response = client.post(
        "/auth/login",
        json={"email": email, "password": "WrongPassword!123"},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Invalid authentication credentials."}


def test_me_requires_token(client: TestClient) -> None:
    response = client.get("/auth/me")

    assert response.status_code == 401
    assert response.json() == {"detail": "Authentication required."}


def test_me_success(client: TestClient, seed_roles: dict[str, object]) -> None:
    _ = seed_roles
    email = "me@example.com"
    password = "StrongPassword!123"
    _register(client, email, password)
    token_data = _login(client, email, password)

    response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {token_data['access_token']}"},
    )
    body = response.json()

    assert response.status_code == 200
    assert body["email"] == email
    assert isinstance(body["id"], str)
    assert body["roles"] == ["player"]
    assert "created_at" in body


def test_login_returns_bearer_token(client: TestClient, seed_roles: dict[str, object]) -> None:
    _ = seed_roles
    email = "bearer@example.com"
    password = "StrongPassword!123"
    _register(client, email, password)

    response = client.post("/auth/login", json={"email": email, "password": password})

    assert response.status_code == 200
    assert response.json()["token_type"] == "bearer"


def test_me_does_not_expose_password_hash(client: TestClient, seed_roles: dict[str, object]) -> None:
    _ = seed_roles
    email = "safe-me@example.com"
    password = "StrongPassword!123"
    _register(client, email, password)
    token_data = _login(client, email, password)

    response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {token_data['access_token']}"},
    )
    body = response.json()

    assert response.status_code == 200
    assert "password_hash" not in body


def test_invalid_token_rejected(client: TestClient) -> None:
    response = client.get(
        "/auth/me",
        headers={"Authorization": "Bearer invalid.token.value"},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Invalid authentication credentials."}


def test_expired_token_rejected(client: TestClient) -> None:
    expired_token = create_access_token(
        {"sub": str(uuid4()), "roles": ["player"]},
        expires_delta=timedelta(seconds=-1),
    )

    response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {expired_token}"},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Invalid authentication credentials."}
