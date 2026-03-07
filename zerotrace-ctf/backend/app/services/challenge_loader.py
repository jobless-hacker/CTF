from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
import json
from pathlib import Path
import posixpath
from typing import Any


@dataclass(frozen=True, slots=True)
class LabDefinition:
    challenge_id: str
    slug: str
    title: str
    start_path: str
    hints: list[str]
    files: dict[str, str]
    flag_templates: dict[str, str]
    permissions: dict[str, str]


class ChallengeLoader:
    _BACKEND_ROOT = Path(__file__).resolve().parents[2]
    _LABS_ROOT = _BACKEND_ROOT / "app" / "labs"

    def load_base_filesystem(self) -> dict[str, Any]:
        base_path = self._LABS_ROOT / "base_filesystem.json"
        try:
            return self._load_json(base_path)
        except (OSError, json.JSONDecodeError, ValueError):
            return {"/": {}}

    def load_module(self, module_code: str) -> list[LabDefinition]:
        normalized_module = module_code.strip().lower()
        module_root = self._LABS_ROOT / normalized_module
        challenges_dir = module_root / "challenges"
        overlays_dir = module_root / "overlays"
        if not challenges_dir.exists():
            return []

        base_fs = self.load_base_filesystem()
        definitions: list[LabDefinition] = []
        for challenge_file in sorted(challenges_dir.glob("*.json")):
            try:
                payload = self._load_json(challenge_file)
            except (OSError, json.JSONDecodeError, ValueError):
                continue
            challenge_id = str(payload.get("id", "")).strip().lower()
            slug = str(payload.get("slug", "")).strip().lower()
            title = str(payload.get("title", "")).strip()
            start_path = self._normalize_path(str(payload.get("startPath", "/")).strip() or "/")
            hints = payload.get("hints", [])
            flag = payload.get("flag", {})
            if not challenge_id or not slug or not title:
                continue
            if not isinstance(hints, list) or not all(isinstance(item, str) for item in hints):
                continue
            if not isinstance(flag, dict):
                continue

            flag_path = self._normalize_path(str(flag.get("path", "")).strip())
            flag_template = str(flag.get("template", "{flag}")).strip() or "{flag}"
            if not flag_path:
                continue
            permissions = payload.get("permissions", {})
            if not isinstance(permissions, dict):
                continue

            normalized_permissions: dict[str, str] = {}
            for raw_path, raw_mode in permissions.items():
                normalized_path = self._normalize_path(str(raw_path).strip())
                normalized_mode = str(raw_mode).strip()
                if not normalized_path or not normalized_mode:
                    continue
                normalized_permissions[normalized_path] = normalized_mode

            overlay_file = overlays_dir / f"{challenge_id}.json"
            if overlay_file.exists():
                try:
                    overlay = self._load_json(overlay_file)
                except (OSError, json.JSONDecodeError, ValueError):
                    overlay = {}
            else:
                overlay = {}
            merged_tree = self._merge_trees(deepcopy(base_fs), overlay)
            files: dict[str, str] = {}
            self._flatten_tree(merged_tree, "/", files)
            if flag_path not in files:
                continue

            definitions.append(
                LabDefinition(
                    challenge_id=challenge_id,
                    slug=slug,
                    title=title,
                    start_path=start_path,
                    hints=[item.strip() for item in hints if item.strip()],
                    files=files,
                    flag_templates={flag_path: flag_template},
                    permissions=normalized_permissions,
                )
            )

        return definitions

    @classmethod
    def _load_json(cls, path: Path) -> dict[str, Any]:
        payload = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise ValueError(f"Expected JSON object in {path}")
        return payload

    @classmethod
    def _merge_trees(cls, base: dict[str, Any], overlay: dict[str, Any]) -> dict[str, Any]:
        for key, value in overlay.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                base[key] = cls._merge_trees(base[key], value)
                continue
            base[key] = deepcopy(value)
        return base

    @classmethod
    def _flatten_tree(cls, node: Any, current_path: str, output: dict[str, str]) -> None:
        if isinstance(node, str):
            output[cls._normalize_path(current_path)] = node
            return

        if not isinstance(node, dict):
            return

        for name, child in node.items():
            key = str(name)
            if current_path == "/" and key == "/":
                cls._flatten_tree(child, "/", output)
                continue
            next_path = cls._normalize_path(posixpath.join(current_path, key))
            cls._flatten_tree(child, next_path, output)

    @staticmethod
    def _normalize_path(path: str) -> str:
        if not path:
            return ""
        normalized = posixpath.normpath(path)
        if not normalized.startswith("/"):
            normalized = f"/{normalized}"
        return normalized or "/"
