from __future__ import annotations

from sqlalchemy import Boolean, CheckConstraint, String, event, text
from sqlalchemy.orm import EXT_SKIP, Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Track(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "tracks"
    __table_args__ = (
        CheckConstraint("slug = lower(slug)", name="ck_tracks_slug_lowercase"),
    )

    name: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    slug: Mapped[str] = mapped_column(String(64), nullable=False, unique=True)
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
        server_default=text("true"),
    )

    challenges: Mapped[list["Challenge"]] = relationship(
        "Challenge",
        back_populates="track",
    )


@event.listens_for(Track, "before_mapper_configured", retval=True)
def _defer_track_mapper_until_challenge_exists(mapper, cls):
    if "Challenge" not in cls.registry._class_registry:
        return EXT_SKIP
    return None
