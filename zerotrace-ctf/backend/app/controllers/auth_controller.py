from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.auth import MessageResponse, UserResponse
from app.schemas.token import AccessTokenResponse
from app.services.auth_service import AuthService
from app.services.exceptions import (
    AuthServiceError,
    InactiveUserError,
    InvalidCredentialsError,
    TokenIssuanceError,
    UserAlreadyExistsError,
)


_auth_service = AuthService()


def register_user(session: Session, email: str, password: str) -> MessageResponse:
    try:
        _auth_service.register_user(session, email=email, password=password)
        session.commit()
    except UserAlreadyExistsError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Registration failed.",
        ) from None
    except IntegrityError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Registration failed.",
        ) from None
    except AuthServiceError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed.",
        ) from None

    return MessageResponse(message="User registered successfully")


def login_user(session: Session, email: str, password: str) -> AccessTokenResponse:
    try:
        user = _auth_service.authenticate_user(session, email=email, password=password)
        return _auth_service.issue_token(user)
    except InvalidCredentialsError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials.",
        ) from None
    except InactiveUserError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        ) from None
    except TokenIssuanceError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication failed.",
        ) from None


def get_current_user_profile(user: User) -> UserResponse:
    return UserResponse(
        id=user.id,
        email=user.email,
        roles=sorted({role.name for role in user.roles if role.name}),
        created_at=user.created_at,
    )
