from __future__ import annotations

from datetime import datetime, timezone
import json
import logging
import sys
from typing import Any
from uuid import UUID

from app.core.settings import get_settings


_LOGGER_NAME = "zerotrace.observability"
_REDACTED_KEYS = {
    "password",
    "password_hash",
    "flag",
    "flag_hash",
    "authorization",
}
_SERVICE_NAME = "zerotrace-backend"


def _get_logger() -> logging.Logger:
    logger = logging.getLogger(_LOGGER_NAME)
    if logger.handlers:
        return logger

    handler = logging.StreamHandler(stream=sys.stdout)
    handler.setFormatter(logging.Formatter("%(message)s"))
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    logger.propagate = False
    return logger


def log_event(event_type: str, **fields: Any) -> None:
    settings = get_settings()
    if not settings.OBSERVABILITY_ENABLED:
        return

    payload_fields = _sanitize_mapping(fields)
    if "request_id" not in payload_fields:
        request_id = _safe_get_request_id()
        if request_id is not None:
            payload_fields["request_id"] = request_id

    payload: dict[str, Any] = {
        "timestamp": _utc_now_iso(),
        "level": "INFO",
        "service": _SERVICE_NAME,
        "environment": settings.ENVIRONMENT,
        "event_type": event_type,
    }
    payload.update(payload_fields)
    _get_logger().info(json.dumps(payload, separators=(",", ":"), sort_keys=True))


def _sanitize_mapping(values: dict[str, Any]) -> dict[str, Any]:
    sanitized: dict[str, Any] = {}
    for key, value in values.items():
        key_str = str(key)
        if key_str.lower() in _REDACTED_KEYS:
            sanitized[key_str] = "[REDACTED]"
            continue
        sanitized[key_str] = _sanitize_value(value)
    return sanitized


def _sanitize_value(value: Any) -> Any:
    if isinstance(value, dict):
        return _sanitize_mapping(value)
    if isinstance(value, (list, tuple, set)):
        return [_sanitize_value(item) for item in value]
    if isinstance(value, datetime):
        if value.tzinfo is None or value.utcoffset() is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
    if isinstance(value, UUID):
        return str(value)
    if isinstance(value, Exception):
        return type(value).__name__
    return value


def _safe_get_request_id() -> str | None:
    try:
        from app.middleware.request_id import get_request_id
    except Exception:
        return None
    return get_request_id()


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

