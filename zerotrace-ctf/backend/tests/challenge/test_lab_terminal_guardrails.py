from __future__ import annotations

import re

from app.services.challenge_lab_service import ChallengeLabService


def test_m11_help_lists_supported_commands_and_du(monkeypatch) -> None:
    monkeypatch.setenv("LAB_PRIVATE_FLAGS_FILE", "")
    service = ChallengeLabService()

    result = service.execute_command("m11-hidden-in-etc", "help", "/etc")

    assert result.exit_code == 0
    assert "Supported commands: help, pwd, ls, cd, cat, grep, find, du, history, clear" in result.output
    assert "du -h /etc" in result.output


def test_m11_blocks_dangerous_commands(monkeypatch) -> None:
    monkeypatch.setenv("LAB_PRIVATE_FLAGS_FILE", "")
    service = ChallengeLabService()

    for command in (
        "rm -rf /",
        "mv /tmp/a /tmp/b",
        "cp /tmp/a /tmp/b",
        "wget http://example.com",
        "curl http://example.com",
        "chmod 777 /tmp/x",
        "chown root /tmp/x",
        "sudo su",
        "ssh user@10.0.0.9",
        "vi /tmp/x",
        "nano /tmp/x",
        "touch /tmp/x",
        "echo test > /tmp/x",
        "cat /etc/passwd; id",
        "echo $(id)",
        "echo `id`",
    ):
        result = service.execute_command("m11-hidden-in-etc", command, "/etc")
        assert result.exit_code == 126
        assert result.output == "Command not allowed in this lab."


def test_m11_du_reports_size(monkeypatch) -> None:
    monkeypatch.setenv("LAB_PRIVATE_FLAGS_FILE", "")
    service = ChallengeLabService()

    bytes_result = service.execute_command("m11-hidden-in-etc", "du /etc", "/")
    human_result = service.execute_command("m11-hidden-in-etc", "du -h /etc", "/")

    assert bytes_result.exit_code == 0
    assert re.fullmatch(r"\d+\t/etc", bytes_result.output)

    assert human_result.exit_code == 0
    assert re.fullmatch(r"[0-9]+(?:\.[0-9])?[BKMGTP]\t/etc", human_result.output)


def test_m11_history_and_clear_commands_are_available(monkeypatch) -> None:
    monkeypatch.setenv("LAB_PRIVATE_FLAGS_FILE", "")
    service = ChallengeLabService()

    history_result = service.execute_command("m11-hidden-in-etc", "history", "/etc")
    clear_result = service.execute_command("m11-hidden-in-etc", "clear", "/etc")

    assert history_result.exit_code == 0
    assert history_result.output == "history"
    assert clear_result.exit_code == 0
    assert clear_result.output == "__CLEAR__"


def test_structured_m11_challenge_definitions_are_loaded(monkeypatch) -> None:
    monkeypatch.setenv("LAB_PRIVATE_FLAGS_FILE", "")
    service = ChallengeLabService()

    expected_slugs = {
        "m11-hidden-in-etc",
        "m11-forgotten-config",
        "m11-lost-backup",
        "m11-strange-include",
        "m11-webroot-secret",
        "m11-temporary-clue",
        "m11-large-file",
        "m11-hidden-environment",
    }

    for slug in expected_slugs:
        assert service.has_lab(slug) is True


def test_structured_m11_challenges_use_configured_start_paths(monkeypatch) -> None:
    monkeypatch.setenv("LAB_PRIVATE_FLAGS_FILE", "")
    service = ChallengeLabService()

    assert service.get_default_cwd("m11-hidden-in-etc") == "/etc"
    assert service.get_default_cwd("m11-webroot-secret") == "/var/www/html"
    assert service.get_default_cwd("m11-hidden-environment") == "/home/dev"
    hints = service.get_lab_hints("m11-hidden-in-etc")
    assert hints is not None
    assert len(hints) == 3
