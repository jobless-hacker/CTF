from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal
from urllib.parse import urlsplit

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
    AUTH_RATE_LIMIT_ENABLED: bool = True
    AUTH_RATE_LIMIT_MAX_ATTEMPTS: int = 20
    AUTH_RATE_LIMIT_WINDOW_SECONDS: int = 60
    AUTH_RATE_LIMIT_LOCK_SECONDS: int = 60
    RATE_LIMIT_BACKEND: Literal["memory", "redis"] = "redis"
    RATE_LIMIT_REDIS_URL: str = "redis://localhost:6379/0"
    RATE_LIMIT_REDIS_KEY_PREFIX: str = "zerotrace:rate_limit"
    RATE_LIMIT_REDIS_SOCKET_TIMEOUT_MS: int = Field(default=200, ge=10, le=10000)
    SUBMISSION_RATE_LIMIT_ENABLED: bool = True
    SUBMISSION_RATE_LIMIT_MAX_ATTEMPTS: int = 15
    SUBMISSION_RATE_LIMIT_WINDOW_SECONDS: int = 60
    SUBMISSION_RATE_LIMIT_LOCK_SECONDS: int = 60
    LAB_COMMAND_RATE_LIMIT_ENABLED: bool = True
    LAB_COMMAND_RATE_LIMIT_MAX_ATTEMPTS: int = 30
    LAB_COMMAND_RATE_LIMIT_WINDOW_SECONDS: int = 60
    LAB_COMMAND_RATE_LIMIT_LOCK_SECONDS: int = 30
    SEED_SYNC_WATCH_ENABLED: bool = False
    SEED_SYNC_WATCH_INTERVAL_SECONDS: float = Field(default=2.0, gt=0, le=300)
    SEED_SYNC_WATCH_DEBOUNCE_SECONDS: float = Field(default=1.0, ge=0, le=60)
    SEED_SYNC_SYNC_ON_STARTUP: bool = True
    SEED_SYNC_SEED_FILE: str = "config/seeds/foundations-challenge-todo.seed.json"
    SEED_SYNC_FLAGS_FILE: str = "config/seeds/private-flags.json"
    SEED_SYNC_MODULES_DIR: str = "config/seeds/modules"
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

        origins: list[str] = []
        seen: set[str] = set()
        for origin in self.CORS_ALLOWED_ORIGINS.split(","):
            normalized = self._normalize_cors_origin(origin)
            if not normalized or normalized in seen:
                continue
            origins.append(normalized)
            seen.add(normalized)

        return origins

    @model_validator(mode="after")
    def validate_xp_first_blood_bonus_config(self) -> "Settings":
        if self.XP_FIRST_BLOOD_BONUS_MODE == "percent":
            if self.XP_FIRST_BLOOD_BONUS_VALUE > 1000:
                raise ValueError("XP_FIRST_BLOOD_BONUS_VALUE must not exceed 1000 in percent mode.")
        elif self.XP_FIRST_BLOOD_BONUS_MODE == "fixed":
            if self.XP_FIRST_BLOOD_BONUS_VALUE > 100000:
                raise ValueError("XP_FIRST_BLOOD_BONUS_VALUE must not exceed 100000 in fixed mode.")

        self._validate_rate_limit_field(
            value=self.AUTH_RATE_LIMIT_MAX_ATTEMPTS,
            min_value=1,
            max_value=100000,
            field_name="AUTH_RATE_LIMIT_MAX_ATTEMPTS",
        )
        self._validate_rate_limit_field(
            value=self.AUTH_RATE_LIMIT_WINDOW_SECONDS,
            min_value=1,
            max_value=86400,
            field_name="AUTH_RATE_LIMIT_WINDOW_SECONDS",
        )
        self._validate_rate_limit_field(
            value=self.AUTH_RATE_LIMIT_LOCK_SECONDS,
            min_value=1,
            max_value=86400,
            field_name="AUTH_RATE_LIMIT_LOCK_SECONDS",
        )
        if self.RATE_LIMIT_BACKEND == "redis":
            redis_url = self.RATE_LIMIT_REDIS_URL.strip()
            if not redis_url:
                raise ValueError("RATE_LIMIT_REDIS_URL must not be empty when RATE_LIMIT_BACKEND=redis.")
            if not self.RATE_LIMIT_REDIS_KEY_PREFIX.strip():
                raise ValueError("RATE_LIMIT_REDIS_KEY_PREFIX must not be empty.")
        self._validate_rate_limit_field(
            value=self.SUBMISSION_RATE_LIMIT_MAX_ATTEMPTS,
            min_value=1,
            max_value=100000,
            field_name="SUBMISSION_RATE_LIMIT_MAX_ATTEMPTS",
        )
        self._validate_rate_limit_field(
            value=self.SUBMISSION_RATE_LIMIT_WINDOW_SECONDS,
            min_value=1,
            max_value=86400,
            field_name="SUBMISSION_RATE_LIMIT_WINDOW_SECONDS",
        )
        self._validate_rate_limit_field(
            value=self.SUBMISSION_RATE_LIMIT_LOCK_SECONDS,
            min_value=1,
            max_value=86400,
            field_name="SUBMISSION_RATE_LIMIT_LOCK_SECONDS",
        )
        self._validate_rate_limit_field(
            value=self.LAB_COMMAND_RATE_LIMIT_MAX_ATTEMPTS,
            min_value=1,
            max_value=100000,
            field_name="LAB_COMMAND_RATE_LIMIT_MAX_ATTEMPTS",
        )
        self._validate_rate_limit_field(
            value=self.LAB_COMMAND_RATE_LIMIT_WINDOW_SECONDS,
            min_value=1,
            max_value=86400,
            field_name="LAB_COMMAND_RATE_LIMIT_WINDOW_SECONDS",
        )
        self._validate_rate_limit_field(
            value=self.LAB_COMMAND_RATE_LIMIT_LOCK_SECONDS,
            min_value=1,
            max_value=86400,
            field_name="LAB_COMMAND_RATE_LIMIT_LOCK_SECONDS",
        )

        return self

    @staticmethod
    def _validate_rate_limit_field(
        *,
        value: int,
        min_value: int,
        max_value: int,
        field_name: str,
    ) -> None:
        if value < min_value:
            raise ValueError(f"{field_name} must be at least {min_value}.")
        if value > max_value:
            raise ValueError(f"{field_name} must not exceed {max_value}.")

    @staticmethod
    def _normalize_cors_origin(origin: str) -> str:
        value = origin.strip()
        if not value or value == "*":
            return value

        parsed = urlsplit(value)
        if parsed.scheme and parsed.netloc:
            return f"{parsed.scheme}://{parsed.netloc}".rstrip("/")

        return value.rstrip("/")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
