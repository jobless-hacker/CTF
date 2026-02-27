from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import List
from uuid import UUID

from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from app.models.challenge_attempt import ChallengeAttempt


@dataclass(frozen=True, slots=True)
class AdminLogEntry:
    id: UUID
    event_type: str
    severity: str
    message: str
    created_at: datetime
    user_id: UUID | None
    challenge_id: UUID | None


class AdminLogService:
    MAX_LIMIT = 500

    def get_admin_logs(self, session: Session, limit: int, offset: int) -> List[AdminLogEntry]:
        validated_limit, validated_offset = self._validate_pagination(limit, offset)
        query = self._build_attempt_log_query(validated_limit, validated_offset)
        rows = session.execute(query).all()
        return [self._map_attempt_row(row) for row in rows]

    @classmethod
    def _validate_pagination(cls, limit: int, offset: int) -> tuple[int, int]:
        if isinstance(limit, bool) or not isinstance(limit, int):
            raise ValueError("limit must be an integer.")
        if isinstance(offset, bool) or not isinstance(offset, int):
            raise ValueError("offset must be an integer.")
        if limit <= 0:
            raise ValueError("limit must be greater than zero.")
        if offset < 0:
            raise ValueError("offset must be greater than or equal to zero.")
        if limit > cls.MAX_LIMIT:
            raise ValueError(f"limit must be less than or equal to {cls.MAX_LIMIT}.")
        return limit, offset

    @staticmethod
    def _build_attempt_log_query(limit: int, offset: int) -> Select:
        return (
            select(
                ChallengeAttempt.id,
                ChallengeAttempt.is_correct,
                ChallengeAttempt.created_at,
                ChallengeAttempt.user_id,
                ChallengeAttempt.challenge_id,
            )
            .order_by(ChallengeAttempt.created_at.desc(), ChallengeAttempt.id.desc())
            .limit(limit)
            .offset(offset)
        )

    @staticmethod
    def _map_attempt_row(row) -> AdminLogEntry:
        if row.is_correct:
            event_type = "challenge_submission.correct"
            severity = "info"
            message = "Correct challenge submission recorded."
        else:
            event_type = "challenge_submission.incorrect"
            severity = "warning"
            message = "Incorrect challenge submission recorded."

        return AdminLogEntry(
            id=row.id,
            event_type=event_type,
            severity=severity,
            message=message,
            created_at=row.created_at,
            user_id=row.user_id,
            challenge_id=row.challenge_id,
        )
