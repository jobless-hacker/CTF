from __future__ import annotations

from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.challenge import Challenge
from app.models.user import User
from app.schemas.challenge import (
    ChallengeActionMessageResponse,
    ChallengeLabCommandRequest,
    ChallengeLabCommandResponse,
    ChallengeCreateResponse,
    ChallengeDetailResponse,
    ChallengeSummaryResponse,
    CreateChallengeRequest,
    SubmitFlagResponse,
)
from app.services.challenge_exceptions import (
    ChallengeAlreadyHasFlagError,
    ChallengeAlreadyPublishedError,
    ChallengeNotFoundError,
    ChallengeNotPublishedError,
    ChallengeRateLimitedError,
    ChallengeServiceError,
    FlagNotSetError,
    InvalidChallengeConfigurationError,
    InvalidFlagSubmissionError,
    TrackNotFoundError,
)
from app.services.challenge_service import ChallengeService
from app.services.challenge_lab_service import ChallengeLabService, ChallengeLabUnavailableError


_challenge_service = ChallengeService()
_challenge_lab_service = ChallengeLabService()


def create_challenge(session: Session, payload: CreateChallengeRequest) -> ChallengeCreateResponse:
    try:
        challenge = _challenge_service.create_challenge(
            session=session,
            track_id=payload.track_id,
            title=payload.title,
            slug=payload.slug,
            description=payload.description,
            difficulty=payload.difficulty,
            points=payload.points,
        )
        session.flush()
        session.commit()
    except TrackNotFoundError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Track not found.",
        ) from None
    except (InvalidChallengeConfigurationError, IntegrityError):
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Challenge creation failed.",
        ) from None
    except ChallengeServiceError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Challenge creation failed.",
        ) from None

    return ChallengeCreateResponse(
        id=challenge.id,
        slug=challenge.slug,
        is_published=challenge.is_published,
    )


def set_flag(
    session: Session,
    challenge_id: UUID,
    plaintext_flag: str,
) -> ChallengeActionMessageResponse:
    try:
        challenge = _challenge_service.get_challenge_by_id(session, challenge_id)
        _challenge_service.set_flag(session, challenge, plaintext_flag)
        session.commit()
    except ChallengeNotFoundError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge not found.",
        ) from None
    except (ChallengeAlreadyHasFlagError, InvalidFlagSubmissionError, IntegrityError):
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Flag update failed.",
        ) from None
    except ChallengeServiceError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Flag update failed.",
        ) from None

    return ChallengeActionMessageResponse(message="Flag set successfully")


def publish_challenge(session: Session, challenge_id: UUID) -> ChallengeActionMessageResponse:
    try:
        challenge = _challenge_service.get_challenge_by_id(session, challenge_id)
        _challenge_service.publish_challenge(session, challenge)
        session.commit()
    except ChallengeNotFoundError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge not found.",
        ) from None
    except (FlagNotSetError, ChallengeAlreadyPublishedError):
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Challenge publish failed.",
        ) from None
    except ChallengeServiceError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Challenge publish failed.",
        ) from None

    return ChallengeActionMessageResponse(message="Challenge published")


def unpublish_challenge(session: Session, challenge_id: UUID) -> ChallengeActionMessageResponse:
    try:
        challenge = _challenge_service.get_challenge_by_id(session, challenge_id)
        _challenge_service.unpublish_challenge(session, challenge)
        session.commit()
    except ChallengeNotFoundError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge not found.",
        ) from None
    except ChallengeServiceError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Challenge unpublish failed.",
        ) from None

    return ChallengeActionMessageResponse(message="Challenge unpublished")


def list_track_challenges(session: Session, track_slug: str) -> list[ChallengeSummaryResponse]:
    try:
        challenges = _challenge_service.list_public_challenges_by_track(session, track_slug)
    except TrackNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Track not found.",
        ) from None
    except ChallengeServiceError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Challenge listing failed.",
        ) from None

    return [
        ChallengeSummaryResponse(
            id=challenge.id,
            track_id=challenge.track_id,
            title=challenge.title,
            slug=challenge.slug,
            difficulty=challenge.difficulty,
            points=challenge.points,
            is_published=challenge.is_published,
        )
        for challenge in challenges
    ]


def get_public_challenge(session: Session, slug: str) -> ChallengeDetailResponse:
    try:
        public_challenge = _challenge_service.get_public_challenge(session, slug)
    except ChallengeNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge not found.",
        ) from None
    except ChallengeNotPublishedError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Challenge unavailable.",
        ) from None
    except ChallengeServiceError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Challenge retrieval failed.",
        ) from None

    return ChallengeDetailResponse(
        id=public_challenge.id,
        track_id=public_challenge.track_id,
        title=public_challenge.title,
        slug=public_challenge.slug,
        description=public_challenge.description,
        difficulty=public_challenge.difficulty,
        points=public_challenge.points,
        is_published=public_challenge.is_published,
        created_at=public_challenge.created_at,
        updated_at=public_challenge.updated_at,
    )


def submit_flag(
    session: Session,
    current_user: User,
    slug: str,
    submitted_flag: str,
) -> SubmitFlagResponse:
    try:
        result = _challenge_service.submit_flag(
            session=session,
            user=current_user,
            challenge_slug=slug,
            submitted_flag=submitted_flag,
        )
        session.commit()
    except ChallengeNotFoundError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge not found.",
        ) from None
    except ChallengeNotPublishedError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Challenge unavailable.",
        ) from None
    except FlagNotSetError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Challenge unavailable.",
        ) from None
    except ChallengeRateLimitedError as exc:
        try:
            session.commit()
        except Exception:
            session.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Flag submission failed.",
            ) from None
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many submissions. Try again later.",
            headers={"Retry-After": str(exc.retry_after_seconds)},
        ) from None
    except InvalidFlagSubmissionError:
        try:
            session.commit()
        except Exception:
            session.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Flag submission failed.",
            ) from None
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid flag submission.",
        ) from None
    except ChallengeServiceError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Flag submission failed.",
        ) from None

    return SubmitFlagResponse(
        correct=result["correct"],
        xp_awarded=result["xp_awarded"],
        first_blood=result["first_blood"],
    )


def execute_lab_command(
    session: Session,
    current_user: User,
    slug: str,
    payload: ChallengeLabCommandRequest,
) -> ChallengeLabCommandResponse:
    _ = current_user
    try:
        _challenge_service.get_public_challenge(session, slug)
    except ChallengeNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge not found.",
        ) from None
    except ChallengeNotPublishedError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Challenge unavailable.",
        ) from None
    except ChallengeServiceError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Challenge retrieval failed.",
        ) from None

    try:
        result = _challenge_lab_service.execute_command(
            challenge_slug=slug,
            command=payload.command,
            cwd=payload.cwd,
        )
    except ChallengeLabUnavailableError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lab unavailable for this challenge.",
        ) from None

    return ChallengeLabCommandResponse(
        output=result.output,
        cwd=result.cwd,
        exit_code=result.exit_code,
    )
