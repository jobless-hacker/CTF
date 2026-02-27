from __future__ import annotations

from collections.abc import Generator
from pathlib import Path
import sys

import pytest
from fastapi import APIRouter, Depends
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

BACKEND_ROOT = Path(__file__).resolve().parents[2]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.settings import get_settings
from app.models import Base
from app.models.role import Role


@pytest.fixture(autouse=True)
def settings_override(monkeypatch: pytest.MonkeyPatch) -> Generator[None, None, None]:
    monkeypatch.setenv("DATABASE_URL", "sqlite+pysqlite:///:memory:")
    monkeypatch.setenv(
        "SECRET_KEY",
        "integration-test-secret-key-0000000000000000000000000000",
    )
    monkeypatch.setenv("ALGORITHM", "HS256")
    monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    monkeypatch.setenv("ENVIRONMENT", "test")
    monkeypatch.setenv("OBSERVABILITY_ENABLED", "false")
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


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


@pytest.fixture
def test_session(test_engine: Engine) -> Generator[Session, None, None]:
    connection = test_engine.connect()
    outer_transaction = connection.begin()
    session = Session(
        bind=connection,
        expire_on_commit=False,
        autoflush=False,
        join_transaction_mode="create_savepoint",
    )

    try:
        yield session
    finally:
        session.close()
        outer_transaction.rollback()
        connection.close()


@pytest.fixture
def override_get_db(test_session: Session):
    def _override_get_db():
        yield test_session

    return _override_get_db


@pytest.fixture
def seed_roles(test_session: Session) -> dict[str, Role]:
    admin = test_session.execute(select(Role).where(Role.name == "admin")).scalar_one_or_none()
    if admin is None:
        admin = Role(name="admin", description="Administrator with elevated privileges")
        test_session.add(admin)

    player = test_session.execute(select(Role).where(Role.name == "player")).scalar_one_or_none()
    if player is None:
        player = Role(name="player", description="Default platform user role")
        test_session.add(player)

    test_session.flush()
    return {"admin": admin, "player": player}


def _ensure_test_admin_ping_route(app) -> None:
    if any(getattr(route, "path", None) == "/admin/ping" for route in app.routes):
        return

    from app.dependencies.rbac import require_admin
    from app.models.user import User

    router = APIRouter()

    @router.get("/admin/ping")
    def admin_ping(current_user: User = Depends(require_admin)) -> dict[str, str]:
        _ = current_user
        return {"status": "ok"}

    app.include_router(router, tags=["test-admin"])


@pytest.fixture
def client(
    settings_override: None,
    override_get_db,
) -> Generator[TestClient, None, None]:
    from app.dependencies.db import get_db
    from main import app

    _ensure_test_admin_ping_route(app)
    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
