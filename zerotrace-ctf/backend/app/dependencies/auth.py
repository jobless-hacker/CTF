from __future__ import annotations

from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.dependencies.db import get_db
from app.models.user import User
from app.repositories import user_repository
from app.services.auth_service import AuthService
from app.services.exceptions import ExpiredAuthTokenError, TokenValidationError


_auth_service = AuthService()


def get_current_user(
    session: Session = Depends(get_db),
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> User:
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required.",
        )

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials.",
        )

    try:
        payload = _auth_service.validate_token(token.strip())
    except (ExpiredAuthTokenError, TokenValidationError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials.",
        ) from None

    try:
        user_id = UUID(payload.sub)
    except (TypeError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials.",
        ) from None

    user = user_repository.get_by_id(session, user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )

    return user
