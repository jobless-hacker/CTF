from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.track import Track


def get_by_id(session: Session, track_id: UUID) -> Track | None:
    stmt = select(Track).where(Track.id == track_id)
    return session.execute(stmt).scalar_one_or_none()


def list_active(session: Session) -> list[Track]:
    stmt = select(Track).where(Track.is_active.is_(True)).order_by(Track.name.asc())
    return list(session.execute(stmt).scalars().all())
