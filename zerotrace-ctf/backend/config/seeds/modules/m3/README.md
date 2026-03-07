# M3 Modular Challenge Definitions

Use this folder to keep M3 challenge content in separate JSON files so updates do not require editing the full seed.

## Current modular challenges

- `m3-01-public-spreadsheet.json`
- `m3-02-github-credentials.json`
- `m3-03-misconfigured-storage.json`
- `m3-04-database-dump.json`
- `m3-05-pastebin-leak.json`
- `m3-06-internal-document.json`
- `m3-07-cloud-access-leak.json`
- `m3-08-log-file-exposure.json`
- `m3-09-archive-leak.json`
- `m3-10-web-backup-exposure.json`

## M3-01 Real-World Upgrade Assets

- `m3-01-realworld-upgrade-report.md`
- `m3-01-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m3_01_realworld_artifact.ps1`

## M3-02 Real-World Upgrade Assets

- `m3-02-realworld-upgrade-report.md`
- `m3-02-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m3_02_realworld_artifact.ps1`

## M3-03 Real-World Upgrade Assets

- `m3-03-realworld-upgrade-report.md`
- `m3-03-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m3_03_realworld_artifact.ps1`

## M3-04 Real-World Upgrade Assets

- `m3-04-realworld-upgrade-report.md`
- `m3-04-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m3_04_realworld_artifact.ps1`

## M3-05 Real-World Upgrade Assets

- `m3-05-realworld-upgrade-report.md`
- `m3-05-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m3_05_realworld_artifact.ps1`

## M3-06 Real-World Upgrade Assets

- `m3-06-realworld-upgrade-report.md`
- `m3-06-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m3_06_realworld_artifact.ps1`

## M3-07 Real-World Upgrade Assets

- `m3-07-realworld-upgrade-report.md`
- `m3-07-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m3_07_realworld_artifact.ps1`

## M3-08 Real-World Upgrade Assets

- `m3-08-realworld-upgrade-report.md`
- `m3-08-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m3_08_realworld_artifact.ps1`

## M3-09 Real-World Upgrade Assets

- `m3-09-realworld-upgrade-report.md`
- `m3-09-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m3_09_realworld_artifact.ps1`

## M3-10 Real-World Upgrade Assets

- `m3-10-realworld-upgrade-report.md`
- `m3-10-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m3_10_realworld_artifact.ps1`

## Sync

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing
```

Notes:
- Prune is enabled by default, so removed modular files are unpublished from backend and disappear from frontend listings after sync.
- Missing `source_file` paths are skipped by default during sync. Use `--strict-missing-source-files` if you want the command to fail instead.
