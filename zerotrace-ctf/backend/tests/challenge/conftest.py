from __future__ import annotations

from collections.abc import Callable, Generator
from pathlib import Path
import sys
from uuid import uuid4

import pytest
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

BACKEND_ROOT = Path(__file__).resolve().parents[2]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.models import Base
from app.models.challenge import Challenge, ChallengeDifficulty
from app.models.track import Track
from app.models.user import User
from app.core.settings import get_settings
from app.services.challenge_service import ChallengeService


@pytest.fixture(scope="session")
def test_engine() -> Generator[Engine, None, None]:
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        future=True,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    yield engine
    Base.metadata.drop_all(engine)
    engine.dispose()


@pytest.fixture(autouse=True)
def settings_override(monkeypatch: pytest.MonkeyPatch) -> Generator[None, None, None]:
    monkeypatch.setenv("ENVIRONMENT", "test")
    monkeypatch.setenv("OBSERVABILITY_ENABLED", "false")
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.fixture
def session(test_engine: Engine) -> Generator[Session, None, None]:
    connection = test_engine.connect()
    outer_transaction = connection.begin()
    db_session = Session(
        bind=connection,
        expire_on_commit=False,
        autoflush=False,
        join_transaction_mode="create_savepoint",
    )
    try:
        yield db_session
    finally:
        db_session.close()
        outer_transaction.rollback()
        connection.close()


@pytest.fixture
def challenge_service() -> ChallengeService:
    return ChallengeService()


@pytest.fixture
def seed_track(session: Session) -> Track:
    track = Track(
        name="Linux",
        slug="linux",
        description="Linux fundamentals and system exploitation",
        is_active=True,
    )
    session.add(track)
    session.flush()
    return track


@pytest.fixture
def seed_user(session: Session) -> User:
    user = User(
        email=f"user-{uuid4()}@example.com",
        password_hash="placeholder-hash",
        is_active=True,
    )
    session.add(user)
    session.flush()
    return user


@pytest.fixture
def create_basic_challenge(
    session: Session,
    challenge_service: ChallengeService,
    seed_track: Track,
) -> Callable[..., Challenge]:
    def _create_basic_challenge(
        *,
        title: str = "Find the Hidden File",
        slug: str = "find-the-hidden-file",
        description: str = "Investigate the provided system artifact.",
        difficulty: ChallengeDifficulty | str = ChallengeDifficulty.EASY,
        points: int = 100,
        with_flag: bool = False,
        flag_value: str = "ZTCTF{test-flag}",
        published: bool = False,
    ) -> Challenge:
        challenge = challenge_service.create_challenge(
            session=session,
            track_id=seed_track.id,
            title=title,
            slug=slug,
            description=description,
            difficulty=difficulty,
            points=points,
        )
        session.flush()

        if with_flag:
            challenge_service.set_flag(session, challenge, flag_value)
            session.flush()

        if published:
            if not with_flag:
                challenge_service.set_flag(session, challenge, flag_value)
                session.flush()
            challenge_service.publish_challenge(session, challenge)
            session.flush()

        return challenge

    return _create_basic_challenge
