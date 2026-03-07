# M8 Modular Challenge Definitions

Use this folder to keep M8 challenge content in separate JSON files so updates do not require editing the full seed.

## Current modular challenges

- `m8-01-public-storage-bucket.json`
- `m8-02-leaked-cloud-credentials.json`
- `m8-03-public-database-snapshot.json`
- `m8-04-overprivileged-iam-role.json`
- `m8-05-exposed-api-key.json`
- `m8-06-suspicious-cloudtrail-event.json`
- `m8-07-open-security-group.json`
- `m8-08-misconfigured-storage-policy.json`
- `m8-09-compromised-access-token.json`
- `m8-10-exposed-backup-archive.json`

## M8-01 Real-World Upgrade Assets

- `m8-01-realworld-upgrade-report.md`
- `m8-01-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m8_01_realworld_artifact.ps1`

## M8-02 Real-World Upgrade Assets

- `m8-02-realworld-upgrade-report.md`
- `m8-02-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m8_02_realworld_artifact.ps1`

## M8-03 Real-World Upgrade Assets

- `m8-03-realworld-upgrade-report.md`
- `m8-03-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m8_03_realworld_artifact.ps1`

## M8-04 Real-World Upgrade Assets

- `m8-04-realworld-upgrade-report.md`
- `m8-04-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m8_04_realworld_artifact.ps1`

## M8-05 Real-World Upgrade Assets

- `m8-05-realworld-upgrade-report.md`
- `m8-05-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m8_05_realworld_artifact.ps1`

## M8-06 Real-World Upgrade Assets

- `m8-06-realworld-upgrade-report.md`
- `m8-06-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m8_06_realworld_artifact.ps1`

## M8-07 Real-World Upgrade Assets

- `m8-07-realworld-upgrade-report.md`
- `m8-07-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m8_07_realworld_artifact.ps1`

## M8-08 Real-World Upgrade Assets

- `m8-08-realworld-upgrade-report.md`
- `m8-08-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m8_08_realworld_artifact.ps1`

## M8-09 Real-World Upgrade Assets

- `m8-09-realworld-upgrade-report.md`
- `m8-09-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m8_09_realworld_artifact.ps1`

## M8-10 Real-World Upgrade Assets

- `m8-10-realworld-upgrade-report.md`
- `m8-10-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m8_10_realworld_artifact.ps1`

## Sync

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing
```

Notes:
- Prune is enabled by default, so removed modular files are unpublished from backend and disappear from frontend listings after sync.
- Missing `source_file` paths are skipped by default during sync. Use `--strict-missing-source-files` if you want the command to fail instead.
