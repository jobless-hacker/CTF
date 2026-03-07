# M7 Modular Challenge Definitions

Use this folder to keep M7 challenge content in separate JSON files so updates do not require editing the full seed.

## Current modular challenges

- `m7-01-suspicious-login-query.json`
- `m7-02-reflected-script.json`
- `m7-03-file-path-access.json`
- `m7-04-broken-authentication.json`
- `m7-05-exposed-admin-panel.json`
- `m7-06-file-upload-abuse.json`
- `m7-07-api-data-exposure.json`
- `m7-08-command-injection.json`
- `m7-09-insecure-cookie.json`
- `m7-10-sensitive-backup.json`

## M7-01 Real-World Upgrade Assets

- `m7-01-realworld-upgrade-report.md`
- `m7-01-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m7_01_realworld_artifact.ps1`

## M7-02 Real-World Upgrade Assets

- `m7-02-realworld-upgrade-report.md`
- `m7-02-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m7_02_realworld_artifact.ps1`

## M7-03 Real-World Upgrade Assets

- `m7-03-realworld-upgrade-report.md`
- `m7-03-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m7_03_realworld_artifact.ps1`

## M7-04 Real-World Upgrade Assets

- `m7-04-realworld-upgrade-report.md`
- `m7-04-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m7_04_realworld_artifact.ps1`

## M7-05 Real-World Upgrade Assets

- `m7-05-realworld-upgrade-report.md`
- `m7-05-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m7_05_realworld_artifact.ps1`

## M7-06 Real-World Upgrade Assets

- `m7-06-realworld-upgrade-report.md`
- `m7-06-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m7_06_realworld_artifact.ps1`

## M7-07 Real-World Upgrade Assets

- `m7-07-realworld-upgrade-report.md`
- `m7-07-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m7_07_realworld_artifact.ps1`

## M7-08 Real-World Upgrade Assets

- `m7-08-realworld-upgrade-report.md`
- `m7-08-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m7_08_realworld_artifact.ps1`

## M7-09 Real-World Upgrade Assets

- `m7-09-realworld-upgrade-report.md`
- `m7-09-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m7_09_realworld_artifact.ps1`

## M7-10 Real-World Upgrade Assets

- `m7-10-realworld-upgrade-report.md`
- `m7-10-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m7_10_realworld_artifact.ps1`

## Sync

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing
```

Notes:
- Prune is enabled by default, so removed modular files are unpublished from backend and disappear from frontend listings after sync.
- Missing `source_file` paths are skipped by default during sync. Use `--strict-missing-source-files` if you want the command to fail instead.
