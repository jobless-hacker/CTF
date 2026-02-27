from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.repositories import track_repository
from app.schemas.track import TrackSummaryResponse


def list_tracks(session: Session) -> list[TrackSummaryResponse]:
    try:
        tracks = track_repository.list_active(session)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Track listing failed.",
        ) from None

    return [
        TrackSummaryResponse(
            id=track.id,
            name=track.name,
            slug=track.slug,
            description=track.description,
            is_active=track.is_active,
        )
        for track in tracks
    ]
