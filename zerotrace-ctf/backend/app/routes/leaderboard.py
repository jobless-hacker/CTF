from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.controllers import leaderboard_controller
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.leaderboard import LeaderboardListResponse


router = APIRouter(tags=["leaderboard"])


@router.get("/leaderboard", response_model=LeaderboardListResponse)
def get_global_leaderboard(
    limit: int = 50,
    offset: int = 0,
    session: Session = Depends(get_db),
    _: User = Depends(get_current_user),
) -> LeaderboardListResponse:
    return leaderboard_controller.get_global_leaderboard(
        session=session,
        limit=limit,
        offset=offset,
    )


@router.get("/tracks/{track_id}/leaderboard", response_model=LeaderboardListResponse)
def get_track_leaderboard(
    track_id: UUID,
    limit: int = 50,
    offset: int = 0,
    session: Session = Depends(get_db),
    _: User = Depends(get_current_user),
) -> LeaderboardListResponse:
    return leaderboard_controller.get_track_leaderboard(
        session=session,
        track_id=track_id,
        limit=limit,
        offset=offset,
    )

