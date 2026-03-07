# M9 Modular Challenge Definitions

Use this folder to keep M9 challenge content in separate JSON files so updates do not require editing the full seed.

## Current modular challenges

- `m9-01-image-metadata.json`
- `m9-02-suspicious-username.json`
- `m9-03-domain-investigation.json`
- `m9-04-document-metadata.json`
- `m9-05-website-archive.json`
- `m9-06-social-media-leak.json`
- `m9-07-hidden-image-info.json`
- `m9-08-email-exposure.json`
- `m9-09-subdomain-discovery.json`
- `m9-10-public-code-leak.json`

## M9-01 Real-World Upgrade Assets

- `m9-01-realworld-upgrade-report.md`
- `m9-01-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m9_01_realworld_artifact.ps1`

## M9-02 Real-World Upgrade Assets

- `m9-02-realworld-upgrade-report.md`
- `m9-02-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m9_02_realworld_artifact.ps1`

## M9-03 Real-World Upgrade Assets

- `m9-03-realworld-upgrade-report.md`
- `m9-03-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m9_03_realworld_artifact.ps1`

## M9-04 Real-World Upgrade Assets

- `m9-04-realworld-upgrade-report.md`
- `m9-04-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m9_04_realworld_artifact.ps1`

## M9-05 Real-World Upgrade Assets

- `m9-05-realworld-upgrade-report.md`
- `m9-05-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m9_05_realworld_artifact.ps1`

## M9-06 Real-World Upgrade Assets

- `m9-06-realworld-upgrade-report.md`
- `m9-06-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m9_06_realworld_artifact.ps1`

## M9-07 Real-World Upgrade Assets

- `m9-07-realworld-upgrade-report.md`
- `m9-07-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m9_07_realworld_artifact.ps1`

## M9-08 Real-World Upgrade Assets

- `m9-08-realworld-upgrade-report.md`
- `m9-08-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m9_08_realworld_artifact.ps1`

## M9-09 Real-World Upgrade Assets

- `m9-09-realworld-upgrade-report.md`
- `m9-09-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m9_09_realworld_artifact.ps1`

## M9-10 Real-World Upgrade Assets

- `m9-10-realworld-upgrade-report.md`
- `m9-10-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m9_10_realworld_artifact.ps1`

## Sync

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing
```

Notes:
- Prune is enabled by default, so removed modular files are unpublished from backend and disappear from frontend listings after sync.
- Missing `source_file` paths are skipped by default during sync. Use `--strict-missing-source-files` if you want the command to fail instead.
