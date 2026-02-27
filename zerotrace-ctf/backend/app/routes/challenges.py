from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.controllers import challenge_controller
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.dependencies.rbac import require_admin
from app.models.user import User
from app.schemas.challenge import (
    ChallengeActionMessageResponse,
    ChallengeCreateResponse,
    ChallengeDetailResponse,
    ChallengeSummaryResponse,
    CreateChallengeRequest,
    SetFlagRequest,
    SubmitFlagRequest,
    SubmitFlagResponse,
)


router = APIRouter(tags=["challenges"])


@router.post("/admin/challenges", response_model=ChallengeCreateResponse)
def create_admin_challenge(
    payload: CreateChallengeRequest,
    session: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> ChallengeCreateResponse:
    return challenge_controller.create_challenge(session, payload)


@router.post("/admin/challenges/{challenge_id}/flag", response_model=ChallengeActionMessageResponse)
def set_admin_challenge_flag(
    challenge_id: UUID,
    payload: SetFlagRequest,
    session: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> ChallengeActionMessageResponse:
    return challenge_controller.set_flag(
        session=session,
        challenge_id=challenge_id,
        plaintext_flag=payload.flag,
    )


@router.post("/admin/challenges/{challenge_id}/publish", response_model=ChallengeActionMessageResponse)
def publish_admin_challenge(
    challenge_id: UUID,
    session: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> ChallengeActionMessageResponse:
    return challenge_controller.publish_challenge(session=session, challenge_id=challenge_id)


@router.post("/admin/challenges/{challenge_id}/unpublish", response_model=ChallengeActionMessageResponse)
def unpublish_admin_challenge(
    challenge_id: UUID,
    session: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> ChallengeActionMessageResponse:
    return challenge_controller.unpublish_challenge(session=session, challenge_id=challenge_id)


@router.get("/tracks/{track_slug}/challenges", response_model=list[ChallengeSummaryResponse])
def list_track_challenges(
    track_slug: str,
    session: Session = Depends(get_db),
    _: User = Depends(get_current_user),
) -> list[ChallengeSummaryResponse]:
    return challenge_controller.list_track_challenges(session=session, track_slug=track_slug)


@router.get("/challenges/{slug}", response_model=ChallengeDetailResponse)
def get_public_challenge(
    slug: str,
    session: Session = Depends(get_db),
    _: User = Depends(get_current_user),
) -> ChallengeDetailResponse:
    return challenge_controller.get_public_challenge(session=session, slug=slug)


@router.post("/challenges/{slug}/submit", response_model=SubmitFlagResponse)
def submit_challenge_flag(
    slug: str,
    payload: SubmitFlagRequest,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> SubmitFlagResponse:
    return challenge_controller.submit_flag(
        session=session,
        current_user=current_user,
        slug=slug,
        submitted_flag=payload.flag,
    )
