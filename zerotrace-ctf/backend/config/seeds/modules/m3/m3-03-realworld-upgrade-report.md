# M3-03 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Cloud storage misconfiguration investigation for exposed restricted data.
- Task target: identify the exposed file containing payroll data.

### Learning Outcome
- Correlate object metadata, ACL changes, CloudTrail access, DLP signals, and export governance records.
- Distinguish multiple exposed files and select payroll-specific artifact.
- Investigate cloud-data exposure using SOC-style multi-source telemetry.

### Previous Artifact Weaknesses
- Single short bucket listing with direct answer path.
- No policy-change, access, or governance context.
- Low realism with no noise or timeline correlation.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Data from Cloud Storage Object and cloud exposure patterns:  
   https://attack.mitre.org/techniques/T1530/
2. NIST SP 800-61 incident analysis and evidence correlation model:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. Cloud security monitoring workflow: ACL change events + CloudTrail object access + DLP + SIEM.

### Key Signals Adopted
- Inventory shows `daily_exports/finance/payroll.xlsx` with `public-read`.
- Policy-change logs show manual ACL update by non-standard actor.
- CloudTrail confirms external `GetObject` requests for `payroll.xlsx`.
- Export audit marks payroll export as `not_approved`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `s3_object_inventory.csv` (**11,604 lines**) object metadata and ACL status.
- `bucket_policy_changes.jsonl` (**4,102 lines**) policy/ACL change events.
- `cloudtrail_getobject.jsonl` (**5,302 lines**) access telemetry.
- `dlp_storage_alerts.jsonl` (**3,902 lines**) data-protection detections.
- `export_job_audit.csv` (**3,202 lines**) export governance records.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression.
- `cloud_storage_policy.txt` (**4 lines**) policy baseline.
- Briefing files.

Realism upgrades:
- Full cloud incident evidence chain from misconfiguration to external access.
- High-volume benign telemetry with targeted critical events.
- Practical analyst workflow requiring correlation across cloud/app/security sources.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident window and affected prefix.
2. Identify publicly exposed finance objects in inventory.
3. Correlate ACL changes and non-approved export job.
4. Confirm external access through CloudTrail and SIEM.
5. Select object containing payroll data and return filename.

Expected answer:
- `CTF{payroll.xlsx}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m3/m3-03-misconfigured-storage.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `payroll.xlsx`, `public-read`, `not_approved`.
- CSV filtering in object inventory and export audits.
- `jq` filtering of high/critical DLP and policy-change events.
