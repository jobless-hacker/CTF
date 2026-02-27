from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UUIDPrimaryKeyMixin


class ChallengeSolve(UUIDPrimaryKeyMixin, Base):
    __tablename__ = "challenge_solves"
    __table_args__ = (
        CheckConstraint("points_awarded > 0", name="ck_challenge_solves_points_awarded_positive"),
        UniqueConstraint("user_id", "challenge_id"),
        Index(None, "user_id"),
        Index(None, "challenge_id"),
        Index("ix_challenge_solves_challenge_id_created_at", "challenge_id", "created_at"),
        Index("ix_challenge_solves_user_id_created_at", "user_id", "created_at"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    challenge_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("challenges.id", ondelete="CASCADE"),
        nullable=False,
    )
    points_awarded: Mapped[int] = mapped_column(Integer, nullable=False)
    is_first_blood: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
        server_default=text("false"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    user: Mapped["User"] = relationship(
        "User",
        passive_deletes=True,
    )
    challenge: Mapped["Challenge"] = relationship(
        "Challenge",
        passive_deletes=True,
    )
