# M5 Modular Challenge Definitions

Use this folder to keep M5 challenge content in separate JSON files so updates do not require editing the full seed.

## Current modular challenges

- `m5-01-suspicious-user.json`
- `m5-02-ssh-login-trail.json`
- `m5-03-bash-history-review.json`
- `m5-04-cron-persistence.json`
- `m5-05-suid-binary.json`
- `m5-06-hidden-file.json`
- `m5-07-strange-process.json`
- `m5-08-suspicious-download.json`
- `m5-09-log-tampering.json`
- `m5-10-unauthorized-ssh-key.json`

## M5-01 Real-World Upgrade Assets

- `m5-01-realworld-upgrade-report.md`
- `m5-01-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m5_01_realworld_artifact.ps1`

## M5-02 Real-World Upgrade Assets

- `m5-02-realworld-upgrade-report.md`
- `m5-02-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m5_02_realworld_artifact.ps1`

## M5-03 Real-World Upgrade Assets

- `m5-03-realworld-upgrade-report.md`
- `m5-03-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m5_03_realworld_artifact.ps1`

## M5-04 Real-World Upgrade Assets

- `m5-04-realworld-upgrade-report.md`
- `m5-04-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m5_04_realworld_artifact.ps1`

## M5-05 Real-World Upgrade Assets

- `m5-05-realworld-upgrade-report.md`
- `m5-05-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m5_05_realworld_artifact.ps1`

## M5-06 Real-World Upgrade Assets

- `m5-06-realworld-upgrade-report.md`
- `m5-06-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m5_06_realworld_artifact.ps1`

## M5-07 Real-World Upgrade Assets

- `m5-07-realworld-upgrade-report.md`
- `m5-07-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m5_07_realworld_artifact.ps1`

## M5-08 Real-World Upgrade Assets

- `m5-08-realworld-upgrade-report.md`
- `m5-08-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m5_08_realworld_artifact.ps1`

## M5-09 Real-World Upgrade Assets

- `m5-09-realworld-upgrade-report.md`
- `m5-09-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m5_09_realworld_artifact.ps1`

## M5-10 Real-World Upgrade Assets

- `m5-10-realworld-upgrade-report.md`
- `m5-10-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m5_10_realworld_artifact.ps1`

## Sync

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing
```

Notes:
- Prune is enabled by default, so removed modular files are unpublished from backend and disappear from frontend listings after sync.
- Missing `source_file` paths are skipped by default during sync. Use `--strict-missing-source-files` if you want the command to fail instead.
