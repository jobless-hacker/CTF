from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.schemas.admin_log import AdminLogEntryResponse, AdminLogListResponse
from app.services.admin_log_service import AdminLogService


_admin_log_service = AdminLogService()


def get_admin_logs(session: Session, limit: int, offset: int) -> AdminLogListResponse:
    try:
        entries = _admin_log_service.get_admin_logs(
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
            detail="Admin log retrieval failed.",
        ) from None

    return AdminLogListResponse(
        results=[
            AdminLogEntryResponse(
                id=entry.id,
                event_type=entry.event_type,
                severity=entry.severity,
                message=entry.message,
                created_at=entry.created_at,
                user_id=entry.user_id,
                challenge_id=entry.challenge_id,
            )
            for entry in entries
        ],
        limit=limit,
        offset=offset,
    )
