from __future__ import annotations

from collections.abc import Generator
from pathlib import Path
import sys

import pytest
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

BACKEND_ROOT = Path(__file__).resolve().parents[2]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.settings import get_settings
from app.models import Base
from app.models.role import Role
from app.services.auth_service import AuthService


@pytest.fixture(autouse=True)
def settings_override(monkeypatch: pytest.MonkeyPatch) -> Generator[None, None, None]:
    monkeypatch.setenv(
        "SECRET_KEY",
        "test-secret-key-for-auth-unit-tests-0000000000000000",
    )
    monkeypatch.setenv("ALGORITHM", "HS256")
    monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    monkeypatch.setenv("ENVIRONMENT", "test")
    monkeypatch.setenv("OBSERVABILITY_ENABLED", "false")
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.fixture(scope="session")
def engine() -> Generator[Engine, None, None]:
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


@pytest.fixture
def session(engine: Engine) -> Generator[Session, None, None]:
    connection = engine.connect()
    transaction = connection.begin()
    db_session = Session(bind=connection, expire_on_commit=False)

    try:
        yield db_session
    finally:
        db_session.close()
        transaction.rollback()
        connection.close()


@pytest.fixture
def seed_roles(session: Session) -> dict[str, Role]:
    player_role = Role(name="player", description="Default player role")
    session.add(player_role)
    session.flush()
    return {"player": player_role}


@pytest.fixture
def auth_service() -> AuthService:
    return AuthService()
