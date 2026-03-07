from __future__ import annotations

import asyncio
from contextlib import suppress
from dataclasses import dataclass
from pathlib import Path
import subprocess
import sys
import time
from typing import Any

from app.core.settings import get_settings
from app.observability.logger import log_event


_BACKEND_ROOT = Path(__file__).resolve().parents[2]
_SEED_SCRIPT_PATH = _BACKEND_ROOT / "scripts" / "seed_intro_cybersecurity_track.py"


@dataclass
class SeedSyncWatcherHandle:
    task: asyncio.Task[None]


def start_seed_sync_watcher() -> SeedSyncWatcherHandle | None:
    settings = get_settings()
    if not settings.SEED_SYNC_WATCH_ENABLED:
        return None

    task = asyncio.create_task(_watch_loop(), name="seed-sync-watcher")
    log_event(
        "seed_sync_watcher_started",
        interval_seconds=settings.SEED_SYNC_WATCH_INTERVAL_SECONDS,
        debounce_seconds=settings.SEED_SYNC_WATCH_DEBOUNCE_SECONDS,
    )
    return SeedSyncWatcherHandle(task=task)


async def stop_seed_sync_watcher(handle: SeedSyncWatcherHandle | None) -> None:
    if handle is None:
        return
    handle.task.cancel()
    with suppress(asyncio.CancelledError):
        await handle.task
    log_event("seed_sync_watcher_stopped")


async def _watch_loop() -> None:
    settings = get_settings()
    seed_file = _resolve_backend_path(settings.SEED_SYNC_SEED_FILE)
    flags_file = _resolve_backend_path(settings.SEED_SYNC_FLAGS_FILE)
    modules_dir = _resolve_backend_path(settings.SEED_SYNC_MODULES_DIR)

    if settings.SEED_SYNC_SYNC_ON_STARTUP:
        await asyncio.to_thread(_run_seed_sync_once, seed_file, flags_file)

    last_snapshot = _collect_snapshot(
        seed_file=seed_file,
        flags_file=flags_file,
        modules_dir=modules_dir,
    )

    pending_change_since: float | None = None

    while True:
        await asyncio.sleep(settings.SEED_SYNC_WATCH_INTERVAL_SECONDS)

        current_snapshot = _collect_snapshot(
            seed_file=seed_file,
            flags_file=flags_file,
            modules_dir=modules_dir,
        )
        if current_snapshot == last_snapshot:
            pending_change_since = None
            continue

        now = time.monotonic()
        if pending_change_since is None:
            pending_change_since = now
            continue
        if now - pending_change_since < settings.SEED_SYNC_WATCH_DEBOUNCE_SECONDS:
            continue

        sync_ok = await asyncio.to_thread(_run_seed_sync_once, seed_file, flags_file)
        if sync_ok:
            last_snapshot = _collect_snapshot(
                seed_file=seed_file,
                flags_file=flags_file,
                modules_dir=modules_dir,
            )
            pending_change_since = None
            continue

        pending_change_since = now


def _resolve_backend_path(raw_path: str) -> Path:
    path = Path(raw_path.strip())
    if not path.is_absolute():
        path = _BACKEND_ROOT / path
    return path.resolve()


def _collect_snapshot(
    *,
    seed_file: Path,
    flags_file: Path,
    modules_dir: Path,
) -> dict[str, tuple[bool, int, int]]:
    snapshot: dict[str, tuple[bool, int, int]] = {}

    snapshot[str(seed_file)] = _stat_tuple(seed_file)
    snapshot[str(flags_file)] = _stat_tuple(flags_file)

    if modules_dir.exists():
        for candidate in sorted(modules_dir.rglob("*")):
            if not candidate.is_file():
                continue
            snapshot[str(candidate)] = _stat_tuple(candidate)
    else:
        snapshot[str(modules_dir)] = _stat_tuple(modules_dir)

    return snapshot


def _stat_tuple(path: Path) -> tuple[bool, int, int]:
    try:
        stat = path.stat()
        return (True, stat.st_mtime_ns, stat.st_size)
    except FileNotFoundError:
        return (False, 0, 0)


def _run_seed_sync_once(seed_file: Path, flags_file: Path) -> bool:
    if not seed_file.exists():
        log_event(
            "seed_sync_skipped_missing_seed_file",
            seed_file=str(seed_file),
        )
        return False

    command = [
        sys.executable,
        str(_SEED_SCRIPT_PATH),
        "--seed-file",
        str(seed_file),
        "--update-existing",
    ]
    if flags_file.exists():
        command.extend(["--flags-file", str(flags_file)])

    try:
        result = subprocess.run(
            command,
            cwd=str(_BACKEND_ROOT),
            capture_output=True,
            text=True,
            check=False,
        )
    except Exception as exc:
        log_event(
            "seed_sync_failed",
            outcome="error",
            error_type=type(exc).__name__,
            seed_file=str(seed_file),
            flags_file=str(flags_file),
        )
        return False

    if result.returncode != 0:
        log_event(
            "seed_sync_failed",
            outcome="nonzero_exit",
            returncode=result.returncode,
            seed_file=str(seed_file),
            flags_file=str(flags_file),
            stderr_tail=_tail(result.stderr),
            stdout_tail=_tail(result.stdout),
        )
        return False

    log_event(
        "seed_sync_applied",
        outcome="ok",
        seed_file=str(seed_file),
        flags_file=str(flags_file),
        stdout_tail=_tail(result.stdout),
    )
    return True


def _tail(content: str, max_chars: int = 500) -> str:
    trimmed = content.strip()
    if len(trimmed) <= max_chars:
        return trimmed
    return trimmed[-max_chars:]
