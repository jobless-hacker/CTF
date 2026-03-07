# M8-03 Instructor Notes

## Objective
- Train learners to investigate public database snapshot exposure in cloud environments.
- Expected answer: `CTF{db-backup}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5803`
2. In `snapshot_inventory.log` and `snapshot.json`, identify public snapshot candidate.
3. In `rds_api.log`, locate permission-change action for snapshot restore attribute.
4. In `cloudtrail_events.jsonl`, confirm control-plane event and added public permission.
5. In `snapshot_policy_audit.log`, verify policy control violation.
6. In `public_snapshot_alerts.jsonl` and `timeline_events.csv`, extract normalized exposed snapshot ID.
7. Submit exposed resource identifier.

## Key Indicators
- Snapshot pivot:
  - `snapshot=db-backup`
- API pivot:
  - `action=ModifyDBSnapshotAttribute ... value=all`
- CloudTrail pivot:
  - `"dBSnapshotIdentifier":"db-backup"`
  - `"valuesToAdd":["all"]`
  - `"publicSnapshot":true`
- Policy pivot:
  - `status=violation ... snapshot=db-backup`
- Alert/SIEM pivot:
  - `"snapshot_id":"db-backup"`
  - `exposed_resource_identified ... db-backup`

## Suggested Commands / Tools
- `rg "db-backup|ModifyDBSnapshotAttribute|valuesToAdd|publicSnapshot|snapshot_id|exposed_resource_identified" evidence`
- Review:
  - `evidence/cloud/snapshot_inventory.log`
  - `evidence/cloud/snapshot.json`
  - `evidence/cloud/rds_api.log`
  - `evidence/cloud/cloudtrail_events.jsonl`
  - `evidence/cloud/snapshot_policy_audit.log`
  - `evidence/security/public_snapshot_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
