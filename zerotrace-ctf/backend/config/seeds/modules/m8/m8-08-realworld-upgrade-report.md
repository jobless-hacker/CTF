# M8-08 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Misconfigured object storage policy using dangerous wildcard principal value.
- Task target: identify risky policy value.

### Learning Outcome
- Investigate storage policy risk across version history, simulation, audit, and runtime access evidence.
- Correlate policy change operations with effective access impact.
- Extract normalized risky policy value from security detections.

### Previous Artifact Weaknesses
- Single bucket policy JSON revealed answer instantly.
- No realistic cloud policy lifecycle or runtime impact evidence.
- Missing SOC/CloudSec detection and triage context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Bucket policy version history with posture state transitions.
2. Policy simulation outputs to validate effective permission impact.
3. CloudTrail policy-change event + object-access telemetry.
4. Policy audit, security alerts, and SIEM normalization.

### Key Signals Adopted
- Policy version log records `principal=*` violation.
- Policy simulation shows principal `*` allowed for object access.
- CloudTrail change event sets wildcard principal.
- Audit/alert/SIEM all normalize risky value as `*`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `bucket_policy_versions.log` (**7,101 lines**) policy baseline and one wildcard-principal violation.
- `policy_simulation.csv` (**5,602 lines**) simulation baseline + critical wildcard principal decision.
- `cloudtrail_events.jsonl` (**5,401 lines**) baseline control-plane events + `PutBucketPolicy` risky change.
- `object_access.log` (**6,201 lines**) object access baseline + anonymous access tied to wildcard policy.
- `policy_audit.log` (**5,101 lines**) policy control baseline + violation event.
- `storage_policy_alerts.jsonl` (**4,301 lines**) noisy alerts and critical risky value finding.
- `timeline_events.csv` (**5,004 lines**) SIEM correlation and risky value identification.
- `bucket_policy.json` direct raw policy artifact.
- `storage_policy_hardening_standard.txt` and `misconfigured_storage_policy_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-noise cloud policy telemetry requiring multi-source pivots.
- Connects policy misconfiguration to actual public data access behavior.
- Includes operational playbook and governance context.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5808`).
2. Identify wildcard candidate in raw policy + policy versions.
3. Confirm effective impact via simulation, CloudTrail change, and object access logs.
4. Validate policy audit + alert/SIEM normalized risky value.
5. Submit risky policy value.

Expected answer:
- `CTF{*}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m8/m8-08-misconfigured-storage-policy.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `principal=*`, `"Principal":"*"`, `risky_policy_value`, `PutBucketPolicy`, `risky_policy_value_identified`.
- Correlate policy-change, policy-effect, and detection streams before submission.
