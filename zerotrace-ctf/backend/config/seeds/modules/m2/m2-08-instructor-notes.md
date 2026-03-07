# M2-08 Instructor Notes

## Objective
- Train learners to identify insider misuse by correlating audit, identity, governance, and UEBA evidence.
- Expected answer: `CTF{alice}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - host: `payroll-portal-01`
   - window: around `2026-03-07 15:41 UTC`
   - sensitive resource: `payroll/salary_records.xlsx`
2. In `portal_audit.csv`, find cross-department access/export activity on payroll resource.
3. In `fileserver_access.csv`, confirm matching file operations by same account.
4. In `db_query.log`, confirm payroll queries for salary records by same account.
5. In `directory_context.csv`, verify account department is not authorized for payroll.
6. In `access_approval_registry.csv`, confirm no valid approval (`not_approved`).
7. In `ueba_alerts.jsonl`, confirm high/critical insider-risk signals.
8. In `timeline_events.csv`, confirm end-to-end escalation and return insider account.

## Key Indicators
- User: `alice`
- Department mismatch: `marketing` accessing payroll data
- Sensitive file/resource: `payroll/salary_records.xlsx`
- Governance mismatch: request status `not_approved`
- UEBA/SIEM critical escalation sequence

## Suggested Commands / Tools
- `rg "alice|salary_records.xlsx|not_approved|cross_department_access|insider_risk_alert" evidence`
- CSV filtering in:
  - `portal_audit.csv`
  - `fileserver_access.csv`
  - `access_approval_registry.csv`
  - `timeline_events.csv`
- `jq` filtering for `severity=="high"` or `severity=="critical"` in `ueba_alerts.jsonl`.
