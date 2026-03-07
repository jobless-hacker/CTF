# M2-02 Instructor Notes

## Objective
- Train learners to classify a login-storm incident using SOC-style multi-source evidence.
- Expected answer: `CTF{bruteforce}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - account: `admin`
   - endpoint: `/api/v1/login`
   - window: around `2026-03-06T08:19Z`
2. In `failed_auth.log`, identify rapid repeated failures from one IP.
3. Confirm dictionary-like password guess sequence for same account/IP.
4. In `auth_api_attempts.csv`, verify high-rate repeated 401 responses.
5. In `waf_auth_alerts.jsonl`, find `AUTH_BRUTEFORCE_DETECTED` critical event.
6. In `account_lockouts.csv`, confirm hard lock after high failure count.
7. In `timeline_events.csv`, confirm SIEM attack classification sequence.
8. Use `source_context.csv` for context; then classify attack type.

## Key Indicators
- Source IP: `185.199.110.42`
- Repeated target: `admin`
- Pattern: rotating common passwords + high-frequency failures
- Control reaction: rate-limit + hard lockout

## Suggested Commands / Tools
- `rg "185.199.110.42|password_guess|AUTH_BRUTEFORCE_DETECTED|hard_lock|bruteforce_pattern_detected" evidence`
- CSV filtering in:
  - `auth_api_attempts.csv`
  - `account_lockouts.csv`
  - `timeline_events.csv`
- `jq` filtering by `severity == "critical"` in `waf_auth_alerts.jsonl`.
