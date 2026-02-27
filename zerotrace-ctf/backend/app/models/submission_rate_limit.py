from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Integer, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class SubmissionRateLimit(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "submission_rate_limits"
    __table_args__ = (
        UniqueConstraint("user_id", "challenge_id"),
        CheckConstraint("attempt_count >= 0", name="ck_submission_rate_limits_attempt_count_non_negative"),
        CheckConstraint(
            "violation_count >= 0",
            name="ck_submission_rate_limits_violation_count_non_negative",
        ),
        Index(None, "last_attempt_at"),
        Index(None, "lock_until"),
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
    window_started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    attempt_count: Mapped[int] = mapped_column(Integer, nullable=False)
    violation_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    lock_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_attempt_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    last_blocked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user: Mapped["User"] = relationship("User", passive_deletes=True)
    challenge: Mapped["Challenge"] = relationship("Challenge", passive_deletes=True)

