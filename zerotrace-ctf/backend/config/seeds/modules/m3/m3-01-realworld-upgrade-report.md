# M3-01 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Public data exposure investigation for leaked customer contact spreadsheet.
- Task target: identify Bob's email from leaked dataset evidence.

### Learning Outcome
- Correlate cloud exposure events, data-access logs, DLP alerts, and leaked content.
- Validate exposure context through export audit and policy baseline.
- Extract required PII element from a realistic, noisy leaked dataset.

### Previous Artifact Weaknesses
- Single tiny spreadsheet file with direct low-effort extraction.
- No incident context or telemetry around how data became public.
- No SOC/DFIR-style evidence chain.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Data from Cloud Storage Object and collection/exposure patterns:  
   https://attack.mitre.org/techniques/T1530/  
   https://attack.mitre.org/techniques/T1537/
2. NIST SP 800-61 incident handling (triage, analysis, containment context):  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. Cloud data-leak workflows combining storage ACL monitoring, DLP alerts, and access-log correlation.

### Key Signals Adopted
- Object listing shows `customer_contacts_snapshot.csv` with `public-read` ACL.
- Public share access log shows external bulk downloads.
- DLP flags restricted contact dataset exposure.
- CRM export audit marks public destination as `not_approved`.
- Leaked dataset row for Bob contains `bob@company.com`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `customer_contacts_snapshot.csv` (**12,804 lines**) leaked contact dataset.
- `object_listing.csv` (**9,202 lines**) cloud object inventory and ACL context.
- `public_share_access.log` (**6,802 lines**) share retrieval telemetry.
- `dlp_exposure_alerts.jsonl` (**4,202 lines**) data-protection alerts.
- `crm_export_audit.csv` (**3,302 lines**) export governance evidence.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression.
- `customer_data_policy.txt` (**4 lines**) policy baseline.
- Briefing files.

Realism upgrades:
- Multi-source investigation evidence with significant operational noise.
- Event timeline from export to public exposure to external download.
- Practical data-protection incident format, not just static CSV lookup.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and leaked object name.
2. Confirm public ACL and external download evidence.
3. Validate export control violation in audit records.
4. Inspect leaked contact snapshot and locate Bob's entry.
5. Return Bob's email as flag value.

Expected answer:
- `CTF{bob@company.com}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m3/m3-01-public-spreadsheet.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `customer_contacts_snapshot.csv`, `public-read`, `not_approved`, `bob@company.com`.
- CSV filtering for target name/email extraction.
- `jq` filtering of critical DLP exposure alerts.
