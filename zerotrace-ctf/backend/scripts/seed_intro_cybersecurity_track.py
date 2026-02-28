#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
import sys
from typing import Any

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session, sessionmaker

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.settings import get_settings
from app.models.challenge import Challenge, ChallengeDifficulty
from app.models.track import Track
from app.repositories import challenge_repository
from app.services.challenge_service import ChallengeService


@dataclass
class SeedStats:
    track_created: bool = False
    track_updated: bool = False
    challenges_created: int = 0
    challenges_updated: int = 0
    flags_set: int = 0
    challenges_published: int = 0
    challenges_skipped: int = 0


_REDACTED_FLAG_VALUES = {
    "REDACTED",
    "REDACTED_USE_PRIVATE_FLAGS_FILE",
    "__REDACTED__",
    "__USE_PRIVATE_FLAGS_FILE__",
}


def _default_seed_file() -> Path:
    return BACKEND_ROOT / "config" / "seeds" / "intro-cybersecurity-track.seed.json"


def _load_seed(seed_file: Path) -> dict[str, Any]:
    if not seed_file.exists():
        raise FileNotFoundError(f"Seed file not found: {seed_file}")

    with seed_file.open("r", encoding="utf-8") as fp:
        payload = json.load(fp)

    if not isinstance(payload, dict):
        raise ValueError("Seed file root must be an object.")
    if "track" not in payload or "modules" not in payload:
        raise ValueError("Seed file must contain 'track' and 'modules'.")
    if not isinstance(payload["modules"], list) or not payload["modules"]:
        raise ValueError("'modules' must be a non-empty list.")

    return payload


def _normalize_slug(value: str) -> str:
    return value.strip().lower()


def _parse_difficulty(value: str) -> ChallengeDifficulty:
    normalized = value.strip().lower()
    try:
        return ChallengeDifficulty(normalized)
    except ValueError as exc:
        raise ValueError(f"Unsupported challenge difficulty: {value}") from exc


def _is_redacted_flag(value: str) -> bool:
    normalized = value.strip()
    if not normalized:
        return True
    if normalized in _REDACTED_FLAG_VALUES:
        return True
    return normalized.upper().startswith("REDACTED_")


def _load_flag_overrides(flags_file: Path | None) -> dict[str, str]:
    if flags_file is None:
        return {}

    if not flags_file.exists():
        raise FileNotFoundError(f"Flags file not found: {flags_file}")

    with flags_file.open("r", encoding="utf-8") as fp:
        payload = json.load(fp)

    if not isinstance(payload, dict):
        raise ValueError("Flags file root must be an object mapping challenge slug to flag.")

    overrides: dict[str, str] = {}
    for raw_slug, raw_flag in payload.items():
        slug = _normalize_slug(str(raw_slug))
        flag = str(raw_flag).strip()
        if not slug:
            continue
        if _is_redacted_flag(flag):
            continue
        overrides[slug] = flag

    return overrides


def _ensure_track(session: Session, track_payload: dict[str, Any], stats: SeedStats) -> Track:
    slug = _normalize_slug(str(track_payload["slug"]))
    name = str(track_payload["name"]).strip()
    description = str(track_payload.get("description", "")).strip() or None
    is_active = bool(track_payload.get("is_active", True))

    track = session.execute(select(Track).where(Track.slug == slug)).scalar_one_or_none()
    if track is None:
        track = Track(
            name=name,
            slug=slug,
            description=description,
            is_active=is_active,
        )
        session.add(track)
        session.flush()
        stats.track_created = True
        return track

    changed = False
    if track.name != name:
        track.name = name
        changed = True
    if track.description != description:
        track.description = description
        changed = True
    if track.is_active != is_active:
        track.is_active = is_active
        changed = True

    if changed:
        stats.track_updated = True

    return track


