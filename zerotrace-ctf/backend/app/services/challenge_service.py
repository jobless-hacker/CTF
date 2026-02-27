from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from time import perf_counter
from typing import TypedDict
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.settings import get_settings
from app.models.challenge import Challenge, ChallengeDifficulty
from app.models.track import Track
from app.models.user import User
from app.observability.logger import log_event
from app.observability.metrics import metrics
from app.repositories import challenge_repository
from app.services.challenge_exceptions import (
    ChallengeAlreadyHasFlagError,
    ChallengeAlreadyPublishedError,
    ChallengeNotFoundError,
    ChallengeNotPublishedError,
    ChallengeRateLimitedError,
    FlagNotSetError,
    InvalidChallengeConfigurationError,
    InvalidFlagSubmissionError,
    TrackNotFoundError,
)
from app.services.flag_hashing import hash_flag, verify_flag
from app.services.rate_limiter import DbSubmissionRateLimiter, SubmissionRateLimiter


class FlagSubmissionResult(TypedDict):
    correct: bool
    xp_awarded: int
    first_blood: bool


@dataclass(frozen=True, slots=True)
class PublicChallengeData:
    id: UUID
    track_id: UUID
    title: str
    slug: str
    description: str
    difficulty: str
    points: int
    is_published: bool
    created_at: datetime
    updated_at: datetime


