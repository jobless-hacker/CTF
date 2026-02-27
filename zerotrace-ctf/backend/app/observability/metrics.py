from __future__ import annotations

from typing import Any

from app.core.settings import get_settings
from app.observability.logger import log_event


class MetricsBackend:
    def increment(self, name: str, value: int = 1, labels: dict[str, str] | None = None) -> None:
        raise NotImplementedError

    def observe(self, name: str, value: float, labels: dict[str, str] | None = None) -> None:
        raise NotImplementedError

    def set_gauge(self, name: str, value: float, labels: dict[str, str] | None = None) -> None:
        raise NotImplementedError


class JsonMetricsBackend(MetricsBackend):
    def increment(self, name: str, value: int = 1, labels: dict[str, str] | None = None) -> None:
        if not self._enabled():
            return
        log_event(
            "metric_increment",
            name=name,
            value=value,
            labels=self._normalize_labels(labels),
        )

    def observe(self, name: str, value: float, labels: dict[str, str] | None = None) -> None:
        if not self._enabled():
            return
        log_event(
            "metric_observe",
            name=name,
            value=value,
            labels=self._normalize_labels(labels),
        )

    def set_gauge(self, name: str, value: float, labels: dict[str, str] | None = None) -> None:
        if not self._enabled():
            return
        log_event(
            "metric_set_gauge",
            name=name,
            value=value,
            labels=self._normalize_labels(labels),
        )

    @staticmethod
    def _normalize_labels(labels: dict[str, str] | None) -> dict[str, str]:
        if labels is None:
            return {}
        return {str(key): str(value) for key, value in labels.items()}

    @staticmethod
    def _enabled() -> bool:
        return get_settings().OBSERVABILITY_ENABLED


metrics: MetricsBackend = JsonMetricsBackend()