def _upsert_challenge(
    session: Session,
    challenge_service: ChallengeService,
    track: Track,
    module_payload: dict[str, Any],
    challenge_payload: dict[str, Any],
    update_existing: bool,
    allow_publish: bool,
    flag_overrides: dict[str, str],
    stats: SeedStats,
) -> None:
    slug = _normalize_slug(str(challenge_payload["slug"]))
    title = str(challenge_payload["title"]).strip()
    difficulty = _parse_difficulty(str(challenge_payload["difficulty"]))
    points = int(challenge_payload["points"])
    base_description = str(challenge_payload["description"]).strip()
    module_code = str(module_payload["code"]).strip()
    module_name = str(module_payload["name"]).strip()

    description = (
        f"[Module {module_code} - {module_name}]\n"
        f"{base_description}\n"
        f"Submit flag in canonical format."
    )

    existing = challenge_repository.get_by_slug(session, slug)
    if existing is not None and existing.track_id != track.id:
        raise ValueError(f"Challenge slug '{slug}' already exists under a different track.")

    challenge: Challenge
    if existing is None:
        challenge = challenge_service.create_challenge(
            session=session,
            track_id=track.id,
            title=title,
            slug=slug,
            description=description,
            difficulty=difficulty,
            points=points,
        )
        stats.challenges_created += 1
    else:
        challenge = existing
        if update_existing:
            changed = False
            if challenge.title != title:
                challenge.title = title
                changed = True
            if challenge.description != description:
                challenge.description = description
                changed = True
            if challenge.difficulty != difficulty:
                challenge.difficulty = difficulty
                changed = True
            if challenge.points != points:
                challenge.points = points
                changed = True
            if changed:
                stats.challenges_updated += 1
        else:
            stats.challenges_skipped += 1

    plaintext_flag = str(challenge_payload.get("flag", "")).strip()
    if _is_redacted_flag(plaintext_flag):
        plaintext_flag = ""

    override_flag = flag_overrides.get(slug)
    if override_flag:
        plaintext_flag = override_flag

    if plaintext_flag and challenge.flag is None:
        challenge_service.set_flag(session, challenge, plaintext_flag)
        stats.flags_set += 1

    seed_publish = bool(challenge_payload.get("publish", False))
    if allow_publish and seed_publish and not challenge.is_published:
        if challenge.flag is None:
            raise ValueError(
                f"Cannot publish challenge '{slug}' without flag. "
                "Set a valid flag in --flags-file or set it later via admin API."
            )
        challenge_service.publish_challenge(session, challenge)
        stats.challenges_published += 1


def _seed(
    payload: dict[str, Any],
    update_existing: bool,
    allow_publish: bool,
    dry_run: bool,
    flag_overrides: dict[str, str],
) -> SeedStats:
    settings = get_settings()
    engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True, future=True)
    session_local = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False, class_=Session)
    challenge_service = ChallengeService()
    stats = SeedStats()

    with session_local() as session:
        try:
            track = _ensure_track(session, payload["track"], stats)
            for module_payload in payload["modules"]:
                challenges = module_payload.get("challenges", [])
                if not isinstance(challenges, list):
                    raise ValueError(f"Invalid module challenge list in {module_payload.get('code', 'unknown')}")
                for challenge_payload in challenges:
                    _upsert_challenge(
                        session=session,
                        challenge_service=challenge_service,
                        track=track,
                        module_payload=module_payload,
                        challenge_payload=challenge_payload,
                        update_existing=update_existing,
                        allow_publish=allow_publish,
                        flag_overrides=flag_overrides,
                        stats=stats,
                    )

            if dry_run:
                session.rollback()
            else:
                session.commit()
        except Exception:
            session.rollback()
            raise
        finally:
            engine.dispose()

    return stats


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Seed Introduction to Cybersecurity track, modules, and challenges.",
    )
    parser.add_argument(
        "--seed-file",
        type=Path,
        default=_default_seed_file(),
        help="Path to track seed JSON file.",
    )
    parser.add_argument(
        "--update-existing",
        action="store_true",
        help="Update title/description/difficulty/points for existing challenge slugs.",
    )
    parser.add_argument(
        "--no-publish",
        action="store_true",
        help="Create and set flags but skip publish actions.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate and execute seed logic, then rollback transaction.",
    )
    parser.add_argument(
        "--flags-file",
        type=Path,
        help=(
            "Path to private JSON map of challenge slug to real flag. "
            "Use this to avoid keeping plaintext flags in public seed files."
        ),
    )
    return parser


def main() -> int:
    parser = _build_parser()
    args = parser.parse_args()

    payload = _load_seed(args.seed_file)
    flag_overrides = _load_flag_overrides(args.flags_file)
    stats = _seed(
        payload=payload,
        update_existing=args.update_existing,
        allow_publish=not args.no_publish,
        dry_run=args.dry_run,
        flag_overrides=flag_overrides,
    )

    print("Intro Cybersecurity track seed completed.")
    print(f"track_created={stats.track_created}")
    print(f"track_updated={stats.track_updated}")
    print(f"challenges_created={stats.challenges_created}")
    print(f"challenges_updated={stats.challenges_updated}")
    print(f"flags_set={stats.flags_set}")
    print(f"challenges_published={stats.challenges_published}")
    print(f"challenges_skipped={stats.challenges_skipped}")
    print(f"dry_run={args.dry_run}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
