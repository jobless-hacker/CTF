from __future__ import annotations

import pytest
from sqlalchemy.orm import Session

from app.repositories import user_repository
from app.services.auth_service import AuthService
from app.services.exceptions import UserAlreadyExistsError


def test_register_user_success(
    session: Session,
    seed_roles: dict[str, object],
    auth_service: AuthService,
) -> None:
    email = "alice@example.com"
    password = "StrongPassword!123"

    user = auth_service.register_user(session, email=email, password=password)
    session.flush()

    assert user.id is not None
    assert user.email == email
    assert user.is_active is True
    assert user.password_hash != password

    user_by_email = user_repository.get_by_email(session, email)
    assert user_by_email is not None
    assert user_by_email.id == user.id

    user_by_id = user_repository.get_by_id(session, user.id)
    assert user_by_id is not None
    assert user_by_id.email == email


def test_register_user_duplicate_email(
    session: Session,
    seed_roles: dict[str, object],
    auth_service: AuthService,
) -> None:
    email = "duplicate@example.com"
    password = "StrongPassword!123"

    auth_service.register_user(session, email=email, password=password)
    session.flush()

    with pytest.raises(UserAlreadyExistsError):
        auth_service.register_user(session, email=email, password=password)


def test_register_assigns_player_role(
    session: Session,
    seed_roles: dict[str, object],
    auth_service: AuthService,
) -> None:
    user = auth_service.register_user(
        session,
        email="player-role@example.com",
        password="StrongPassword!123",
    )
    session.flush()

    role_names = sorted(role.name for role in user.roles)
    assert role_names == ["player"]
