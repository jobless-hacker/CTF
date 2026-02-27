from __future__ import annotations

from collections.abc import Callable, Iterable

from fastapi import Depends, HTTPException, status

from app.dependencies.auth import get_current_user
from app.models.user import User


def require_roles(required_roles: list[str]) -> Callable[..., User]:
    allowed_roles = tuple(required_roles)

    def _role_guard(current_user: User = Depends(get_current_user)) -> User:
        user_roles = {role.name for role in current_user.roles if role.name}

        if not user_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )

        if not _has_any_required_role(user_roles, allowed_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )

        return current_user

    return _role_guard


def _has_any_required_role(user_roles: set[str], required_roles: Iterable[str]) -> bool:
    return any(role_name in user_roles for role_name in required_roles)


require_admin = require_roles(["admin"])


# Example usage:
# from fastapi import APIRouter, Depends
# from app.dependencies.rbac import require_admin
# from app.models.user import User
#
# router = APIRouter()
#
# @router.post("/admin/example")
# async def admin_action(current_user: User = Depends(require_admin)) -> dict[str, str]:
#     return {"status": "ok"}
