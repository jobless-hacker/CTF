# M2-08 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Insider-risk investigation for unauthorized confidential data access.
- Task target: identify the insider account that accessed payroll records.

### Learning Outcome
- Correlate audit portal activity, file access, DB queries, UEBA alerts, and identity/governance context.
- Validate access against approval registry and policy controls.
- Distinguish legitimate finance access from cross-department misuse.

### Previous Artifact Weaknesses
- Single short audit log with low realism.
- No supporting evidence from identity, governance, or multi-source telemetry.
- Minimal noise and weak SOC investigation depth.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Data from Information Repositories / Insider account misuse patterns:  
   https://attack.mitre.org/techniques/T1213/  
   https://attack.mitre.org/techniques/T1078/
2. NIST SP 800-61 incident handling for evidence collection/correlation:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. Enterprise insider-risk workflows combining UEBA + data-governance + access audit telemetry.

### Key Signals Adopted
- `alice` (marketing) accessed and exported `payroll/salary_records.xlsx`.
- File server and DB logs confirm payroll dataset retrieval under same user/time window.
- Approval registry explicitly marks request as `not_approved`.
- UEBA produces high/critical cross-department sensitive-access alerts.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `portal_audit.csv` (**10,804 lines**) payroll portal access telemetry.
- `fileserver_access.csv` (**7,604 lines**) file server operations.
- `db_query.log` (**6,202 lines**) payroll DB query trail.
- `ueba_alerts.jsonl` (**4,302 lines**) behavioral/security analytics.
- `timeline_events.csv` (**5,005 lines**) SIEM correlation sequence.
- `access_approval_registry.csv` (**3,302 lines**) governance approval context.
- `directory_context.csv` (**6 lines**) identity and department mapping.
- `payroll_data_access_policy.txt` (**4 lines**) policy baseline.
- Briefing files.

Realism upgrades:
- Multi-source SOC + governance evidence with high-volume noise.
- False positives and benign departmental access to force analysis depth.
- Practical insider-use case reflecting real audit and IR workflows.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and sensitive resource from briefing.
2. Identify suspicious user from portal audit around incident time.
3. Confirm same user in file server and DB query logs.
4. Validate department mismatch via directory context.
5. Confirm no approval in access registry and policy violation.
6. Confirm UEBA + SIEM escalation sequence.
7. Return insider account.

Expected answer:
- `CTF{alice}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m2/m2-08-internal-audit-trail.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `alice`, `salary_records.xlsx`, `not_approved`.
- CSV filtering by user/time in audit and approval datasets.
- `jq` extraction for high/critical UEBA signals.
