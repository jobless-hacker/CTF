from __future__ import annotations

import pytest
from sqlalchemy.orm import Session

from app.services.auth_service import AuthService
from app.services.exceptions import InactiveUserError, InvalidCredentialsError


def _register_user(session: Session, auth_service: AuthService, *, email: str, password: str):
    user = auth_service.register_user(session, email=email, password=password)
    session.flush()
    return user


def test_authenticate_user_success(
    session: Session,
    seed_roles: dict[str, object],
    auth_service: AuthService,
) -> None:
    email = "auth-success@example.com"
    password = "StrongPassword!123"
    registered_user = _register_user(session, auth_service, email=email, password=password)

    authenticated_user = auth_service.authenticate_user(session, email=email, password=password)

    assert authenticated_user.id == registered_user.id
    assert authenticated_user.email == email
    assert authenticated_user.is_active is True


def test_authenticate_invalid_password(
    session: Session,
    seed_roles: dict[str, object],
    auth_service: AuthService,
) -> None:
    email = "invalid-password@example.com"
    _register_user(session, auth_service, email=email, password="StrongPassword!123")

    with pytest.raises(InvalidCredentialsError):
        auth_service.authenticate_user(session, email=email, password="WrongPassword!123")


def test_authenticate_nonexistent_user(
    session: Session,
    auth_service: AuthService,
) -> None:
    with pytest.raises(InvalidCredentialsError):
        auth_service.authenticate_user(
            session,
            email="missing@example.com",
            password="StrongPassword!123",
        )


def test_authenticate_inactive_user(
    session: Session,
    seed_roles: dict[str, object],
    auth_service: AuthService,
) -> None:
    email = "inactive@example.com"
    password = "StrongPassword!123"
    user = _register_user(session, auth_service, email=email, password=password)
    user.is_active = False
    session.flush()

    with pytest.raises(InactiveUserError):
        auth_service.authenticate_user(session, email=email, password=password)
