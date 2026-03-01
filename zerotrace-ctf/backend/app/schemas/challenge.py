from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.challenge import ChallengeDifficulty


class CreateChallengeRequest(BaseModel):
    track_id: UUID
    title: str = Field(min_length=1, max_length=150)
    slug: str = Field(min_length=1, max_length=100)
    description: str = Field(min_length=1)
    difficulty: ChallengeDifficulty
    points: int = Field(gt=0)
    attachment_url: str | None = None

    model_config = ConfigDict(extra="forbid")

    @field_validator("title", "slug", "description")
    @classmethod
    def strip_text_fields(cls, value: str) -> str:
        return value.strip()


class SetFlagRequest(BaseModel):
    flag: str

    model_config = ConfigDict(extra="forbid")


class SubmitFlagRequest(BaseModel):
    flag: str

    model_config = ConfigDict(extra="forbid")


class ChallengeLabCommandRequest(BaseModel):
    command: str = Field(min_length=1, max_length=256)
    cwd: str = Field(default="/", min_length=1, max_length=256)

    model_config = ConfigDict(extra="forbid")

    @field_validator("command", "cwd")
    @classmethod
    def strip_command_fields(cls, value: str) -> str:
        return value.strip()


class ChallengeCreateResponse(BaseModel):
    id: UUID
    slug: str
    is_published: bool

    model_config = ConfigDict(extra="forbid")


class ChallengeSummaryResponse(BaseModel):
    id: UUID
    track_id: UUID
    title: str
    slug: str
    difficulty: ChallengeDifficulty
    points: int
    is_published: bool
    lab_available: bool
    attachment_url: str | None

    model_config = ConfigDict(extra="forbid")


class ChallengeDetailResponse(BaseModel):
    id: UUID
    track_id: UUID
    title: str
    slug: str
    description: str
    difficulty: ChallengeDifficulty
    points: int
    is_published: bool
    lab_available: bool
    attachment_url: str | None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(extra="forbid")


class SubmitFlagResponse(BaseModel):
    correct: bool
    xp_awarded: int = Field(ge=0)
    first_blood: bool

    model_config = ConfigDict(extra="forbid")


class ChallengeLabCommandResponse(BaseModel):
    output: str
    cwd: str
    exit_code: int

    model_config = ConfigDict(extra="forbid")


class ChallengeActionMessageResponse(BaseModel):
    message: str

    model_config = ConfigDict(extra="forbid")
