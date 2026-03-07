# M10 Modular Challenge Definitions

Use this folder to keep M10 challenge content in separate JSON files so updates do not require editing the full seed.

## Current modular challenges

- `m10-01-suspicious-file-type.json`
- `m10-02-hidden-archive.json`
- `m10-03-image-metadata.json`
- `m10-04-timeline-event.json`
- `m10-05-base64-artifact.json`
- `m10-06-suspicious-executable.json`
- `m10-07-deleted-file-trace.json`
- `m10-08-hex-artifact.json`
- `m10-09-stego-image.json`
- `m10-10-forensic-report.json`

## M10-01 Real-World Upgrade Assets

- `m10-01-realworld-upgrade-report.md`
- `m10-01-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m10_01_realworld_artifact.ps1`

## M10-02 Real-World Upgrade Assets

- `m10-02-realworld-upgrade-report.md`
- `m10-02-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m10_02_realworld_artifact.ps1`

## M10-03 Real-World Upgrade Assets

- `m10-03-realworld-upgrade-report.md`
- `m10-03-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m10_03_realworld_artifact.ps1`

## M10-04 Real-World Upgrade Assets

- `m10-04-realworld-upgrade-report.md`
- `m10-04-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m10_04_realworld_artifact.ps1`

## M10-05 Real-World Upgrade Assets

- `m10-05-realworld-upgrade-report.md`
- `m10-05-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m10_05_realworld_artifact.ps1`

## M10-06 Real-World Upgrade Assets

- `m10-06-realworld-upgrade-report.md`
- `m10-06-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m10_06_realworld_artifact.ps1`

## M10-07 Real-World Upgrade Assets

- `m10-07-realworld-upgrade-report.md`
- `m10-07-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m10_07_realworld_artifact.ps1`

## M10-08 Real-World Upgrade Assets

- `m10-08-realworld-upgrade-report.md`
- `m10-08-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m10_08_realworld_artifact.ps1`

## M10-09 Real-World Upgrade Assets

- `m10-09-realworld-upgrade-report.md`
- `m10-09-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m10_09_realworld_artifact.ps1`

## M10-10 Real-World Upgrade Assets

- `m10-10-realworld-upgrade-report.md`
- `m10-10-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m10_10_realworld_artifact.ps1`

## Sync

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing
```

Notes:
- Prune is enabled by default, so removed modular files are unpublished from backend and disappear from frontend listings after sync.
- Missing `source_file` paths are skipped by default during sync. Use `--strict-missing-source-files` if you want the command to fail instead.
