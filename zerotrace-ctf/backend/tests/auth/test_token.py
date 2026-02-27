from __future__ import annotations

from datetime import timedelta
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.security.exceptions import InvalidTokenError
from app.security.jwt import create_access_token
from app.security.password import hash_password, verify_password
from app.services.auth_service import AuthService
from app.services.exceptions import ExpiredAuthTokenError, TokenIssuanceError, TokenValidationError


def _registered_user(session: Session, auth_service: AuthService):
    user = auth_service.register_user(
        session,
        email=f"user-{uuid4()}@example.com",
        password="StrongPassword!123",
    )
    session.flush()
    return user


def test_issue_token_success(
    session: Session,
    seed_roles: dict[str, object],
    auth_service: AuthService,
) -> None:
    user = _registered_user(session, auth_service)

    response = auth_service.issue_token(user)
    response_data = response.model_dump()

    assert isinstance(response.access_token, str)
    assert response.access_token
    assert response.token_type == "bearer"
    assert set(response_data.keys()) == {"access_token", "token_type"}
    assert "password_hash" not in response_data


def test_token_payload_contains_expected_fields(
    session: Session,
    seed_roles: dict[str, object],
    auth_service: AuthService,
) -> None:
    user = _registered_user(session, auth_service)

    response = auth_service.issue_token(user)
    payload = auth_service.validate_token(response.access_token)
    payload_data = payload.model_dump()

    assert set(payload_data.keys()) == {"sub", "roles", "exp", "iat"}
    assert "email" not in payload_data
    assert "password_hash" not in payload_data
    assert "is_active" not in payload_data


def test_validate_token_success(
    session: Session,
    seed_roles: dict[str, object],
    auth_service: AuthService,
) -> None:
    user = _registered_user(session, auth_service)
    response = auth_service.issue_token(user)

    payload = auth_service.validate_token(response.access_token)

    assert payload.sub == str(user.id)
    assert payload.roles == ["player"]
    assert payload.exp >= payload.iat


def test_validate_token_expired(auth_service: AuthService) -> None:
    token = create_access_token(
        {"sub": str(uuid4()), "roles": ["player"]},
        expires_delta=timedelta(seconds=-1),
    )

    with pytest.raises(ExpiredAuthTokenError):
        auth_service.validate_token(token)


def test_validate_token_tampered(
    session: Session,
    seed_roles: dict[str, object],
    auth_service: AuthService,
) -> None:
    user = _registered_user(session, auth_service)
    response = auth_service.issue_token(user)
    token = response.access_token
    header, payload, signature = token.split(".")
    tampered_signature = f"{'a' if signature[0] != 'a' else 'b'}{signature[1:]}"
    tampered = ".".join([header, payload, tampered_signature])

    with pytest.raises(TokenValidationError):
        auth_service.validate_token(tampered)


def test_password_hash_not_equal_plaintext() -> None:
    plain_password = "StrongPassword!123"

    hashed_password = hash_password(plain_password)

    assert hashed_password != plain_password


def test_verify_password_false_on_invalid_hash() -> None:
    assert verify_password("StrongPassword!123", "not-a-valid-hash") is False


def test_token_rejects_sensitive_claim_injection() -> None:
    with pytest.raises(InvalidTokenError):
        create_access_token(
            {
                "sub": str(uuid4()),
                "roles": ["player"],
                "email": "user@example.com",
            }
        )

    with pytest.raises(InvalidTokenError):
        create_access_token(
            {
                "sub": str(uuid4()),
                "roles": ["player"],
                "password_hash": "should-not-be-allowed",
            }
        )


def test_issue_token_missing_user_id_raises(
    auth_service: AuthService,
) -> None:
    from app.models.user import User

    user = User(
        email="no-id@example.com",
        password_hash="hashed-password",
        is_active=True,
    )

    with pytest.raises(TokenIssuanceError):
        auth_service.issue_token(user)
