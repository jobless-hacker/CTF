# M8-09 Instructor Notes

## Objective
- Train learners to investigate compromised access token incidents in cloud API environments.
- Expected answer: `CTF{abc123xyz}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5809`
   - service: `api-gateway`
2. In `token_audit.log` and `access_log.txt`, identify exposed token candidate.
3. In `api_access.log`, verify suspicious external request carrying token.
4. In `token_introspection.jsonl`, confirm token exposure and risk classification.
5. In `session_activity.csv`, confirm blocked suspicious session tied to token.
6. In `token_exposure_alerts.jsonl` and `timeline_events.csv`, extract normalized exposed token.
7. Submit exposed token value.

## Key Indicators
- Token pivot:
  - `token=abc123xyz`
  - `exposure=yes`
- API/session pivot:
  - `auth_token=abc123xyz`
  - `token_ref=abc123xyz ... blocked,critical`
- Detection pivot:
  - `"exposed_token":"abc123xyz"`
  - `"leaked_token":"abc123xyz"`
- SIEM pivot:
  - `exposed_token_identified ... abc123xyz`

## Suggested Commands / Tools
- `rg "abc123xyz|exposure=yes|auth_token=|exposed_token|leaked_token|exposed_token_identified" evidence`
- Review:
  - `evidence/cloud/token_audit.log`
  - `evidence/cloud/access_log.txt`
  - `evidence/cloud/api_access.log`
  - `evidence/cloud/token_introspection.jsonl`
  - `evidence/cloud/session_activity.csv`
  - `evidence/security/token_exposure_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
