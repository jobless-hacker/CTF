from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.controllers import track_controller
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.track import TrackSummaryResponse


router = APIRouter(tags=["tracks"])


@router.get("/tracks", response_model=list[TrackSummaryResponse])
def list_tracks(
    session: Session = Depends(get_db),
    _: User = Depends(get_current_user),
) -> list[TrackSummaryResponse]:
    return track_controller.list_tracks(session=session)
