from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.controllers import admin_log_controller
from app.dependencies.db import get_db
from app.dependencies.rbac import require_admin
from app.models.user import User
from app.schemas.admin_log import AdminLogListResponse


router = APIRouter(tags=["admin"])


@router.get("/admin/logs", response_model=AdminLogListResponse)
def get_admin_logs(
    limit: int = 50,
    offset: int = 0,
    session: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> AdminLogListResponse:
    return admin_log_controller.get_admin_logs(session=session, limit=limit, offset=offset)
