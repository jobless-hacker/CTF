from fastapi import APIRouter

from app.routes.admin_logs import router as admin_logs_router
from app.routes.auth import router as auth_router
from app.routes.challenges import router as challenges_router
from app.routes.health import router as health_router
from app.routes.leaderboard import router as leaderboard_router
from app.routes.tracks import router as tracks_router
from app.routes.users import router as users_router


api_router = APIRouter()
api_router.include_router(health_router)
api_router.include_router(auth_router, prefix="/auth", tags=["auth"])
api_router.include_router(challenges_router)
api_router.include_router(leaderboard_router)
api_router.include_router(tracks_router)
api_router.include_router(users_router)
api_router.include_router(admin_logs_router)
