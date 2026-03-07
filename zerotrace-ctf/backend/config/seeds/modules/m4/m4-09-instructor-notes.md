# M4-09 Instructor Notes

## Objective
- Train learners to identify the exact backend service impacted during load balancer failure.
- Expected answer: `CTF{api01}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5416`
   - outage window near `2026-03-08 00:28 UTC`
2. In `lb_health_checks.csv`, locate repeated:
   - `backend server api01 unhealthy`
3. In `upstream_proxy.log`, confirm upstream errors for `api01` (`upstream_status=503`).
4. In `backend_probe_results.csv`, confirm probe failures for `api01`.
5. In `backend_pool_stats.csv`, confirm `api01` marked unhealthy with high error rate.
6. In `target_registration.log`, confirm `api01` removed from rotation.
7. In `lb_alerts.jsonl` and `timeline_events.csv`, confirm `affected_backend=api01`.
8. Submit `CTF{api01}`.

## Key Indicators
- Incident ID: `INC-2026-5416`
- LB marker: `backend server api01 unhealthy`
- Proxy marker: `upstream=api01` with 503
- Alert marker: `affected_backend = api01`
- SIEM marker: `backend_unhealthy`

## Suggested Commands / Tools
- `rg "api01|backend server api01 unhealthy|affected_backend|INC-2026-5416" evidence`
- CSV analysis in:
  - `lb_health_checks.csv`
  - `backend_pool_stats.csv`
  - `backend_probe_results.csv`
  - `timeline_events.csv`
- JSONL filtering in `lb_alerts.jsonl` for critical backend failures.
