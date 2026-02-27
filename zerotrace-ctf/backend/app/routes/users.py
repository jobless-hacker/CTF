from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.controllers import user_controller
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.user import UserXPResponse


router = APIRouter(tags=["users"])


@router.get("/users/me/xp", response_model=UserXPResponse)
def get_me_xp(
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserXPResponse:
    return user_controller.get_current_user_xp(session=session, current_user=current_user)
