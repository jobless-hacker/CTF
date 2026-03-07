#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Any
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session, sessionmaker

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.settings import get_settings
from app.models.challenge import Challenge
from app.models.role import Role
from scripts.seed_intro_cybersecurity_track import _load_seed, _seed

SEED_RELATIVE_PATH = Path("config/seeds/foundations-challenge-todo.seed.json")
SEEDS_DIR = BACKEND_ROOT / "config" / "seeds"
TEST_SLUG = "m1-99-modularity-smoke-test"
TEST_SOURCE_REL = Path("modules/m1/m1-99-modularity-smoke-test.json")
TEST_TRACK_SLUG = "foundations"
TEST_FLAG = "CTF{modularity_smoke_test}"


def _read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fp:
        payload = json.load(fp)
    if not isinstance(payload, dict):
        raise ValueError(f"Expected JSON object in: {path}")
    return payload


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fp:
        json.dump(payload, fp, indent=2)
        fp.write("\n")


def _build_test_challenge_payload(title: str, points: int, attachment_url: str) -> dict[str, Any]:
    return {
        "order": 99,
        "slug": TEST_SLUG,
        "title": title,
        "difficulty": "easy",
        "points": points,
        "description": (
            "SOC received a test case for verifying modular challenge lifecycle behavior.\n\n"
            "Validate add, update, and delete-prune flow from modular seed files.\n\n"
            "Flag Format\n"
            "CTF{modularity_smoke_test}"
        ),
        "include_module_context": False,
        "include_submission_footer": False,
        "attachment_url": attachment_url,
        "flag": "REDACTED_USE_PRIVATE_FLAGS_FILE",
        "publish": True,
    }


def _ensure_m1_source_entry(seed_payload: dict[str, Any], source_rel: Path) -> None:
    for module_payload in seed_payload.get("modules", []):
        if str(module_payload.get("code", "")).strip().upper() != "M1":
            continue
        challenges = module_payload.get("challenges", [])
        if not isinstance(challenges, list):
            raise ValueError("M1 challenges must be a list.")
        marker = {"source_file": str(source_rel).replace("\\", "/")}
        if marker not in challenges:
            challenges.append(marker)
        return
    raise ValueError("Module M1 not found in seed payload.")


def _remove_m1_source_entry(seed_payload: dict[str, Any], source_rel: Path) -> None:
    normalized_rel = str(source_rel).replace("\\", "/")
    for module_payload in seed_payload.get("modules", []):
        if str(module_payload.get("code", "")).strip().upper() != "M1":
            continue
        challenges = module_payload.get("challenges", [])
        if not isinstance(challenges, list):
            raise ValueError("M1 challenges must be a list.")
        module_payload["challenges"] = [
            challenge
            for challenge in challenges
            if not (
                isinstance(challenge, dict)
                and str(challenge.get("source_file", "")).replace("\\", "/") == normalized_rel
            )
        ]
        return
    raise ValueError("Module M1 not found in seed payload.")


def _ensure_player_role(session: Session) -> None:
    player_role = session.execute(select(Role).where(Role.name == "player")).scalar_one_or_none()
    if player_role is not None:
        return
    session.add(Role(name="player", description="Default platform user role"))
    session.commit()


def _db_session_factory() -> sessionmaker[Session]:
    settings = get_settings()
    engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True, future=True)
    return sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False, class_=Session)


def _get_challenge_state(session: Session, slug: str) -> Challenge | None:
    return session.execute(select(Challenge).where(Challenge.slug == slug)).scalar_one_or_none()


def _auth_headers(client: TestClient) -> dict[str, str]:
    email = f"modularity-smoke-{uuid4().hex[:8]}@example.com"
    password = "StrongPassword!123"

    register_response = client.post("/auth/register", json={"email": email, "password": password})
    if register_response.status_code != 201:
        raise RuntimeError(f"Auth register failed: {register_response.status_code} {register_response.text}")

    login_response = client.post("/auth/login", json={"email": email, "password": password})
    if login_response.status_code != 200:
        raise RuntimeError(f"Auth login failed: {login_response.status_code} {login_response.text}")

    token = login_response.json().get("access_token")
    if not token:
        raise RuntimeError("Auth token missing in login response.")
    return {"Authorization": f"Bearer {token}"}


def _assert_frontend_feed_contains(client: TestClient, headers: dict[str, str], slug: str, title: str) -> None:
    list_response = client.get(f"/tracks/{TEST_TRACK_SLUG}/challenges", headers=headers)
    if list_response.status_code != 200:
        raise RuntimeError(
            f"Track challenge listing failed: {list_response.status_code} {list_response.text}"
        )
    payload = list_response.json()
    match = next((item for item in payload if item.get("slug") == slug), None)
    if match is None:
        raise AssertionError(f"Expected challenge slug '{slug}' in track listing.")
    if match.get("title") != title:
        raise AssertionError(
            f"Expected title '{title}' for slug '{slug}', got '{match.get('title')}'."
        )


