# M2-05 Instructor Notes

## Objective
- Train learners to investigate after-hours exfiltration by correlating network, proxy, endpoint, DLP, policy, and SIEM evidence.
- Expected answer: `CTF{payroll.xlsx}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - host: `fin-wks-22`
   - user in context: `sarah.k`
   - destination: `198.51.100.7`
   - window: around `23:51 UTC`
2. In `netflow_egress.csv`, isolate large outbound sessions to unapproved external destination.
3. In `proxy_egress.log`, confirm upload requests and filename metadata.
4. In `file_access_audit.csv`, confirm same user accessed/copied/prepared the file immediately before upload.
5. In `dlp_alerts.jsonl`, confirm high/critical alerts and the exact file tied to restricted PII.
6. In `user_context.csv` and `data_egress_policy.txt`, verify privilege/policy mismatch.
7. In `timeline_events.csv`, confirm SIEM escalation sequence.
8. Return the exfiltrated filename.

## Key Indicators
- Destination: `198.51.100.7`
- User: `sarah.k`
- File: `payroll.xlsx`
- Policy signal: off-hours external transfer of restricted PII

## Suggested Commands / Tools
- `rg "198.51.100.7|sarah.k|payroll.xlsx|policy_violation|restricted-pii" evidence`
- CSV filtering in:
  - `netflow_egress.csv`
  - `file_access_audit.csv`
  - `timeline_events.csv`
- `jq` filtering for `severity == "high" or "critical"` in `dlp_alerts.jsonl`.
