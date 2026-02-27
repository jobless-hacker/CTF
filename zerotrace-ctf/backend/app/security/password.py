from __future__ import annotations

from passlib.context import CryptContext

from app.security.exceptions import PasswordHashError


_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain_password: str) -> str:
    try:
        return _pwd_context.hash(plain_password)
    except Exception:
        raise PasswordHashError("Password hashing failed.") from None


def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return _pwd_context.verify(plain_password, hashed_password)
    except Exception:
        return False
