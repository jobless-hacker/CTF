from __future__ import annotations

import pytest
from sqlalchemy.orm import Session

from app.repositories import challenge_repository
from app.services.challenge_exceptions import ChallengeNotFoundError, ChallengeNotPublishedError
from app.services.challenge_service import ChallengeService, PublicChallengeData


def test_get_public_challenge_success(
    session: Session,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(
        slug="public-challenge",
        published=True,
        flag_value="ZTCTF{public-view}",
    )

    public_data = challenge_service.get_public_challenge(session, "public-challenge")

    assert isinstance(public_data, PublicChallengeData)
    assert public_data.id == challenge.id
    assert public_data.slug == "public-challenge"
    assert public_data.is_published is True
    assert public_data.difficulty == "easy"
    assert not hasattr(public_data, "flag_hash")


def test_get_public_challenge_unpublished_raises(
    session: Session,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(slug="hidden-challenge", with_flag=True)

    with pytest.raises(ChallengeNotPublishedError):
        challenge_service.get_public_challenge(session, challenge.slug)


def test_get_public_challenge_not_found(
    session: Session,
    challenge_service: ChallengeService,
) -> None:
    with pytest.raises(ChallengeNotFoundError):
        challenge_service.get_public_challenge(session, "does-not-exist")


def test_list_published_by_track_returns_only_published(
    session: Session,
    create_basic_challenge,
) -> None:
    create_basic_challenge(slug="published-one", published=True, flag_value="ZTCTF{one}")
    create_basic_challenge(slug="published-two", published=True, flag_value="ZTCTF{two}")
    create_basic_challenge(slug="draft-one", with_flag=True, published=False)

    challenges = challenge_repository.list_published_by_track(session, "linux")
    slugs = [challenge.slug for challenge in challenges]

    assert sorted(slugs) == ["published-one", "published-two"]
