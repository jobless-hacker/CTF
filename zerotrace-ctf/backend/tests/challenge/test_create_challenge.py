from __future__ import annotations

from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.models.challenge import ChallengeDifficulty
from app.repositories import challenge_repository
from app.services.challenge_exceptions import (
    InvalidChallengeConfigurationError,
    TrackNotFoundError,
)
from app.services.challenge_service import ChallengeService


def test_create_challenge_success(
    session: Session,
    seed_track,
    challenge_service: ChallengeService,
) -> None:
    challenge = challenge_service.create_challenge(
        session=session,
        track_id=seed_track.id,
        title="Packet Hunt",
        slug="packet-hunt",
        description="Analyze the capture and recover the indicator.",
        difficulty=ChallengeDifficulty.MEDIUM,
        points=150,
    )
    session.flush()

    assert challenge.id is not None
    assert challenge.track_id == seed_track.id
    assert challenge.title == "Packet Hunt"
    assert challenge.slug == "packet-hunt"
    assert challenge.difficulty == ChallengeDifficulty.MEDIUM
    assert challenge.points == 150
    assert challenge.is_published is False

    loaded = challenge_repository.get_by_slug(session, "packet-hunt")
    assert loaded is not None
    assert loaded.id == challenge.id


def test_create_challenge_invalid_slug_uppercase(
    session: Session,
    seed_track,
    challenge_service: ChallengeService,
) -> None:
    with pytest.raises(InvalidChallengeConfigurationError):
        challenge_service.create_challenge(
            session=session,
            track_id=seed_track.id,
            title="Bad Slug",
            slug="Bad-Slug",
            description="desc",
            difficulty=ChallengeDifficulty.EASY,
            points=50,
        )


def test_create_challenge_invalid_difficulty(
    session: Session,
    seed_track,
    challenge_service: ChallengeService,
) -> None:
    with pytest.raises(InvalidChallengeConfigurationError):
        challenge_service.create_challenge(
            session=session,
            track_id=seed_track.id,
            title="Bad Difficulty",
            slug="bad-difficulty",
            description="desc",
            difficulty="expert",
            points=50,
        )


def test_create_challenge_points_must_be_positive(
    session: Session,
    seed_track,
    challenge_service: ChallengeService,
) -> None:
    with pytest.raises(InvalidChallengeConfigurationError):
        challenge_service.create_challenge(
            session=session,
            track_id=seed_track.id,
            title="Zero Points",
            slug="zero-points",
            description="desc",
            difficulty=ChallengeDifficulty.EASY,
            points=0,
        )


def test_create_challenge_missing_track(
    session: Session,
    challenge_service: ChallengeService,
) -> None:
    with pytest.raises(TrackNotFoundError):
        challenge_service.create_challenge(
            session=session,
            track_id=uuid4(),
            title="Missing Track",
            slug="missing-track",
            description="desc",
            difficulty=ChallengeDifficulty.EASY,
            points=50,
        )
