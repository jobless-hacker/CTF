from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from jose import ExpiredSignatureError, JWTError, jwt as jose_jwt
from pydantic import ValidationError

from app.core.settings import get_settings
from app.schemas.token import TokenPayload
from app.security.exceptions import ExpiredTokenError, InvalidTokenError, TokenDecodeError


_DISALLOWED_CLAIMS = {"email", "password_hash"}


def create_access_token(data: dict[str, Any], expires_delta: timedelta | None = None) -> str:
    if any(claim in data for claim in _DISALLOWED_CLAIMS):
        raise InvalidTokenError("Sensitive fields are not allowed in token payload.")

    settings = get_settings()
    now = datetime.now(timezone.utc)
    lifetime = expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    payload = dict(data)
    payload["iat"] = int(now.timestamp())
    payload["exp"] = int((now + lifetime).timestamp())

    try:
        validated = TokenPayload.model_validate(payload)
    except ValidationError:
        raise InvalidTokenError("Token payload is invalid.") from None

    try:
        return jose_jwt.encode(validated.model_dump(), settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    except JWTError:
        raise InvalidTokenError("Access token creation failed.") from None


def decode_access_token(token: str) -> TokenPayload:
    settings = get_settings()

    try:
        payload = jose_jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except ExpiredSignatureError:
        raise ExpiredTokenError("Access token has expired.") from None
    except JWTError:
        raise TokenDecodeError("Access token is invalid.") from None

    try:
        return TokenPayload.model_validate(payload)
    except ValidationError:
        raise TokenDecodeError("Access token payload is invalid.") from None
