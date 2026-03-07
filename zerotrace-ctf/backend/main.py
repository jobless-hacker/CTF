from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from app.core.settings import get_settings
from app.middleware import register_middleware
from app.observability.integrity import IntegritySchedulerHandle, start_integrity_scheduler, stop_integrity_scheduler
from app.routes import api_router
from app.services.seed_sync_watcher import (
    SeedSyncWatcherHandle,
    start_seed_sync_watcher,
    stop_seed_sync_watcher,
)


settings = get_settings()
_BACKEND_ROOT = Path(__file__).resolve().parent
_ARTIFACTS_DIR = _BACKEND_ROOT / "artifacts"
_ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
_ARTIFACTS_ROOT = _ARTIFACTS_DIR.resolve()

app = FastAPI(title="ZeroTrace CTF Backend")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
register_middleware(app)
app.include_router(api_router)


@app.get("/artifacts/{artifact_path:path}")
def download_artifact(artifact_path: str) -> FileResponse:
    candidate = (_ARTIFACTS_ROOT / artifact_path).resolve()
    if not candidate.is_file():
        raise HTTPException(status_code=404, detail="Artifact not found.")

    try:
        candidate.relative_to(_ARTIFACTS_ROOT)
    except ValueError:
        raise HTTPException(status_code=404, detail="Artifact not found.") from None

    return FileResponse(
        path=candidate,
        filename=candidate.name,
        media_type="application/octet-stream",
    )


@app.on_event("startup")
async def startup_observability_tasks() -> None:
    app.state.integrity_scheduler = start_integrity_scheduler()
    app.state.seed_sync_watcher = start_seed_sync_watcher()


@app.on_event("shutdown")
async def shutdown_observability_tasks() -> None:
    handle: IntegritySchedulerHandle | None = getattr(app.state, "integrity_scheduler", None)
    watcher_handle: SeedSyncWatcherHandle | None = getattr(app.state, "seed_sync_watcher", None)
    await stop_integrity_scheduler(handle)
    await stop_seed_sync_watcher(watcher_handle)
