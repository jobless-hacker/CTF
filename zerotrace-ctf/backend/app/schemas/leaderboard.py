from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class LeaderboardEntryResponse(BaseModel):
    user_id: UUID
    total_xp: int = Field(ge=0)
    first_solve_at: datetime
    rank: int = Field(ge=1)

    model_config = ConfigDict(extra="forbid")


class LeaderboardListResponse(BaseModel):
    results: list[LeaderboardEntryResponse]
    limit: int = Field(ge=1)
    offset: int = Field(ge=0)

    model_config = ConfigDict(extra="forbid")

