from __future__ import annotations

from contextvars import ContextVar
from uuid import UUID, uuid4

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response


_REQUEST_ID_CONTEXT: ContextVar[str | None] = ContextVar("request_id", default=None)


class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = _resolve_request_id(request.headers.get("X-Request-ID"))
        token = _REQUEST_ID_CONTEXT.set(request_id)
        request.state.request_id = request_id
        try:
            response = await call_next(request)
        finally:
            _REQUEST_ID_CONTEXT.reset(token)

        response.headers["X-Request-ID"] = request_id
        return response


def get_request_id() -> str | None:
    return _REQUEST_ID_CONTEXT.get()


def _resolve_request_id(candidate: str | None) -> str:
    if candidate:
        try:
            return str(UUID(candidate))
        except ValueError:
            pass
    return str(uuid4())