class ChallengeService:
    def __init__(self, rate_limiter: SubmissionRateLimiter | None = None) -> None:
        self._rate_limiter = rate_limiter or DbSubmissionRateLimiter()

    def create_challenge(
        self,
        session: Session,
        track_id: UUID,
        title: str,
        slug: str,
        description: str,
        difficulty: ChallengeDifficulty | str,
        points: int,
    ) -> Challenge:
        track = session.execute(select(Track.id).where(Track.id == track_id)).scalar_one_or_none()
        if track is None:
            raise TrackNotFoundError("Track not found.")

        normalized_title = title.strip()
        normalized_slug = self._normalize_slug(slug)
        normalized_description = description.strip()
        if not normalized_title:
            raise InvalidChallengeConfigurationError("Challenge title is required.")
        if not normalized_description:
            raise InvalidChallengeConfigurationError("Challenge description is required.")
        if points <= 0:
            raise InvalidChallengeConfigurationError("Challenge points must be greater than zero.")

        parsed_difficulty = self._parse_difficulty(difficulty)

        return challenge_repository.create_challenge(
            session=session,
            track_id=track_id,
            title=normalized_title,
            slug=normalized_slug,
            description=normalized_description,
            difficulty=parsed_difficulty,
            points=points,
        )

    def set_flag(
        self,
        session: Session,
        challenge: Challenge,
        plaintext_flag: str,
    ) -> None:
        if challenge.flag is not None:
            raise ChallengeAlreadyHasFlagError("Challenge flag is already set.")

        normalized_flag = self._normalize_flag(plaintext_flag)
        flag_hash = hash_flag(normalized_flag)
        challenge_repository.set_flag_hash(session, challenge=challenge, flag_hash=flag_hash)
        return None

    def publish_challenge(self, session: Session, challenge: Challenge) -> Challenge:
        _ = session
        if challenge.is_published:
            raise ChallengeAlreadyPublishedError("Challenge is already published.")
        if challenge.flag is None or not challenge.flag.flag_hash:
            raise FlagNotSetError("Challenge flag is not set.")

        challenge.is_published = True
        return challenge

    def unpublish_challenge(self, session: Session, challenge: Challenge) -> Challenge:
        _ = session
        challenge.is_published = False
        return challenge

    def submit_flag(
        self,
        session: Session,
        user: User,
        challenge_slug: str,
        submitted_flag: str,
    ) -> FlagSubmissionResult:
        started = perf_counter()
        metrics.increment(
            "zerotrace_submission_requests_total",
            labels={"endpoint": "challenge_submit"},
        )
        lookup_slug = challenge_slug.strip()
        challenge = challenge_repository.get_by_slug(session, lookup_slug)
        if challenge is None:
            log_event(
                "submission_outcome",
                outcome="challenge_not_found",
                user_id=user.id,
                challenge_slug=lookup_slug,
                latency_ms=self._elapsed_millis(started),
            )
            raise ChallengeNotFoundError("Challenge not found.")
        if not challenge.is_published:
            log_event(
                "submission_outcome",
                outcome="challenge_not_published",
                user_id=user.id,
                challenge_id=challenge.id,
                track_id=challenge.track_id,
                latency_ms=self._elapsed_millis(started),
            )
            raise ChallengeNotPublishedError("Challenge is not published.")
        if challenge.flag is None or not challenge.flag.flag_hash:
            log_event(
                "submission_outcome",
                outcome="challenge_flag_not_set",
                user_id=user.id,
                challenge_id=challenge.id,
                track_id=challenge.track_id,
                latency_ms=self._elapsed_millis(started),
            )
            raise FlagNotSetError("Challenge flag is not set.")

        log_event(
            "submission_attempt",
            outcome="received",
            user_id=user.id,
            challenge_id=challenge.id,
            track_id=challenge.track_id,
            challenge_slug=challenge.slug,
            latency_ms=self._elapsed_millis(started),
        )

        rate_limit_decision = self._rate_limiter.check_and_consume(
            session=session,
            user_id=user.id,
            challenge_id=challenge.id,
            now=datetime.now(timezone.utc),
        )
        if not rate_limit_decision.allowed:
            retry_after_seconds = rate_limit_decision.retry_after_seconds or 1
            metrics.increment(
                "zerotrace_submission_rate_limited_total",
                labels={"endpoint": "challenge_submit"},
            )
            log_event(
                "submission_blocked",
                outcome="rate_limited",
                user_id=user.id,
                challenge_id=challenge.id,
                track_id=challenge.track_id,
                retry_after_seconds=retry_after_seconds,
                latency_ms=self._elapsed_millis(started),
            )
            log_event(
                "submission_outcome",
                outcome="rate_limited",
                user_id=user.id,
                challenge_id=challenge.id,
                track_id=challenge.track_id,
                retry_after_seconds=retry_after_seconds,
                latency_ms=self._elapsed_millis(started),
            )
            raise ChallengeRateLimitedError(retry_after_seconds=retry_after_seconds)

        normalized_flag = submitted_flag.strip()
        if not normalized_flag:
            challenge_repository.record_attempt(
                session,
                user=user,
                challenge=challenge,
                submitted_flag=submitted_flag,
                is_correct=False,
            )
            metrics.increment(
                "zerotrace_submission_incorrect_total",
                labels={"track_slug": challenge.track.slug, "difficulty": challenge.difficulty.value},
            )
            log_event(
                "submission_outcome",
                outcome="invalid_flag_submission",
                user_id=user.id,
                challenge_id=challenge.id,
                track_id=challenge.track_id,
                latency_ms=self._elapsed_millis(started),
            )
            raise InvalidFlagSubmissionError("Submitted flag is invalid.")

        is_correct = verify_flag(normalized_flag, challenge.flag.flag_hash)
        challenge_repository.record_attempt(
            session,
            user=user,
            challenge=challenge,
            submitted_flag=submitted_flag,
            is_correct=is_correct,
        )

        if not is_correct:
            metrics.increment(
                "zerotrace_submission_incorrect_total",
                labels={"track_slug": challenge.track.slug, "difficulty": challenge.difficulty.value},
            )
            log_event(
                "submission_outcome",
                outcome="incorrect",
                user_id=user.id,
                challenge_id=challenge.id,
                track_id=challenge.track_id,
                latency_ms=self._elapsed_millis(started),
            )
            return {
                "correct": False,
                "xp_awarded": 0,
                "first_blood": False,
            }

        base_points = challenge.points
        if base_points <= 0:
            raise InvalidChallengeConfigurationError("Challenge points configuration is invalid.")

        settings = get_settings()
        bonus_points = self._calculate_first_blood_bonus(base_points)

        if settings.XP_FIRST_BLOOD_ENABLED and challenge_repository.get_first_blood_solve_by_challenge(
            session, challenge.id
        ) is None:
            first_blood_awarded = self._try_insert_challenge_solve(
                session=session,
                user=user,
                challenge=challenge,
                points_awarded=base_points + bonus_points,
                is_first_blood=True,
            )
            if first_blood_awarded:
                metrics.increment(
                    "zerotrace_submission_correct_total",
                    labels={"track_slug": challenge.track.slug, "difficulty": challenge.difficulty.value},
                )
                metrics.increment("zerotrace_xp_awarded_total", labels={"source": "first_blood"})
                metrics.increment(
                    "zerotrace_xp_points_awarded_sum",
                    value=base_points + bonus_points,
                    labels={"source": "first_blood"},
                )
                metrics.increment(
                    "zerotrace_first_blood_awarded_total",
                    labels={"track_slug": challenge.track.slug, "difficulty": challenge.difficulty.value},
                )
                log_event(
                    "xp_awarded",
                    outcome="awarded",
                    user_id=user.id,
                    challenge_id=challenge.id,
                    track_id=challenge.track_id,
                    points_awarded=base_points + bonus_points,
                    first_blood=True,
                    latency_ms=self._elapsed_millis(started),
                )
                log_event(
                    "first_blood_awarded",
                    outcome="awarded",
                    user_id=user.id,
                    challenge_id=challenge.id,
                    track_id=challenge.track_id,
                    points_awarded=base_points + bonus_points,
                    latency_ms=self._elapsed_millis(started),
                )
                log_event(
                    "submission_outcome",
                    outcome="correct",
                    user_id=user.id,
                    challenge_id=challenge.id,
                    track_id=challenge.track_id,
                    xp_awarded=base_points + bonus_points,
                    first_blood=True,
                    latency_ms=self._elapsed_millis(started),
                )
                return {
                    "correct": True,
                    "xp_awarded": base_points + bonus_points,
                    "first_blood": True,
                }

        solve_awarded = self._try_insert_challenge_solve(
            session=session,
            user=user,
            challenge=challenge,
            points_awarded=base_points,
            is_first_blood=False,
        )
        if solve_awarded:
            metrics.increment(
                "zerotrace_submission_correct_total",
                labels={"track_slug": challenge.track.slug, "difficulty": challenge.difficulty.value},
            )
            metrics.increment("zerotrace_xp_awarded_total", labels={"source": "base"})
            metrics.increment(
                "zerotrace_xp_points_awarded_sum",
                value=base_points,
                labels={"source": "base"},
            )
            log_event(
                "xp_awarded",
                outcome="awarded",
                user_id=user.id,
                challenge_id=challenge.id,
                track_id=challenge.track_id,
                points_awarded=base_points,
                first_blood=False,
                latency_ms=self._elapsed_millis(started),
            )
            log_event(
                "submission_outcome",
                outcome="correct",
                user_id=user.id,
                challenge_id=challenge.id,
                track_id=challenge.track_id,
                xp_awarded=base_points,
                first_blood=False,
                latency_ms=self._elapsed_millis(started),
            )
            return {
                "correct": True,
                "xp_awarded": base_points,
                "first_blood": False,
            }

        log_event(
            "submission_outcome",
            outcome="already_solved",
            user_id=user.id,
            challenge_id=challenge.id,
            track_id=challenge.track_id,
            xp_awarded=0,
            first_blood=False,
            latency_ms=self._elapsed_millis(started),
        )
        return {
            "correct": True,
            "xp_awarded": 0,
            "first_blood": False,
        }

    def get_public_challenge(self, session: Session, slug: str) -> PublicChallengeData:
        challenge = challenge_repository.get_by_slug(session, slug.strip())
        if challenge is None:
            raise ChallengeNotFoundError("Challenge not found.")
        if not challenge.is_published:
            raise ChallengeNotPublishedError("Challenge is not published.")

        return PublicChallengeData(
            id=challenge.id,
            track_id=challenge.track_id,
            title=challenge.title,
            slug=challenge.slug,
            description=challenge.description,
            difficulty=challenge.difficulty.value,
            points=challenge.points,
            is_published=challenge.is_published,
            created_at=challenge.created_at,
            updated_at=challenge.updated_at,
        )

    def list_public_challenges_by_track(self, session: Session, track_slug: str) -> list[Challenge]:
        normalized_track_slug = track_slug.strip()
        track = session.execute(select(Track.id).where(Track.slug == normalized_track_slug)).scalar_one_or_none()
        if track is None:
            raise TrackNotFoundError("Track not found.")

        return challenge_repository.list_published_by_track(session, normalized_track_slug)

    def get_challenge_by_id(self, session: Session, challenge_id: UUID) -> Challenge:
        challenge = challenge_repository.get_by_id(session, challenge_id)
        if challenge is None:
            raise ChallengeNotFoundError("Challenge not found.")
        return challenge

    @staticmethod
    def _normalize_slug(slug: str) -> str:
        normalized = slug.strip()
        if not normalized:
            raise InvalidChallengeConfigurationError("Challenge slug is required.")
        if normalized != normalized.lower():
            raise InvalidChallengeConfigurationError("Challenge slug must be lowercase.")
        if len(normalized) > 100:
            raise InvalidChallengeConfigurationError("Challenge slug is too long.")
        return normalized

    @staticmethod
    def _normalize_flag(flag: str) -> str:
        normalized = flag.strip()
        if not normalized:
            raise InvalidFlagSubmissionError("Flag must not be empty.")
        return normalized

    @staticmethod
    def _parse_difficulty(difficulty: ChallengeDifficulty | str) -> ChallengeDifficulty:
        if isinstance(difficulty, ChallengeDifficulty):
            return difficulty

        try:
            return ChallengeDifficulty(difficulty)
        except ValueError:
            raise InvalidChallengeConfigurationError("Invalid challenge difficulty.") from None

    @staticmethod
    def _calculate_first_blood_bonus(base_points: int) -> int:
        settings = get_settings()
        if not settings.XP_FIRST_BLOOD_ENABLED:
            return 0

        bonus_value = settings.XP_FIRST_BLOOD_BONUS_VALUE
        if bonus_value < 0:
            raise InvalidChallengeConfigurationError("First-blood bonus configuration is invalid.")

        if settings.XP_FIRST_BLOOD_BONUS_MODE == "fixed":
            return bonus_value
        if settings.XP_FIRST_BLOOD_BONUS_MODE == "percent":
            return (base_points * bonus_value) // 100

        raise InvalidChallengeConfigurationError("First-blood bonus configuration is invalid.")

    @staticmethod
    def _try_insert_challenge_solve(
        session: Session,
        user: User,
        challenge: Challenge,
        points_awarded: int,
        is_first_blood: bool,
    ) -> bool:
        if points_awarded <= 0:
            raise InvalidChallengeConfigurationError("Awarded points must be greater than zero.")

        try:
            with session.begin_nested():
                challenge_repository.create_challenge_solve(
                    session=session,
                    user=user,
                    challenge=challenge,
                    points_awarded=points_awarded,
                    is_first_blood=is_first_blood,
                )
                session.flush()
        except IntegrityError:
            return False

        return True

    @staticmethod
    def _elapsed_millis(started: float) -> float:
        return round((perf_counter() - started) * 1000, 3)
