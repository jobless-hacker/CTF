from __future__ import annotations

from enum import Enum
import uuid

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Integer, String, Text, text
from sqlalchemy import Enum as SqlEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class ChallengeDifficulty(str, Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"


class Challenge(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "challenges"
    __table_args__ = (
        CheckConstraint("points > 0", name="ck_challenges_points_positive"),
        CheckConstraint("slug = lower(slug)", name="ck_challenges_slug_lowercase"),
    )

    title: Mapped[str] = mapped_column(String(150), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    difficulty: Mapped[ChallengeDifficulty] = mapped_column(
        SqlEnum(
            ChallengeDifficulty,
            name="challenge_difficulty",
            native_enum=True,
            values_callable=lambda enum_cls: [member.value for member in enum_cls],
        ),
        nullable=False,
    )
    points: Mapped[int] = mapped_column(Integer, nullable=False)
    is_published: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
        server_default=text("false"),
    )
    track_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("tracks.id", ondelete="CASCADE"),
        nullable=False,
    )

    track: Mapped["Track"] = relationship("Track", back_populates="challenges")
    flag: Mapped["ChallengeFlag | None"] = relationship(
        "ChallengeFlag",
        back_populates="challenge",
        uselist=False,
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    attempts: Mapped[list["ChallengeAttempt"]] = relationship(
        "ChallengeAttempt",
        back_populates="challenge",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
