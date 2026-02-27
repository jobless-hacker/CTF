from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class UserXPResponse(BaseModel):
    total_xp: int = Field(ge=0)

    model_config = ConfigDict(extra="forbid")
