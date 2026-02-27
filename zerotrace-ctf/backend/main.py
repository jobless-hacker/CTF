from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.settings import get_settings
from app.middleware import register_middleware
from app.observability.integrity import IntegritySchedulerHandle, start_integrity_scheduler, stop_integrity_scheduler
from app.routes import api_router


settings = get_settings()
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


@app.on_event("startup")
async def startup_observability_tasks() -> None:
    app.state.integrity_scheduler = start_integrity_scheduler()


@app.on_event("shutdown")
async def shutdown_observability_tasks() -> None:
    handle: IntegritySchedulerHandle | None = getattr(app.state, "integrity_scheduler", None)
    await stop_integrity_scheduler(handle)
