# M3-04 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Investigation of leaked authentication SQL dump and credential exposure.
- Task target: identify the leaked admin password.

### Learning Outcome
- Correlate leaked data content with cloud exposure events and external access telemetry.
- Validate incident through DLP, SIEM, and backup governance records.
- Extract a sensitive credential from realistic forensic artifacts.

### Previous Artifact Weaknesses
- Minimal SQL sample with near-direct answer visibility.
- No context of how dump leaked or was accessed.
- No multi-source SOC/DFIR evidence chain.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Credentials in Files and data exposure in cloud/object stores:  
   https://attack.mitre.org/techniques/T1552/001/  
   https://attack.mitre.org/techniques/T1530/
2. NIST SP 800-61 incident handling and evidence correlation:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. Cloud leak triage workflow: ACL change + object access logs + DLP + SIEM.

### Key Signals Adopted
- Leaked SQL file `users_dump_2026_03_07.sql` set to `public-read`.
- External object retrieval from non-corporate IP.
- DLP confirms plaintext credential content in exposed dump.
- SQL data row reveals admin password `AdminPass!`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `users_dump_2026_03_07.sql` (**12,211 lines**) leaked auth dump content.
- `backup_catalog.csv` (**8,402 lines**) backup inventory/governance metadata.
- `public_object_access.log` (**7,302 lines**) object retrieval telemetry.
- `acl_change_events.jsonl` (**4,101 lines**) exposure-causing ACL events.
- `dlp_dump_alerts.jsonl` (**3,802 lines**) data-loss detections.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression.
- `db_backup_security_policy.txt` (**4 lines**) control baseline.
- Briefing files.

Realism upgrades:
- End-to-end leak narrative from ACL misconfiguration to external exfiltration.
- High-volume benign background records with targeted critical sequence.
- Practical forensic workflow across data, cloud, and security telemetry.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident ticket and identify leaked object.
2. Confirm ACL exposure and external access events.
3. Validate DLP and SIEM correlation.
4. Inspect leaked SQL dump rows for admin credential.
5. Return admin password value.

Expected answer:
- `CTF{AdminPass!}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m3/m3-04-database-dump.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `users_dump_2026_03_07.sql`, `public-read`, `AdminPass!`.
- JSONL filtering for critical DLP/ACL events.
- SQL dump grep/filter for admin record extraction.
