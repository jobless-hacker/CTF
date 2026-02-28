from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


_BACKEND_ROOT = Path(__file__).resolve().parents[2]
_PLACEHOLDER_SECRET_KEYS = {
    "super-long-random-secret",
    "change-me",
    "changeme",
    "replace-me",
    "your-secret-key",
}


class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    OBSERVABILITY_ENABLED: bool = True
    DATABASE_URL: str
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60, gt=0)
    XP_FIRST_BLOOD_ENABLED: bool = True
    XP_FIRST_BLOOD_BONUS_MODE: Literal["fixed", "percent"] = "percent"
    XP_FIRST_BLOOD_BONUS_VALUE: int = Field(default=20, ge=0)
    SUBMISSION_RATE_LIMIT_ENABLED: bool = True
    SUBMISSION_RATE_LIMIT_MAX_ATTEMPTS: int = 15
    SUBMISSION_RATE_LIMIT_WINDOW_SECONDS: int = 60
    SUBMISSION_RATE_LIMIT_LOCK_SECONDS: int = 60
    CORS_ALLOWED_ORIGINS: str = (
        "http://localhost:5000,"
        "http://127.0.0.1:5000,"
        "http://localhost:5173,"
        "http://127.0.0.1:5173,"
        "https://jobless-hacker.github.io"
    )

    model_config = SettingsConfigDict(
        env_file=_BACKEND_ROOT / ".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, value: str) -> str:
        secret = value.strip()
        if not secret:
            raise ValueError("SECRET_KEY must not be empty.")
        if secret in _PLACEHOLDER_SECRET_KEYS:
            raise ValueError("SECRET_KEY must not use a placeholder value.")
        if len(secret) < 32:
            raise ValueError("SECRET_KEY must be at least 32 characters.")
        return secret

    @field_validator("ALGORITHM")
    @classmethod
    def validate_algorithm(cls, value: str) -> str:
        algorithm = value.strip()
        if not algorithm:
            raise ValueError("ALGORITHM must not be empty.")
        return algorithm

    @field_validator("DATABASE_URL")
    @classmethod
    def validate_database_url(cls, value: str) -> str:
        database_url = value.strip()
        if not database_url:
            raise ValueError("DATABASE_URL must not be empty.")
        return database_url

    @field_validator("ENVIRONMENT")
    @classmethod
    def validate_environment(cls, value: str) -> str:
        environment = value.strip()
        if not environment:
            raise ValueError("ENVIRONMENT must not be empty.")
        return environment

    @property
    def cors_allowed_origins(self) -> list[str]:
        if self.CORS_ALLOWED_ORIGINS.strip() == "*":
            return ["*"]

        return [
            origin.strip()
            for origin in self.CORS_ALLOWED_ORIGINS.split(",")
            if origin.strip()
        ]

    @model_validator(mode="after")
    def validate_xp_first_blood_bonus_config(self) -> "Settings":
        if self.XP_FIRST_BLOOD_BONUS_MODE == "percent":
            if self.XP_FIRST_BLOOD_BONUS_VALUE > 1000:
                raise ValueError("XP_FIRST_BLOOD_BONUS_VALUE must not exceed 1000 in percent mode.")
        elif self.XP_FIRST_BLOOD_BONUS_MODE == "fixed":
            if self.XP_FIRST_BLOOD_BONUS_VALUE > 100000:
                raise ValueError("XP_FIRST_BLOOD_BONUS_VALUE must not exceed 100000 in fixed mode.")

        if self.SUBMISSION_RATE_LIMIT_MAX_ATTEMPTS < 1:
            raise ValueError("SUBMISSION_RATE_LIMIT_MAX_ATTEMPTS must be at least 1.")
        if self.SUBMISSION_RATE_LIMIT_MAX_ATTEMPTS > 100000:
            raise ValueError("SUBMISSION_RATE_LIMIT_MAX_ATTEMPTS must not exceed 100000.")
        if self.SUBMISSION_RATE_LIMIT_WINDOW_SECONDS < 1:
            raise ValueError("SUBMISSION_RATE_LIMIT_WINDOW_SECONDS must be at least 1.")
        if self.SUBMISSION_RATE_LIMIT_WINDOW_SECONDS > 86400:
            raise ValueError("SUBMISSION_RATE_LIMIT_WINDOW_SECONDS must not exceed 86400.")
        if self.SUBMISSION_RATE_LIMIT_LOCK_SECONDS < 1:
            raise ValueError("SUBMISSION_RATE_LIMIT_LOCK_SECONDS must be at least 1.")
        if self.SUBMISSION_RATE_LIMIT_LOCK_SECONDS > 86400:
            raise ValueError("SUBMISSION_RATE_LIMIT_LOCK_SECONDS must not exceed 86400.")

        return self


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
