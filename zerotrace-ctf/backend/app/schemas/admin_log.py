from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class AdminLogEntryResponse(BaseModel):
    id: UUID
    event_type: str
    severity: str
    message: str
    created_at: datetime
    user_id: UUID | None = None
    challenge_id: UUID | None = None

    model_config = ConfigDict(extra="forbid")


class AdminLogListResponse(BaseModel):
    results: list[AdminLogEntryResponse]
    limit: int = Field(ge=1)
    offset: int = Field(ge=0)

    model_config = ConfigDict(extra="forbid")
