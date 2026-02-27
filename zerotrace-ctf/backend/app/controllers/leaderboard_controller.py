from __future__ import annotations

from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.repositories import track_repository
from app.schemas.leaderboard import LeaderboardEntryResponse, LeaderboardListResponse
from app.services.leaderboard_service import LeaderboardService


_leaderboard_service = LeaderboardService()


def get_global_leaderboard(session: Session, limit: int, offset: int) -> LeaderboardListResponse:
    try:
        entries = _leaderboard_service.get_global_leaderboard(
            session=session,
            limit=limit,
            offset=offset,
        )
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid pagination parameters.",
        ) from None
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Leaderboard retrieval failed.",
        ) from None

    return LeaderboardListResponse(
        results=[_map_entry(entry) for entry in entries],
        limit=limit,
        offset=offset,
    )


def get_track_leaderboard(session: Session, track_id: UUID, limit: int, offset: int) -> LeaderboardListResponse:
    if track_repository.get_by_id(session, track_id) is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Track not found.",
        )

    try:
        entries = _leaderboard_service.get_track_leaderboard(
            session=session,
            track_id=track_id,
            limit=limit,
            offset=offset,
        )
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid pagination parameters.",
        ) from None
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Leaderboard retrieval failed.",
        ) from None

    return LeaderboardListResponse(
        results=[_map_entry(entry) for entry in entries],
        limit=limit,
        offset=offset,
    )


def _map_entry(entry) -> LeaderboardEntryResponse:
    return LeaderboardEntryResponse(
        user_id=entry.user_id,
        total_xp=entry.total_xp,
        first_solve_at=entry.first_solve_at,
        rank=entry.rank,
    )

