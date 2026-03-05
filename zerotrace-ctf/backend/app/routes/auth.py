from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.controllers import auth_controller
from app.core.settings import get_settings
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, MessageResponse, RegisterRequest, UserResponse
from app.schemas.token import AccessTokenResponse
from app.services.in_memory_rate_limiter import auth_rate_limiter


router = APIRouter()


def _extract_client_ip(request: Request) -> str:
    forwarded_for = request.headers.get("x-forwarded-for", "").strip()
    if forwarded_for:
        candidate = forwarded_for.split(",", maxsplit=1)[0].strip()
        if candidate:
            return candidate

    if request.client and request.client.host:
        return request.client.host
    return "unknown"


def _enforce_auth_rate_limit(request: Request, action: str) -> None:
    settings = get_settings()
    if not settings.AUTH_RATE_LIMIT_ENABLED:
        return

    client_ip = _extract_client_ip(request)
    decision = auth_rate_limiter.check_and_consume(
        key=f"auth:{action}:{client_ip}",
        max_attempts=settings.AUTH_RATE_LIMIT_MAX_ATTEMPTS,
        window_seconds=settings.AUTH_RATE_LIMIT_WINDOW_SECONDS,
        lock_seconds=settings.AUTH_RATE_LIMIT_LOCK_SECONDS,
    )
    if decision.allowed:
        return

    retry_after = decision.retry_after_seconds or 1
    raise HTTPException(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        detail="Too many authentication attempts. Try again later.",
        headers={"Retry-After": str(retry_after)},
    )


@router.post("/register", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def register(
    payload: RegisterRequest,
    request: Request,
    session: Session = Depends(get_db),
) -> MessageResponse:
    _enforce_auth_rate_limit(request, "register")
    return auth_controller.register_user(
        session=session,
        email=payload.email,
        password=payload.password,
    )


@router.post("/login", response_model=AccessTokenResponse)
def login(
    payload: LoginRequest,
    request: Request,
    session: Session = Depends(get_db),
) -> AccessTokenResponse:
    _enforce_auth_rate_limit(request, "login")
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
