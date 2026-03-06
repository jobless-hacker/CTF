from __future__ import annotations

from app.core.settings import Settings


def test_cors_allowed_origins_normalizes_full_frontend_urls() -> None:
    settings = Settings(
        DATABASE_URL="sqlite+pysqlite:///:memory:",
        SECRET_KEY="test-secret-key-for-settings-spec-000000000000",
        CORS_ALLOWED_ORIGINS=(
            "https://jobless-hacker.github.io/CTF/#/login,"
            "http://localhost:5173/auth/login,"
            "https://jobless-hacker.github.io"
        ),
    )

    assert settings.cors_allowed_origins == [
        "https://jobless-hacker.github.io",
        "http://localhost:5173",
    ]
