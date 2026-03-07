# M8-01 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Public cloud storage exposure of a sensitive payroll file.
- Task target: identify the exposed sensitive payroll object filename.

### Learning Outcome
- Investigate cloud object exposure through inventory, access, and policy telemetry.
- Correlate object-level evidence across storage, CloudTrail, and SOC pipelines.
- Extract normalized sensitive filename used for containment.

### Previous Artifact Weaknesses
- Single bucket listing file made answer immediate.
- No realistic cloud telemetry or access validation workflow.
- Missing policy/audit/SIEM evidence expected in real CloudSec incidents.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Bucket listing snapshots and object inventory records for object discovery.
2. S3 access logs and CloudTrail events for anonymous/public access confirmation.
3. Bucket policy audit signals for principal/action misconfiguration.
4. Security alert stream and SIEM timeline for normalized exposed object naming.

### Key Signals Adopted
- `payroll.xlsx` appears in listing snapshot and object inventory.
- Anonymous `GetObject` access to `payroll.xlsx`.
- Policy audit violation with public principal and object scope.
- Security/SIEM normalize exposed object as `payroll.xlsx`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `bucket_object_inventory.log` (**7,101 lines**) noisy inventory baseline with one restricted sensitive object.
- `bucket_listing_snapshot.txt` realistic CLI listing output with exposed object.
- `object_access.log` (**6,201 lines**) storage access baseline plus anonymous sensitive object retrieval.
- `cloudtrail_events.jsonl` (**5,401 lines**) cloud event stream with one anonymous sensitive read event.
- `bucket_policy_audit.log` (**5,101 lines**) policy baseline and one public-read violation.
- `storage_exposure_alerts.jsonl` (**4,301 lines**) noisy alert stream with critical sensitive object exposure.
- `timeline_events.csv` (**5,004 lines**) SIEM correlation and final object identification.
- `cloud_storage_exposure_policy.txt` and `public_bucket_exposure_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-volume cloud telemetry requiring object-name pivoting.
- Multi-source cloud + security correlation before final answer.
- Includes incident handling context (ticket, runbook, policy).

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5801`) and target bucket.
2. Identify candidate sensitive object from listing and inventory.
3. Confirm public/anonymous access via access logs and CloudTrail.
4. Validate policy violation and alert/SIEM normalized object field.
5. Submit exposed sensitive payroll filename.

Expected answer:
- `CTF{payroll.xlsx}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m8/m8-01-public-storage-bucket.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `payroll.xlsx`, `auth=anonymous`, `"type":"Anonymous"`, `exposed_object`, `exposed_sensitive_file_identified`.
- Correlate listing/access/policy/alert signals to confirm final answer.
