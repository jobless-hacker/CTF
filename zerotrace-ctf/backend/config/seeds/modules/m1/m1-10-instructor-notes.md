# M1-10 Instructor Notes

## Objective
- Train learners to investigate failed disaster recovery due to corrupted backup data.
- Expected answer: `CTF{availability}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and capture incident pivots:
   - `backup_id`: `BK-126004`
   - `archive`: `customer-db-2026-03-05.tar.zst`
2. Validate backup metadata in `backup_catalog.csv`.
3. Check manifest and checksum signals:
   - expected digest from catalog/manifest
   - observed digest in `checksum_validation.csv`
4. Confirm restore failure sequence in `restore_controller.log`:
   - checksum mismatch
   - extraction failure (`Unexpected EOF`)
   - restore aborted
5. Correlate storage anomaly in `object_storage_audit.csv`.
6. Confirm user impact:
   - `service_recovery_status.csv` (`down` state)
   - `uptime_probes.csv` (`503` + timeout period)
7. Use `normalized_events.csv` to validate severity and timeline.
8. Classify CIA impact.

## Key Indicators
- Backup ID: `BK-126004`
- Expected checksum: `874b7c2e5f9f0a0e9b31a0e1946737ded3931314db4f4374c6d4cbf6ab0f8e5a`
- Observed checksum: `44b9fa4f8df3964b4888958037f1552cbd1c5c93d6aa6d9cf6e7db5b6f2fdc8a`
- Restore error: `Unexpected EOF in archive`
- Service impact: prolonged downtime during recovery window

## Suggested Commands / Tools
- `rg "BK-126004|customer-db-2026-03-05|checksum mismatch|Unexpected EOF" evidence`
- CSV filter by `backup_id` and incident timestamps across:
  - `backup_catalog.csv`
  - `checksum_validation.csv`
  - `object_storage_audit.csv`
  - `service_recovery_status.csv`
- `jq` filter manifest entries in `backup_manifest_records.jsonl`.
