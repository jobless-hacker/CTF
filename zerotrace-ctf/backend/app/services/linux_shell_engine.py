from __future__ import annotations

from dataclasses import dataclass, field
from fnmatch import fnmatch
import posixpath
import shlex
from typing import Protocol


class LinuxFilesystemView(Protocol):
    def normalize_path(self, path: str) -> str: ...

    def resolve(self, cwd: str, target: str) -> str: ...

    def exists(self, path: str) -> bool: ...

    def is_file(self, path: str) -> bool: ...

    def is_dir(self, path: str) -> bool: ...

    def read_file(self, path: str) -> str: ...

    def file_size_bytes(self, path: str) -> int: ...

    def list_dir(self, path: str, show_all: bool) -> list[str]: ...

    def iter_files_under(self, path: str, recursive: bool) -> list[str]: ...

    def walk(self, path: str) -> list[str]: ...

    def permission_bits(self, path: str) -> int: ...

    def permission_string(self, path: str) -> str: ...


@dataclass(slots=True)
class ShellSession:
    filesystem: LinuxFilesystemView
    cwd: str
    history: list[str] = field(default_factory=list)


@dataclass(frozen=True, slots=True)
class ShellCommandResult:
    output: str
    cwd: str
    exit_code: int


class LinuxShellEngine:
    BLOCKED_COMMANDS = {
        "rm",
        "mv",
        "cp",
        "sudo",
        "chmod",
        "chown",
        "curl",
        "wget",
        "ssh",
        "vi",
        "nano",
        "touch",
    }
    BLOCKED_TOKENS = {">", ">>", "1>", "1>>", "2>", "2>>", "<", "<<", "|", ";", "&&", "||"}
    BLOCKED_FRAGMENTS = (";", "&&", "||", "`", "$(", ">", "<", "|")

    def run(self, command: str, session: ShellSession) -> ShellCommandResult:
        command_text = command.strip()
        if not command_text:
            return ShellCommandResult(output="", cwd=session.cwd, exit_code=0)

        try:
            tokens = shlex.split(command_text)
        except ValueError as exc:
            return ShellCommandResult(output=f"parse error: {exc}", cwd=session.cwd, exit_code=1)

        if not tokens:
            return ShellCommandResult(output="", cwd=session.cwd, exit_code=0)

        name = tokens[0]
        args = tokens[1:]
        if self._is_blocked_command(name, tokens):
            return ShellCommandResult(
                output="Command not allowed in this lab.",
                cwd=session.cwd,
                exit_code=126,
            )

        session.history.append(command_text)

        if name == "help":
            return ShellCommandResult(
                output=(
                    "Supported commands: help, pwd, ls, cd, cat, grep, find, du, history, clear\n"
                    "Examples:\n"
                    "  ls -la /etc\n"
                    "  find / -perm -4000\n"
                    "  grep -R include /etc\n"
                    "  find /etc -name '*.conf'\n"
                    "  du -ah /var"
                ),
                cwd=session.cwd,
                exit_code=0,
            )

        if name == "pwd":
            return ShellCommandResult(output=session.cwd, cwd=session.cwd, exit_code=0)

        if name == "history":
            return ShellCommandResult(output="\n".join(session.history), cwd=session.cwd, exit_code=0)

        if name == "clear":
            return ShellCommandResult(output="__CLEAR__", cwd=session.cwd, exit_code=0)

        if name == "cd":
            return self._cmd_cd(session, args)
        if name == "ls":
            return self._cmd_ls(session, args)
        if name == "cat":
            return self._cmd_cat(session, args)
        if name == "grep":
            return self._cmd_grep(session, args)
        if name == "find":
            return self._cmd_find(session, args)
        if name == "du":
            return self._cmd_du(session, args)

        return ShellCommandResult(output=f"{name}: command not found", cwd=session.cwd, exit_code=127)

    @classmethod
    def _is_blocked_command(cls, name: str, tokens: list[str]) -> bool:
        normalized_name = posixpath.basename(name)
        if normalized_name in cls.BLOCKED_COMMANDS:
            return True

        if any(token in cls.BLOCKED_TOKENS for token in tokens):
            return True

        if any(fragment in token for token in tokens for fragment in cls.BLOCKED_FRAGMENTS):
            return True

        if normalized_name == "echo" and len(tokens) > 1:
            return True

        return False

    def _cmd_cd(self, session: ShellSession, args: list[str]) -> ShellCommandResult:
        target = "/" if not args else args[0]
        if len(args) > 1:
            return ShellCommandResult(output="cd: too many arguments", cwd=session.cwd, exit_code=1)

        destination = session.filesystem.resolve(session.cwd, target)
        if not session.filesystem.exists(destination):
            return ShellCommandResult(output=f"cd: {target}: No such file or directory", cwd=session.cwd, exit_code=1)
        if not session.filesystem.is_dir(destination):
            return ShellCommandResult(output=f"cd: {target}: Not a directory", cwd=session.cwd, exit_code=1)

        session.cwd = destination
        return ShellCommandResult(output="", cwd=session.cwd, exit_code=0)

    def _cmd_ls(self, session: ShellSession, args: list[str]) -> ShellCommandResult:
        show_all = False
        long_format = False
        target: str | None = None

        for arg in args:
            if arg.startswith("-"):
                for flag in arg[1:]:
                    if flag == "a":
                        show_all = True
                    elif flag == "l":
                        long_format = True
                    else:
                        return ShellCommandResult(
                            output=f"ls: invalid option -- '{flag}'",
                            cwd=session.cwd,
                            exit_code=1,
                        )
                continue

            if target is not None:
                return ShellCommandResult(output="ls: too many operands", cwd=session.cwd, exit_code=1)
            target = arg

        path = session.filesystem.resolve(session.cwd, target or ".")
        if not session.filesystem.exists(path):
            return ShellCommandResult(
                output=f"ls: cannot access '{target or '.'}': No such file or directory",
                cwd=session.cwd,
                exit_code=1,
            )

        if session.filesystem.is_file(path):
            if not long_format:
                return ShellCommandResult(output=posixpath.basename(path), cwd=session.cwd, exit_code=0)
            mode = session.filesystem.permission_string(path)
            return ShellCommandResult(output=f"{mode} {posixpath.basename(path)}", cwd=session.cwd, exit_code=0)

        listing = session.filesystem.list_dir(path, show_all=show_all)
        if not long_format:
            return ShellCommandResult(output="\n".join(listing), cwd=session.cwd, exit_code=0)

        rendered: list[str] = []
        for entry in listing:
            if entry == ".":
                entry_path = path
            elif entry == "..":
                entry_path = session.filesystem.resolve(path, "..")
            else:
                entry_path = session.filesystem.resolve(path, entry)
            mode = session.filesystem.permission_string(entry_path)
            rendered.append(f"{mode} {entry}")
        return ShellCommandResult(output="\n".join(rendered), cwd=session.cwd, exit_code=0)

    def _cmd_cat(self, session: ShellSession, args: list[str]) -> ShellCommandResult:
        if not args:
            return ShellCommandResult(output="cat: missing file operand", cwd=session.cwd, exit_code=1)

        chunks: list[str] = []
        for raw_path in args:
            path = session.filesystem.resolve(session.cwd, raw_path)
            if not session.filesystem.exists(path):
                return ShellCommandResult(
                    output=f"cat: {raw_path}: No such file or directory",
                    cwd=session.cwd,
                    exit_code=1,
                )
            if session.filesystem.is_dir(path):
                return ShellCommandResult(
                    output="cat: target is a directory",
                    cwd=session.cwd,
                    exit_code=1,
                )

            content = session.filesystem.read_file(path).rstrip("\n")
            if len(args) > 1:
                chunks.append(f"==> {path} <==")
            chunks.append(content)

        return ShellCommandResult(output="\n".join(chunks), cwd=session.cwd, exit_code=0)

    def _cmd_grep(self, session: ShellSession, args: list[str]) -> ShellCommandResult:
        recursive = False
        index = 0
        while index < len(args) and args[index].startswith("-"):
            options = args[index][1:]
            for option in options:
                if option in {"r", "R"}:
                    recursive = True
                else:
                    return ShellCommandResult(
                        output=f"grep: invalid option -- '{option}'",
                        cwd=session.cwd,
                        exit_code=1,
                    )
            index += 1

        remaining = args[index:]
        if len(remaining) < 2:
            return ShellCommandResult(output="grep: usage grep -R <term> <path>", cwd=session.cwd, exit_code=1)

        pattern, raw_path = remaining[0], remaining[1]
        path = session.filesystem.resolve(session.cwd, raw_path)
        if not session.filesystem.exists(path):
            return ShellCommandResult(output=f"grep: {raw_path}: No such file or directory", cwd=session.cwd, exit_code=1)
        if session.filesystem.is_dir(path) and not recursive:
            return ShellCommandResult(output=f"grep: {raw_path}: Is a directory", cwd=session.cwd, exit_code=1)
        if not pattern:
            return ShellCommandResult(output="grep: empty pattern", cwd=session.cwd, exit_code=1)

        matches: list[str] = []
        for file_path in session.filesystem.iter_files_under(path, recursive=recursive):
            for line_no, line in enumerate(session.filesystem.read_file(file_path).splitlines(), start=1):
                if pattern in line:
                    matches.append(f"{file_path}:{line_no}:{line}")

        if not matches:
            return ShellCommandResult(output="", cwd=session.cwd, exit_code=1)
        return ShellCommandResult(output="\n".join(matches), cwd=session.cwd, exit_code=0)

    def _cmd_find(self, session: ShellSession, args: list[str]) -> ShellCommandResult:
        if not args:
            return ShellCommandResult(output="find: usage find <path> -name <pattern>", cwd=session.cwd, exit_code=1)

        raw_path = args[0]
        query_path = session.filesystem.resolve(session.cwd, raw_path)
        if not session.filesystem.exists(query_path):
            return ShellCommandResult(output=f"find: '{raw_path}': No such file or directory", cwd=session.cwd, exit_code=1)

        type_filter: str | None = None
        name_glob: str | None = None
        perm_filter: str | None = None
        index = 1
        while index < len(args):
            token = args[index]
            if token == "-type":
                if index + 1 >= len(args):
                    return ShellCommandResult(output="find: missing argument to '-type'", cwd=session.cwd, exit_code=1)
                type_filter = args[index + 1]
                if type_filter not in {"f", "d"}:
                    return ShellCommandResult(
                        output=f"find: unknown argument to -type: {type_filter}",
                        cwd=session.cwd,
                        exit_code=1,
                    )
                index += 2
                continue

            if token == "-name":
                if index + 1 >= len(args):
                    return ShellCommandResult(output="find: missing argument to '-name'", cwd=session.cwd, exit_code=1)
                name_glob = args[index + 1]
                index += 2
                continue

            if token == "-perm":
                if index + 1 >= len(args):
                    return ShellCommandResult(output="find: missing argument to '-perm'", cwd=session.cwd, exit_code=1)
                perm_filter = args[index + 1]
                index += 2
                continue

            return ShellCommandResult(output=f"find: unsupported predicate '{token}'", cwd=session.cwd, exit_code=1)

        results: list[str] = []
        for candidate in session.filesystem.walk(query_path):
            if type_filter == "f" and not session.filesystem.is_file(candidate):
                continue
            if type_filter == "d" and not session.filesystem.is_dir(candidate):
                continue
            if name_glob and not fnmatch(posixpath.basename(candidate), name_glob):
                continue
            if perm_filter is not None and not self._matches_perm(session.filesystem.permission_bits(candidate), perm_filter):
                continue
            results.append(candidate)

        return ShellCommandResult(output="\n".join(results), cwd=session.cwd, exit_code=0)

    @staticmethod
    def _matches_perm(mode_bits: int, expression: str) -> bool:
        candidate = expression.strip()
        if not candidate:
            return False
        try:
            if candidate.startswith("-"):
                required = int(candidate[1:], 8)
                return (mode_bits & required) == required
            expected = int(candidate, 8)
            return mode_bits == expected
        except ValueError:
            return False

    def _cmd_du(self, session: ShellSession, args: list[str]) -> ShellCommandResult:
        human_readable = False
        all_entries = False
        summary_only = False
        target: str | None = None

        for arg in args:
            if arg.startswith("-"):
                for flag in arg[1:]:
                    if flag == "h":
                        human_readable = True
                        continue
                    if flag == "a":
                        all_entries = True
                        continue
                    if flag == "s":
                        summary_only = True
                        continue
                    return ShellCommandResult(
                        output=f"du: invalid option -- '{flag}'",
                        cwd=session.cwd,
                        exit_code=1,
                    )
                continue

            if target is not None:
                return ShellCommandResult(output="du: extra operand", cwd=session.cwd, exit_code=1)
            target = arg

        path = session.filesystem.resolve(session.cwd, target or ".")
        if not session.filesystem.exists(path):
            return ShellCommandResult(
                output=f"du: cannot access '{target or '.'}': No such file or directory",
                cwd=session.cwd,
                exit_code=1,
            )

        if summary_only:
            all_entries = False

        if all_entries and session.filesystem.is_dir(path):
            lines: list[str] = []
            for candidate in session.filesystem.walk(path):
                size = self._du_size(session.filesystem, candidate)
                rendered_size = self._format_size(size, human_readable=human_readable)
                lines.append(f"{rendered_size}\t{candidate}")
            return ShellCommandResult(output="\n".join(lines), cwd=session.cwd, exit_code=0)

        size = self._du_size(session.filesystem, path)
        rendered_size = self._format_size(size, human_readable=human_readable)
        return ShellCommandResult(output=f"{rendered_size}\t{path}", cwd=session.cwd, exit_code=0)

    @staticmethod
    def _du_size(filesystem: LinuxFilesystemView, path: str) -> int:
        if filesystem.is_file(path):
            return filesystem.file_size_bytes(path)
        return sum(
            filesystem.file_size_bytes(file_path)
            for file_path in filesystem.iter_files_under(path, recursive=True)
        )

    @staticmethod
    def _format_size(size: int, *, human_readable: bool) -> str:
        if not human_readable:
            return str(size)

        units = ["B", "K", "M", "G", "T"]
        value = float(size)
        unit_index = 0
        while value >= 1024 and unit_index < len(units) - 1:
            value /= 1024
            unit_index += 1

        if unit_index == 0:
            return f"{int(value)}{units[unit_index]}"
        return f"{value:.1f}{units[unit_index]}"
