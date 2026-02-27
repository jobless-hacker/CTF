from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.role import Role
from app.models.user import User


def get_by_email(session: Session, email: str) -> User | None:
    stmt = (
        select(User)
        .options(selectinload(User.roles))
        .where(User.email == email)
    )
    return session.execute(stmt).scalar_one_or_none()


def get_by_id(session: Session, user_id: UUID) -> User | None:
    stmt = (
        select(User)
        .options(selectinload(User.roles))
        .where(User.id == user_id)
    )
    return session.execute(stmt).scalar_one_or_none()


def create_user(session: Session, email: str, password_hash: str) -> User:
    user = User(
        email=email,
        password_hash=password_hash,
        is_active=True,
    )
    session.add(user)
    return user


def assign_role(session: Session, user: User, role_name: str) -> None:
    with session.no_autoflush:
        role_stmt = select(Role).where(Role.name == role_name)
        role = session.execute(role_stmt).scalar_one_or_none()
        if role is None:
            raise LookupError(f"Role '{role_name}' not found.")

        if any(existing_role.name == role_name for existing_role in user.roles):
            return

        user.roles.append(role)
