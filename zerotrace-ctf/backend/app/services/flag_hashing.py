from __future__ import annotations

from passlib.context import CryptContext

from app.services.challenge_exceptions import FlagHashingError


_flag_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_flag(plaintext_flag: str) -> str:
    try:
        return _flag_context.hash(plaintext_flag)
    except Exception:
        raise FlagHashingError("Flag hashing failed.") from None


def verify_flag(plaintext_flag: str, hashed_flag: str) -> bool:
    try:
        return _flag_context.verify(plaintext_flag, hashed_flag)
    except Exception:
        return False
