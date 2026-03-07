# M5-01 Instructor Notes

## Objective
- Train learners to investigate unauthorized Linux account provisioning with SOC-style evidence correlation.
- Expected answer: `CTF{hacker}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5501`
   - host: `lin-prod-01`
2. In `user_change_audit.log`, find unauthorized account creation activity.
3. In `auth.log`, confirm first login and sudo usage by the same account.
4. In `identity_alerts.jsonl`, locate critical alert with `suspicious_user`.
5. In `passwd_snapshot.txt`, confirm account presence in host user database.
6. Submit the exact suspicious username.

## Key Indicators
- Incident ID: `INC-2026-5501`
- Unauthorized action: `action=useradd account=hacker`
- Authentication pivot: `Accepted password for hacker from 203.0.113.77`
- Privilege pivot: `sudo: hacker ... COMMAND=/bin/cat /etc/shadow`
- Alert pivot: `"type":"unauthorized_account_created"` and `"suspicious_user":"hacker"`

## Suggested Commands / Tools
- `rg "hacker|useradd account=|unauthorized_account_created|INC-2026-5501" evidence`
- Parse `identity_alerts.jsonl` with `jq`/grep style filters.
- Review timelines in:
  - `user_change_audit.log`
  - `auth.log`
  - `timeline_events.csv`
