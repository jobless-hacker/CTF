# M7-09 Instructor Notes

## Objective
- Train learners to investigate insecure cookie configuration and identify the missing security flag.
- Expected answer: `CTF{httponly}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5709`
   - request id: `req-9927333`
2. In `gateway_access.log`, identify suspicious login flow event.
3. In `response_headers.log` and `http_headers.txt`, inspect Set-Cookie attributes.
4. In `browser_security_scan.csv`, confirm failed cookie hardening check.
5. In `session_config_audit.log`, verify profile-level hardening drift.
6. In `cookie_security_alerts.jsonl` and `timeline_events.csv`, use normalized missing flag indicator.
7. Submit missing cookie security flag.

## Key Indicators
- Request pivot:
  - `request_id=req-9927333`
- Header pivot:
  - `Set-Cookie ... Secure; SameSite=Lax` (without HttpOnly)
- Detection pivot:
  - `missing_cookie_flag=httponly`
- Scan/config pivot:
  - `result=fail, missing_flag=httponly`
  - `httponly=false ... missing_flag=httponly`
- SIEM pivot:
  - `missing_cookie_flag_identified ... httponly`

## Suggested Commands / Tools
- `rg "req-9927333|Set-Cookie|missing_flag=httponly|missing_cookie_flag_identified|httponly=false" evidence`
- Review:
  - `evidence/web/gateway_access.log`
  - `evidence/web/response_headers.log`
  - `evidence/web/http_headers.txt`
  - `evidence/web/browser_security_scan.csv`
  - `evidence/app/session_config_audit.log`
  - `evidence/security/cookie_security_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
