from __future__ import annotations

import json

from app.services.challenge_lab_service import ChallengeLabService


def test_lab_files_do_not_expose_ctf_flags_without_private_mapping(
    monkeypatch,
) -> None:
    monkeypatch.setenv("LAB_PRIVATE_FLAGS_FILE", "")
    service = ChallengeLabService()

    grep_result = service.execute_command(
        "m12-permission-denied",
        r"grep -R 'CTF\{' /",
        "/",
    )
    cat_result = service.execute_command(
        "m12-permission-denied",
        "cat /var/lib/secret/flag.txt",
        "/",
    )

    assert grep_result.exit_code == 1
    assert grep_result.output == ""
    assert "CTF{" not in cat_result.output


def test_lab_flags_are_injected_from_private_mapping_file(
    tmp_path,
    monkeypatch,
) -> None:
    flags_file = tmp_path / "private-flags.json"
    flags_file.write_text(
        json.dumps(
            {
                "m12-permission-denied": "CTF{runtime_m12_flag}",
                "m16-reverse-shell-drop": "CTF{runtime_m16_flag}",
            }
        ),
        encoding="utf-8",
    )
    monkeypatch.setenv("LAB_PRIVATE_FLAGS_FILE", str(flags_file))
    service = ChallengeLabService()

    m12_result = service.execute_command(
        "m12-permission-denied",
        "cat /var/lib/secret/flag.txt",
        "/",
    )
    m16_result = service.execute_command(
        "m16-reverse-shell-drop",
        "cat /tmp/notes.txt",
        "/",
    )

    assert m12_result.exit_code == 0
    assert m12_result.output == "CTF{runtime_m12_flag}"
    assert m16_result.exit_code == 0
    assert m16_result.output == "Reverse shell dropped. Flag: CTF{runtime_m16_flag}"
