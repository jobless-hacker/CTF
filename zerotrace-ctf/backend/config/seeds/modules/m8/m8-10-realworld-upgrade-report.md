# M8-10 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Exposure of a full historical backup archive in cloud storage.
- Task target: identify the exact exposed full backup archive filename.

### Learning Outcome
- Investigate backup exposure incidents across inventory, access, and detection data.
- Correlate cloud evidence sources to confirm true exposure versus noise.
- Extract normalized archive indicator from SOC/CloudSec telemetry.

### Previous Artifact Weaknesses
- Single short artifact made the answer immediate.
- No realistic backup lifecycle, access telemetry, or detection noise.
- Missing incident triage context used in cloud investigations.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Backup inventory and catalog datasets with classification and retention metadata.
2. Object access + CloudTrail records to validate anonymous/public archive access.
3. Policy audit and alert pipelines for control violation correlation.
4. SIEM timeline normalization for final investigative confirmation.

### Key Signals Adopted
- `full_backup_2025.zip` appears as `full,true,public,critical` in catalog.
- Object access and CloudTrail include anonymous download/get-object for same file.
- Policy audit + alerts + SIEM normalize the exposed full backup archive indicator.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `backup_inventory.log` (**7,101 lines**) with one full-backup exposure event.
- `backup_catalog.csv` (**5,602 lines**) classification baseline plus critical public full archive row.
- `object_access.log` (**6,201 lines**) normal internal access plus anonymous public archive download.
- `cloudtrail_events.jsonl` (**5,401 lines**) baseline S3 reads plus anonymous `GetObject` for target.
- `backup_policy_audit.log` (**5,101 lines**) control pass noise and one policy violation for archive.
- `backup_archive_alerts.jsonl` (**4,301 lines**) noisy monitoring alerts plus critical exposure finding.
- `timeline_events.csv` (**5,004 lines**) SIEM correlation and final archive identification event.
- `cloud_backup.txt` direct low-fidelity artifact.
- Policy/runbook/intel + briefing files for realistic SOC handoff context.

Realism upgrades:
- High-volume noisy cloud telemetry with one true exposed archive path.
- Multiple evidence pivots required across cloud, security, and SIEM layers.
- Matches operational backup exposure investigations in cloud SOC workflows.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5810`).
2. Identify candidate full archive in inventory/catalog evidence.
3. Validate public exposure with object access and CloudTrail anonymous events.
4. Confirm policy violation and critical detection in alerts/SIEM timeline.
5. Submit exposed full backup archive filename.

Expected answer:
- `CTF{full_backup_2025.zip}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m8/m8-10-exposed-backup-archive.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `full_backup_2025.zip`, `full,true,public,critical`, `auth=anonymous`, `exposed_archive`, `full_backup_archive_identified`.
- Correlate cloud inventory/access and SOC detections before submission.
