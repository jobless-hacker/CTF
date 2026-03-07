# M1-11 Instructor Notes

## Objective
- Train learners to investigate public cloud-snapshot exposure with realistic governance telemetry.
- Expected answer: `CTF{confidentiality}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and identify target resource:
   - `customer-db-backup-2026-03-05`
2. Validate expected policy in `approved_sharing_baseline.json`.
3. Confirm change event in `cloudtrail_events.jsonl`:
   - `eventName=ModifyDBSnapshotAttribute`
   - `requestParameters.valuesToAdd=["all"]`
4. Verify current snapshot state in `snapshot_attributes_current.json` (`restore` includes `all`).
5. Correlate history in `snapshot_attribute_history.csv` (public-share event).
6. Cross-check detection context:
   - `governance_findings.csv` active high-severity finding
   - `access_analyzer_findings.jsonl` active public exposure finding
7. Filter sandbox false positives and conclude CIA impact.

## Key Indicators
- Snapshot ID: `customer-db-backup-2026-03-05`
- Risky value: `all` in `restore` attribute
- Change actor: `ops-admin`
- Event time: `2026-03-06T05:14:11Z`
- Baseline mismatch: production snapshots must not be public

## Suggested Commands / Tools
- `rg "customer-db-backup-2026-03-05|ModifyDBSnapshotAttribute|valuesToAdd|all" evidence`
- CSV filter by snapshot ID in:
  - `snapshot_inventory.csv`
  - `snapshot_attribute_history.csv`
  - `governance_findings.csv`
- `jq` filter CloudTrail and analyzer JSONL by resource ID and timestamp.
