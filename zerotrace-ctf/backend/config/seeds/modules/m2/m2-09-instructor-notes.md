# M2-09 Instructor Notes

## Objective
- Train learners to classify a web authentication exploit by correlating front-end request patterns with backend SQL behavior.
- Expected answer: `CTF{sqli}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - app host: `web-app-01`
   - auth service: `auth-service`
   - window: around `2026-03-07 16:12 UTC`
2. In `web_access.log`, identify suspicious login query patterns with tautology payloads.
3. In `raw_request_corpus.txt`, confirm exact payload structure (`' OR '1'='1`, `' OR 1=1--`).
4. In `waf_alerts.jsonl`, confirm SQL injection rule hits and severity.
5. In `auth_service.log`, confirm unexpected successful login linked to vulnerable legacy query builder.
6. In `db_audit.log`, confirm unsanitized string-concatenated SQL query caused by injected input.
7. In `timeline_events.csv`, validate end-to-end incident sequence.
8. Return the exploited vulnerability class.

## Key Indicators
- Payload patterns: `admin' OR '1'='1` and `' OR 1=1--`
- WAF rules: `SQL Injection Attack Detected`, `SQLi Authentication Bypass Pattern`
- Auth signal: bypass event tied to `legacy_query_builder`
- DB signal: injected predicate in login SQL

## Suggested Commands / Tools
- `rg "OR%20%271%27=%271|OR%201=1--|SQL Injection|legacy_query_builder|db_unsanitized_query" evidence`
- `jq` filtering for high/critical in `waf_alerts.jsonl`
- CSV/log timeline correlation in:
  - `web_access.log`
  - `auth_service.log`
  - `db_audit.log`
  - `timeline_events.csv`
