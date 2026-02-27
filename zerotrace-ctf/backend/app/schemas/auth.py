from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


class _AuthRequestBase(BaseModel):
    email: str = Field(min_length=1, max_length=320)
    password: str = Field(min_length=1, max_length=255)

    model_config = ConfigDict(extra="forbid")

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("Email must not be empty.")
        return normalized


class RegisterRequest(_AuthRequestBase):
    pass


class LoginRequest(_AuthRequestBase):
    pass


class UserResponse(BaseModel):
    id: UUID
    email: str
    roles: list[str]
    created_at: datetime

    model_config = ConfigDict(extra="forbid")


class MessageResponse(BaseModel):
    message: str

    model_config = ConfigDict(extra="forbid")
