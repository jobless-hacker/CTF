from __future__ import annotations

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.controllers import auth_controller
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, MessageResponse, RegisterRequest, UserResponse
from app.schemas.token import AccessTokenResponse


router = APIRouter()


@router.post("/register", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def register(
    payload: RegisterRequest,
    session: Session = Depends(get_db),
) -> MessageResponse:
    return auth_controller.register_user(
        session=session,
        email=payload.email,
        password=payload.password,
    )


@router.post("/login", response_model=AccessTokenResponse)
def login(
    payload: LoginRequest,
    session: Session = Depends(get_db),
) -> AccessTokenResponse:
    return auth_controller.login_user(
        session=session,
        email=payload.email,
        password=payload.password,
    )


@router.get("/me", response_model=UserResponse)
def get_me(
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    return auth_controller.get_current_user_profile(current_user)
