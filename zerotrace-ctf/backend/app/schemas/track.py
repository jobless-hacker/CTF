from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, ConfigDict


class TrackSummaryResponse(BaseModel):
    id: UUID
    name: str
    slug: str
    description: str | None
    is_active: bool

    model_config = ConfigDict(extra="forbid")
