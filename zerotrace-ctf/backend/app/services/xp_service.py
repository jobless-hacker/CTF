from __future__ import annotations

from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.challenge_solve import ChallengeSolve


class XPService:
    @staticmethod
    def get_total_xp_for_user(session: Session, user_id: UUID) -> int:
        stmt = select(func.coalesce(func.sum(ChallengeSolve.points_awarded), 0)).where(
            ChallengeSolve.user_id == user_id
        )
        total_xp = session.execute(stmt).scalar_one()
        return int(total_xp)
