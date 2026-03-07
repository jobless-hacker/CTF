# M3-08 Instructor Notes

## Objective
- Train learners to investigate log-based sensitive token exposure in a production environment.
- Expected answer: `CTF{9f8a7b6c}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5211`
   - window around `2026-03-07 14:22-14:23 UTC`
2. Inspect `logging_runtime.conf` and identify risky setting (`enable_raw_request_dump=true`).
3. In `app_server.log`, pivot on `raw-request-dump` and extract token from Authorization header capture.
4. In `api_gateway_requests.csv`, confirm same token appears in correlated request record.
5. In `waf_alerts.csv`, verify high-severity token leakage alert for same value/IP.
6. In `trace_events.jsonl`, validate observability error containing exposed token field.
7. In `timeline_events.csv`, confirm SIEM sequence and incident opening.
8. Submit exact token value in `CTF{...}` format.

## Key Indicators
- Incident ID: `INC-2026-5211`
- Logging issue: `enable_raw_request_dump=true`
- Token leak pivot: `9f8a7b6c`
- Correlated source IP: `185.199.110.42`
- SIEM marker: `token_exposed_in_logs`

## Suggested Commands / Tools
- `rg "9f8a7b6c|raw-request-dump|INC-2026-5211|token_exposed_in_logs|185.199.110.42" evidence`
- CSV analysis in:
  - `api_gateway_requests.csv`
  - `waf_alerts.csv`
  - `timeline_events.csv`
- JSONL filtering in `trace_events.jsonl` for `exposed_token`.
