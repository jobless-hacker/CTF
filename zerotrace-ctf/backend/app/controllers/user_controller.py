from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.user import UserXPResponse
from app.services.xp_service import XPService


_xp_service = XPService()


def get_current_user_xp(session: Session, current_user: User) -> UserXPResponse:
    try:
        total_xp = _xp_service.get_total_xp_for_user(session=session, user_id=current_user.id)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="XP retrieval failed.",
        ) from None

    return UserXPResponse(total_xp=total_xp)
