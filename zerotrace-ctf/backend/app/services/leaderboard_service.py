from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from time import perf_counter
from typing import List
from uuid import UUID

from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session

from app.models.challenge import Challenge
from app.models.challenge_solve import ChallengeSolve
from app.models.user import User
from app.observability.metrics import metrics


@dataclass(frozen=True, slots=True)
class LeaderboardEntry:
    user_id: UUID
    total_xp: int
    first_solve_at: datetime
    rank: int


class LeaderboardService:
    MAX_LIMIT = 500

    def get_global_leaderboard(self, session: Session, limit: int, offset: int) -> List[LeaderboardEntry]:
        started = perf_counter()
        validated_limit, validated_offset = self._validate_pagination(limit, offset)
        query = self._build_ranked_query(
            self._build_global_user_scores_cte(),
            validated_limit,
            validated_offset,
        )
        entries = self._map_rows(session.execute(query).all())
        latency_ms = (perf_counter() - started) * 1000
        metrics.increment("zerotrace_leaderboard_queries_total", labels={"type": "global"})
        metrics.observe("zerotrace_leaderboard_query_latency_ms", latency_ms, labels={"type": "global"})
        metrics.observe("zerotrace_leaderboard_rows_returned", len(entries), labels={"type": "global"})
        return entries

    def get_track_leaderboard(
        self,
        session: Session,
        track_id: UUID,
        limit: int,
        offset: int,
    ) -> List[LeaderboardEntry]:
        started = perf_counter()
        validated_limit, validated_offset = self._validate_pagination(limit, offset)
        query = self._build_ranked_query(
            self._build_track_user_scores_cte(track_id),
            validated_limit,
            validated_offset,
        )
        entries = self._map_rows(session.execute(query).all())
        latency_ms = (perf_counter() - started) * 1000
        metrics.increment("zerotrace_leaderboard_queries_total", labels={"type": "track"})
        metrics.observe("zerotrace_leaderboard_query_latency_ms", latency_ms, labels={"type": "track"})
        metrics.observe("zerotrace_leaderboard_rows_returned", len(entries), labels={"type": "track"})
        return entries

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
    def _build_global_user_scores_cte():
        return (
            select(
                ChallengeSolve.user_id.label("user_id"),
                func.sum(ChallengeSolve.points_awarded).label("total_xp"),
                func.min(ChallengeSolve.created_at).label("first_solve_at"),
            )
            .join(User, User.id == ChallengeSolve.user_id)
            .where(User.is_active.is_(True))
            .group_by(ChallengeSolve.user_id)
            .cte("user_scores")
        )

    @staticmethod
    def _build_track_user_scores_cte(track_id: UUID):
        return (
            select(
                ChallengeSolve.user_id.label("user_id"),
                func.sum(ChallengeSolve.points_awarded).label("total_xp"),
                func.min(ChallengeSolve.created_at).label("first_solve_at"),
            )
            .join(Challenge, Challenge.id == ChallengeSolve.challenge_id)
            .join(User, User.id == ChallengeSolve.user_id)
            .where(
                User.is_active.is_(True),
                Challenge.track_id == track_id,
            )
            .group_by(ChallengeSolve.user_id)
            .cte("user_scores")
        )

    @staticmethod
    def _build_ranked_query(user_scores_cte, limit: int, offset: int) -> Select:
        order_by = (
            user_scores_cte.c.total_xp.desc(),
            user_scores_cte.c.first_solve_at.asc(),
            user_scores_cte.c.user_id.asc(),
        )
        return (
            select(
                user_scores_cte.c.user_id,
                user_scores_cte.c.total_xp,
                user_scores_cte.c.first_solve_at,
                func.rank().over(order_by=order_by).label("rank"),
            )
            .order_by(*order_by)
            .limit(limit)
            .offset(offset)
        )

    @staticmethod
    def _map_rows(rows) -> List[LeaderboardEntry]:
        return [
            LeaderboardEntry(
                user_id=row.user_id,
                total_xp=int(row.total_xp),
                first_solve_at=row.first_solve_at,
                rank=int(row.rank),
            )
            for row in rows
        ]
