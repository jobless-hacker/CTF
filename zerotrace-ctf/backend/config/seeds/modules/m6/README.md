# M6 Modular Challenge Definitions

Use this folder to keep M6 challenge content in separate JSON files so updates do not require editing the full seed.

## Current modular challenges

- `m6-01-suspicious-connection.json`
- `m6-02-dns-beaconing.json`
- `m6-03-plaintext-credentials.json`
- `m6-04-port-scan.json`
- `m6-05-malware-download.json`
- `m6-06-c2-communication.json`
- `m6-07-suspicious-dns-query.json`
- `m6-08-data-exfiltration.json`
- `m6-09-infected-host.json`
- `m6-10-lateral-movement.json`

## M6-01 Real-World Upgrade Assets

- `m6-01-realworld-upgrade-report.md`
- `m6-01-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m6_01_realworld_artifact.ps1`

## M6-02 Real-World Upgrade Assets

- `m6-02-realworld-upgrade-report.md`
- `m6-02-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m6_02_realworld_artifact.ps1`

## M6-03 Real-World Upgrade Assets

- `m6-03-realworld-upgrade-report.md`
- `m6-03-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m6_03_realworld_artifact.ps1`

## M6-04 Real-World Upgrade Assets

- `m6-04-realworld-upgrade-report.md`
- `m6-04-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m6_04_realworld_artifact.ps1`

## M6-05 Real-World Upgrade Assets

- `m6-05-realworld-upgrade-report.md`
- `m6-05-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m6_05_realworld_artifact.ps1`

## M6-06 Real-World Upgrade Assets

- `m6-06-realworld-upgrade-report.md`
- `m6-06-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m6_06_realworld_artifact.ps1`

## M6-07 Real-World Upgrade Assets

- `m6-07-realworld-upgrade-report.md`
- `m6-07-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m6_07_realworld_artifact.ps1`

## M6-08 Real-World Upgrade Assets

- `m6-08-realworld-upgrade-report.md`
- `m6-08-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m6_08_realworld_artifact.ps1`

## M6-09 Real-World Upgrade Assets

- `m6-09-realworld-upgrade-report.md`
- `m6-09-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m6_09_realworld_artifact.ps1`

## M6-10 Real-World Upgrade Assets

- `m6-10-realworld-upgrade-report.md`
- `m6-10-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m6_10_realworld_artifact.ps1`

## Sync

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing
```

Notes:
- Prune is enabled by default, so removed modular files are unpublished from backend and disappear from frontend listings after sync.
- Missing `source_file` paths are skipped by default during sync. Use `--strict-missing-source-files` if you want the command to fail instead.
