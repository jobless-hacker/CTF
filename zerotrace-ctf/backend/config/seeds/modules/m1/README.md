# M1 Modular Challenge Definitions

Use this folder to keep M1 challenge content in separate JSON files so updates do not require editing the full seed.

## Current modular challenge

- `m1-01-public-bucket-exposure.json`
- `m1-02-sniffed-credentials.json`
- `m1-03-modified-database-record.json`
- `m1-04-deleted-logs.json`
- `m1-05-web-server-crash.json`
- `m1-06-github-secret-leak.json`
- `m1-07-mis-sent-email.json`
- `m1-08-config-file-tampering.json`
- `m1-09-firewall-ddos-alert.json`
- `m1-10-backup-corruption.json`
- `m1-11-aws-public-snapshot.json`
- `m1-12-packet-replay-attack.json`
- `m1-13-siem-alert-investigation.json`
- `m1-14-docker-misconfiguration.json`
- `m1-15-ransomware-lock.json`
- `m1-16-api-data-exposure.json`
- `m1-17-unauthorized-git-commit.json`
- `m1-18-cloudtrail-incident.json`
- `m1-19-kubernetes-crash.json`
- `m1-20-dns-amplification-attack.json`
- `m1-21-modularity-test-challenge.json`

## M1-01 Real-World Upgrade Assets

- `m1-01-realworld-upgrade-report.md`
- `m1-01-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_01_realworld_artifact.ps1`

## M1-02 Real-World Upgrade Assets

- `m1-02-realworld-upgrade-report.md`
- `m1-02-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_02_realworld_artifact.ps1`

## M1-03 Real-World Upgrade Assets

- `m1-03-realworld-upgrade-report.md`
- `m1-03-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_03_realworld_artifact.ps1`

## M1-04 Real-World Upgrade Assets

- `m1-04-realworld-upgrade-report.md`
- `m1-04-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_04_realworld_artifact.ps1`

## M1-05 Real-World Upgrade Assets

- `m1-05-realworld-upgrade-report.md`
- `m1-05-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_05_realworld_artifact.ps1`

## M1-06 Real-World Upgrade Assets

- `m1-06-realworld-upgrade-report.md`
- `m1-06-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_06_realworld_artifact.ps1`

## M1-07 Real-World Upgrade Assets

- `m1-07-realworld-upgrade-report.md`
- `m1-07-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_07_realworld_artifact.ps1`

## M1-08 Real-World Upgrade Assets

- `m1-08-realworld-upgrade-report.md`
- `m1-08-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_08_realworld_artifact.ps1`

## M1-09 Real-World Upgrade Assets

- `m1-09-realworld-upgrade-report.md`
- `m1-09-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_09_realworld_artifact.ps1`

## M1-10 Real-World Upgrade Assets

- `m1-10-realworld-upgrade-report.md`
- `m1-10-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_10_realworld_artifact.ps1`

## M1-11 Real-World Upgrade Assets

- `m1-11-realworld-upgrade-report.md`
- `m1-11-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_11_realworld_artifact.ps1`

## M1-12 Real-World Upgrade Assets

- `m1-12-realworld-upgrade-report.md`
- `m1-12-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_12_realworld_artifact.ps1`

## M1-13 Real-World Upgrade Assets

- `m1-13-realworld-upgrade-report.md`
- `m1-13-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_13_realworld_artifact.ps1`

## M1-14 Real-World Upgrade Assets

- `m1-14-realworld-upgrade-report.md`
- `m1-14-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_14_realworld_artifact.ps1`

## M1-15 Real-World Upgrade Assets

- `m1-15-realworld-upgrade-report.md`
- `m1-15-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_15_realworld_artifact.ps1`

## M1-16 Real-World Upgrade Assets

- `m1-16-realworld-upgrade-report.md`
- `m1-16-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_16_realworld_artifact.ps1`

## M1-17 Real-World Upgrade Assets

- `m1-17-realworld-upgrade-report.md`
- `m1-17-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_17_realworld_artifact.ps1`

## M1-18 Real-World Upgrade Assets

- `m1-18-realworld-upgrade-report.md`
- `m1-18-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_18_realworld_artifact.ps1`

## M1-19 Real-World Upgrade Assets

- `m1-19-realworld-upgrade-report.md`
- `m1-19-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_19_realworld_artifact.ps1`

## M1-20 Real-World Upgrade Assets

- `m1-20-realworld-upgrade-report.md`
- `m1-20-instructor-notes.md`
- Artifact generator: `backend/scripts/build_m1_20_realworld_artifact.ps1`

## How to migrate next challenges

1. Copy one challenge object from `foundations-challenge-todo.seed.json` into a new file here.
2. Replace that challenge object in the seed with:

```json
{
  "source_file": "modules/m1/<your-file-name>.json"
}
```

3. Run a dry-run seed:

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing --dry-run
```

4. Apply sync:

```bash
python scripts/seed_intro_cybersecurity_track.py --seed-file config/seeds/foundations-challenge-todo.seed.json --flags-file config/seeds/private-flags.json --update-existing
```

Notes:
- Prune is enabled by default, so removed modular files are unpublished from backend and disappear from frontend listings after sync.
- Missing `source_file` paths are skipped by default during sync. Use `--strict-missing-source-files` if you want the command to fail instead.
- If backend auto-watch is enabled (`SEED_SYNC_WATCH_ENABLED=true`), file changes under `config/seeds/modules/` trigger sync automatically.
