from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class TokenPayload(BaseModel):
    sub: str
    roles: list[str]
    exp: int
    iat: int

    model_config = ConfigDict(extra="forbid")


class AccessTokenResponse(BaseModel):
    access_token: str
    token_type: str = Field(default="bearer")
