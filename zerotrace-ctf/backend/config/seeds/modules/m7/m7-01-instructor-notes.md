# M7-01 Instructor Notes

## Objective
- Train learners to classify a suspicious login attack using multi-source web evidence.
- Expected answer: `CTF{sqli}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5701`
   - endpoint: `/login`
2. In `access.log`, locate crafted login parameter payload with SQL tautology marker.
3. In `waf.log`, verify SQL injection detection trigger (`rule=942100`).
4. In `auth_service.log`, validate suspicious username/query parameter behavior.
5. In `query_audit.log`, confirm backend raw query shows SQL tautology pattern.
6. In `web_attack_alerts.jsonl` and `timeline_events.csv`, extract final attack vector classification.
7. Submit vulnerability class.

## Key Indicators
- Access pivot:
  - `/login?user=admin'+OR+'1'='1&pass=test`
- WAF pivot:
  - `rule=942100 ... SQL Injection Attack Detected`
- DB pivot:
  - `username='admin' OR '1'='1'`
- Alert pivot:
  - `"type":"auth_bypass_attempt_detected","attack_vector":"sqli"`
- SIEM pivot:
  - `vulnerability_classified ... sqli`

## Suggested Commands / Tools
- `rg "OR\\+'1'='1|942100|attack_vector|vulnerability_classified|sqli" evidence`
- Review:
  - `evidence/network/access.log`
  - `evidence/network/waf.log`
  - `evidence/application/auth_service.log`
  - `evidence/database/query_audit.log`
  - `evidence/security/web_attack_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
