from __future__ import annotations

import pytest
from sqlalchemy.orm import Session

from app.repositories import challenge_repository
from app.services.challenge_exceptions import (
    ChallengeAlreadyHasFlagError,
    ChallengeAlreadyPublishedError,
    FlagNotSetError,
)
from app.services.challenge_service import ChallengeService
from app.services.flag_hashing import hash_flag, verify_flag


def test_set_flag_success(
    session: Session,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge()
    plaintext_flag = "ZTCTF{linux-basics}"

    challenge_service.set_flag(session, challenge, plaintext_flag)
    session.flush()

    loaded = challenge_repository.get_by_id(session, challenge.id)
    assert loaded is not None
    assert loaded.flag is not None
    assert loaded.flag.flag_hash != plaintext_flag
    assert verify_flag(plaintext_flag, loaded.flag.flag_hash) is True
    assert verify_flag("ZTCTF{wrong-flag}", loaded.flag.flag_hash) is False


def test_set_flag_twice_raises(
    session: Session,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(with_flag=True, flag_value="ZTCTF{one-time-flag}")

    with pytest.raises(ChallengeAlreadyHasFlagError):
        challenge_service.set_flag(session, challenge, "ZTCTF{new-flag}")


def test_publish_without_flag_raises(
    session: Session,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge()

    with pytest.raises(FlagNotSetError):
        challenge_service.publish_challenge(session, challenge)


def test_publish_success(
    session: Session,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(with_flag=True, flag_value="ZTCTF{publish-me}")

    returned = challenge_service.publish_challenge(session, challenge)
    session.flush()

    assert returned is challenge
    assert challenge.is_published is True


def test_publish_twice_raises(
    session: Session,
    challenge_service: ChallengeService,
    create_basic_challenge,
) -> None:
    challenge = create_basic_challenge(published=True, flag_value="ZTCTF{already-published}")

    with pytest.raises(ChallengeAlreadyPublishedError):
        challenge_service.publish_challenge(session, challenge)


def test_flag_hash_not_equal_plaintext_and_verify_roundtrip() -> None:
    plaintext_flag = "ZTCTF{hash-roundtrip}"
    hashed_flag = hash_flag(plaintext_flag)

    assert hashed_flag != plaintext_flag
    assert verify_flag(plaintext_flag, hashed_flag) is True
    assert verify_flag("ZTCTF{different}", hashed_flag) is False
