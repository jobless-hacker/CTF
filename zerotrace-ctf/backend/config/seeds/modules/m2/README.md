# M2 Modular Challenge Definitions

Use this folder to keep M2 challenge content in separate JSON files so updates do not require editing the full seed.

## Current modular challenges

- `m2-01-after-hours-access.json`
- `m2-02-login-storm.json`
- `m2-03-unknown-process.json`
- `m2-04-unexpected-sudo-activity.json`
- `m2-05-midnight-upload.json`
- `m2-06-new-admin-session.json`
- `m2-07-unusual-web-request.json`
- `m2-08-internal-audit-trail.json`
- `m2-09-strange-request-pattern.json`
- `m2-10-shell-history-review.json`

## M2-01 Real-World Upgrade Assets

- `m2-01-realworld-upgrade-report.md`
- `m2-01-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m2_01_realworld_artifact.ps1`

## M2-02 Real-World Upgrade Assets

- `m2-02-realworld-upgrade-report.md`
- `m2-02-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m2_02_realworld_artifact.ps1`

## M2-03 Real-World Upgrade Assets

- `m2-03-realworld-upgrade-report.md`
- `m2-03-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m2_03_realworld_artifact.ps1`

## M2-04 Real-World Upgrade Assets

- `m2-04-realworld-upgrade-report.md`
- `m2-04-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m2_04_realworld_artifact.ps1`

## M2-05 Real-World Upgrade Assets

- `m2-05-realworld-upgrade-report.md`
- `m2-05-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m2_05_realworld_artifact.ps1`

## M2-06 Real-World Upgrade Assets

- `m2-06-realworld-upgrade-report.md`
- `m2-06-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m2_06_realworld_artifact.ps1`

## M2-07 Real-World Upgrade Assets

- `m2-07-realworld-upgrade-report.md`
- `m2-07-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m2_07_realworld_artifact.ps1`

## M2-08 Real-World Upgrade Assets

- `m2-08-realworld-upgrade-report.md`
- `m2-08-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m2_08_realworld_artifact.ps1`

## M2-09 Real-World Upgrade Assets

- `m2-09-realworld-upgrade-report.md`
- `m2-09-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m2_09_realworld_artifact.ps1`

## M2-10 Real-World Upgrade Assets

- `m2-10-realworld-upgrade-report.md`
- `m2-10-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m2_10_realworld_artifact.ps1`

## Sync

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing
```

Notes:
- Prune is enabled by default, so removed modular files are unpublished from backend and disappear from frontend listings after sync.
- Missing `source_file` paths are skipped by default during sync. Use `--strict-missing-source-files` if you want the command to fail instead.
