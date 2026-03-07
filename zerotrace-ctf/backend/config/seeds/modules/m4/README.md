# M4 Modular Challenge Definitions

Use this folder to keep M4 challenge content in separate JSON files so updates do not require editing the full seed.

## Current modular challenges

- `m4-01-web-server-crash.json`
- `m4-02-traffic-flood.json`
- `m4-03-disk-full.json`
- `m4-04-service-failure.json`
- `m4-05-database-overload.json`
- `m4-06-container-crash.json`
- `m4-07-kubernetes-restart-loop.json`
- `m4-08-dns-outage.json`
- `m4-09-load-balancer-failure.json`
- `m4-10-ransomware-lockdown.json`

## M4-01 Real-World Upgrade Assets

- `m4-01-realworld-upgrade-report.md`
- `m4-01-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m4_01_realworld_artifact.ps1`

## M4-02 Real-World Upgrade Assets

- `m4-02-realworld-upgrade-report.md`
- `m4-02-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m4_02_realworld_artifact.ps1`

## M4-03 Real-World Upgrade Assets

- `m4-03-realworld-upgrade-report.md`
- `m4-03-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m4_03_realworld_artifact.ps1`

## M4-04 Real-World Upgrade Assets

- `m4-04-realworld-upgrade-report.md`
- `m4-04-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m4_04_realworld_artifact.ps1`

## M4-05 Real-World Upgrade Assets

- `m4-05-realworld-upgrade-report.md`
- `m4-05-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m4_05_realworld_artifact.ps1`

## M4-06 Real-World Upgrade Assets

- `m4-06-realworld-upgrade-report.md`
- `m4-06-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m4_06_realworld_artifact.ps1`

## M4-07 Real-World Upgrade Assets

- `m4-07-realworld-upgrade-report.md`
- `m4-07-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m4_07_realworld_artifact.ps1`

## M4-08 Real-World Upgrade Assets

- `m4-08-realworld-upgrade-report.md`
- `m4-08-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m4_08_realworld_artifact.ps1`

## M4-09 Real-World Upgrade Assets

- `m4-09-realworld-upgrade-report.md`
- `m4-09-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m4_09_realworld_artifact.ps1`

## M4-10 Real-World Upgrade Assets

- `m4-10-realworld-upgrade-report.md`
- `m4-10-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m4_10_realworld_artifact.ps1`

## Sync

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing
```

Notes:
- Prune is enabled by default, so removed modular files are unpublished from backend and disappear from frontend listings after sync.
- Missing `source_file` paths are skipped by default during sync. Use `--strict-missing-source-files` if you want the command to fail instead.
