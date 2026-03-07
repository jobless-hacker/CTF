# M8-03 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Public exposure of cloud database snapshot via permissive restore settings.
- Task target: identify exposed snapshot resource ID.

### Learning Outcome
- Analyze snapshot exposure through inventory, API, CloudTrail, and policy data.
- Correlate change events with security detections and SIEM normalization.
- Extract final exposed resource identifier used in incident response.

### Previous Artifact Weaknesses
- Single snapshot metadata file gave immediate answer.
- No realistic cloud control-plane investigation workflow.
- Missing API/policy/alert timeline context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Snapshot inventory telemetry for baseline visibility state.
2. RDS API logs and CloudTrail events for permission-change operations.
3. Snapshot policy audits detecting public restore misconfiguration.
4. Alert stream and SIEM timeline for normalized exposed resource naming.

### Key Signals Adopted
- Snapshot `db-backup` appears with `visibility=public`.
- API and CloudTrail show `ModifyDBSnapshotAttribute` adding `restore=all`.
- Policy/aalert/SIEM converge on exposed resource `db-backup`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `snapshot_inventory.log` (**7,101 lines**) noisy inventory baseline with one public snapshot event.
- `rds_api.log` (**5,601 lines**) API activity stream with public restore change operation.
- `cloudtrail_events.jsonl` (**5,401 lines**) control-plane event stream with exposed snapshot signal.
- `snapshot_policy_audit.log` (**5,101 lines**) policy baseline and one violation entry.
- `public_snapshot_alerts.jsonl` (**4,301 lines**) noisy alerts and one critical exposure event.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression and final resource identification.
- `snapshot.json` direct metadata artifact.
- `database_snapshot_exposure_policy.txt` and `public_snapshot_exposure_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-volume cloud telemetry with a single actionable misconfiguration.
- Requires cross-correlation between inventory, control-plane logs, and detections.
- Includes SOC/CloudSec incident process context.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5803`).
2. Identify candidate public snapshot in inventory/metadata artifacts.
3. Confirm permission change in RDS API and CloudTrail evidence.
4. Validate policy violation and alert/SIEM normalized snapshot ID.
5. Submit exposed resource ID.

Expected answer:
- `CTF{db-backup}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m8/m8-03-public-database-snapshot.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `db-backup`, `ModifyDBSnapshotAttribute`, `valuesToAdd`, `publicSnapshot`, `snapshot_id`, `exposed_resource_identified`.
- Correlate inventory/api/policy/security evidence before submitting.
