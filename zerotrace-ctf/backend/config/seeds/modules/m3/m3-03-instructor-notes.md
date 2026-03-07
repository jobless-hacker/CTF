# M3-03 Instructor Notes

## Objective
- Train learners to investigate cloud misconfiguration incidents and identify exposed payroll artifacts.
- Expected answer: `CTF{payroll.xlsx}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - bucket: `corp-data-exports`
   - prefix: `daily_exports/finance/`
   - window: around `2026-03-07 10:14-10:16 UTC`
2. In `s3_object_inventory.csv`, find finance objects marked `public-read`.
3. In `bucket_policy_changes.jsonl`, confirm ACL changes and actor context.
4. In `export_job_audit.csv`, verify payroll export was `not_approved`.
5. In `cloudtrail_getobject.jsonl`, confirm external access for exposed payroll object.
6. In `dlp_storage_alerts.jsonl`, validate high/critical restricted-data alerts.
7. In `timeline_events.csv`, confirm event progression and incident opening.
8. Return the file containing payroll data.

## Key Indicators
- Exposed object: `daily_exports/finance/payroll.xlsx`
- ACL: `public-read`
- Governance mismatch: `not_approved`
- External access confirmed by CloudTrail + SIEM

## Suggested Commands / Tools
- `rg "payroll.xlsx|public-read|not_approved|external_object_access" evidence`
- CSV filtering in:
  - `s3_object_inventory.csv`
  - `export_job_audit.csv`
  - `timeline_events.csv`
- `jq` review for critical events in:
  - `bucket_policy_changes.jsonl`
  - `cloudtrail_getobject.jsonl`
  - `dlp_storage_alerts.jsonl`
