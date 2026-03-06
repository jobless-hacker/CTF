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