def _assert_frontend_feed_missing(client: TestClient, headers: dict[str, str], slug: str) -> None:
    list_response = client.get(f"/tracks/{TEST_TRACK_SLUG}/challenges", headers=headers)
    if list_response.status_code != 200:
        raise RuntimeError(
            f"Track challenge listing failed: {list_response.status_code} {list_response.text}"
        )
    payload = list_response.json()
    if any(item.get("slug") == slug for item in payload):
        raise AssertionError(f"Challenge slug '{slug}' should not be visible in track listing.")

    detail_response = client.get(f"/challenges/{slug}", headers=headers)
    if detail_response.status_code != 400:
        raise AssertionError(
            f"Expected challenge detail to be unavailable after prune; got {detail_response.status_code}."
        )


def _run_seed_once(
    seed_file: Path,
    *,
    prune_missing: bool,
) -> None:
    payload = _load_seed(seed_file)
    _seed(
        payload=payload,
        update_existing=True,
        overwrite_flags=True,
        allow_publish=True,
        prune_missing=prune_missing,
        dry_run=False,
        flag_overrides={TEST_SLUG: TEST_FLAG},
    )


def main() -> int:
    temp_root = Path(tempfile.mkdtemp(prefix="m1_modularity_smoke_"))
    temp_seed_file = temp_root / "foundations-challenge-todo.seed.json"
    temp_m1_dir = temp_root / "modules" / "m1"

    print("Preparing temporary modular seed workspace...")
    try:
        shutil.copy2(SEEDS_DIR / SEED_RELATIVE_PATH.name, temp_seed_file)
        shutil.copytree(SEEDS_DIR / "modules" / "m1", temp_m1_dir, dirs_exist_ok=True)

        session_local = _db_session_factory()
        with session_local() as session:
            _ensure_player_role(session)

        from main import app

        with TestClient(app) as client:
            headers = _auth_headers(client)

            print("STEP 1/3: ADD test modular challenge and seed...")
            seed_payload = _read_json(temp_seed_file)
            _ensure_m1_source_entry(seed_payload, TEST_SOURCE_REL)
            _write_json(temp_seed_file, seed_payload)

            test_challenge_path = temp_root / TEST_SOURCE_REL
            _write_json(
                test_challenge_path,
                _build_test_challenge_payload(
                    title="M1: CIA Triad - Modularity Smoke Test",
                    points=120,
                    attachment_url="/artifacts/m1/m1-99-modularity-smoke-test-v1.zip",
                ),
            )

            _run_seed_once(temp_seed_file, prune_missing=False)

            with session_local() as session:
                challenge = _get_challenge_state(session, TEST_SLUG)
                if challenge is None:
                    raise AssertionError("ADD failed: challenge row not created.")
                if not challenge.is_published:
                    raise AssertionError("ADD failed: challenge should be published.")
                if challenge.points != 120:
                    raise AssertionError(f"ADD failed: expected points 120, got {challenge.points}.")
            _assert_frontend_feed_contains(
                client,
                headers,
                TEST_SLUG,
                "M1: CIA Triad - Modularity Smoke Test",
            )
            print("PASS: ADD reflected in backend DB and frontend feed API.")

            print("STEP 2/3: UPDATE test modular challenge and re-seed...")
            _write_json(
                test_challenge_path,
                _build_test_challenge_payload(
                    title="M1: CIA Triad - Modularity Smoke Test v2",
                    points=140,
                    attachment_url="/artifacts/m1/m1-99-modularity-smoke-test-v2.zip",
                ),
            )
            _run_seed_once(temp_seed_file, prune_missing=False)

            with session_local() as session:
                challenge = _get_challenge_state(session, TEST_SLUG)
                if challenge is None:
                    raise AssertionError("UPDATE failed: challenge row missing.")
                if challenge.title != "M1: CIA Triad - Modularity Smoke Test v2":
                    raise AssertionError(f"UPDATE failed: unexpected title '{challenge.title}'.")
                if challenge.points != 140:
                    raise AssertionError(f"UPDATE failed: expected points 140, got {challenge.points}.")
                if challenge.attachment_url != "/artifacts/m1/m1-99-modularity-smoke-test-v2.zip":
                    raise AssertionError("UPDATE failed: attachment_url not updated.")
            _assert_frontend_feed_contains(
                client,
                headers,
                TEST_SLUG,
                "M1: CIA Triad - Modularity Smoke Test v2",
            )
            print("PASS: UPDATE reflected in backend DB and frontend feed API.")

            print("STEP 3/3: DELETE (prune) by removing modular source entry...")
            seed_payload = _read_json(temp_seed_file)
            _remove_m1_source_entry(seed_payload, TEST_SOURCE_REL)
            _write_json(temp_seed_file, seed_payload)
            if test_challenge_path.exists():
                test_challenge_path.unlink()

            _run_seed_once(temp_seed_file, prune_missing=True)

            with session_local() as session:
                challenge = _get_challenge_state(session, TEST_SLUG)
                if challenge is None:
                    raise AssertionError("PRUNE failed: challenge row missing unexpectedly.")
                if challenge.is_published:
                    raise AssertionError("PRUNE failed: challenge should be unpublished.")
            _assert_frontend_feed_missing(client, headers, TEST_SLUG)
            print("PASS: DELETE(prune) reflected in backend DB and frontend feed API.")

        print("\nModularity smoke test complete: ADD, UPDATE, DELETE(prune) all passed.")
        return 0
    finally:
        shutil.rmtree(temp_root, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
