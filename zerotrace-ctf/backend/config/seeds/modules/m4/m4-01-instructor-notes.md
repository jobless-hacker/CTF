# M4-01 Instructor Notes

## Objective
- Train learners to investigate real-world web outage artifacts and identify the user-facing HTTP error code.
- Expected answer: `CTF{503}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5301`
   - outage window around `2026-03-07 17:42 UTC`
2. In `nginx_error.log`, locate critical outage lines:
   - `worker_connections are not enough`
   - generated response `503 Service Unavailable`
3. In `web_status_timeseries.csv`, confirm spike in `status_503`.
4. In `lb_health_checks.csv`, confirm unhealthy backend with HTTP 503.
5. In `host_resource_metrics.csv`, validate saturation (high connections/open_fds/listen_queue).
6. In `ops_alerts.jsonl`, find critical alert with `http_error: 503`.
7. In `timeline_events.csv`, confirm SIEM correlation and incident opening.
8. Submit outage code as `CTF{503}`.

## Key Indicators
- Incident ID: `INC-2026-5301`
- Outage marker: `503 Service Unavailable`
- Correlated source context: `185.199.110.42` in error flow
- SIEM event: `web_service_unavailable`
- LB evidence: unhealthy targets returning `503`

## Suggested Commands / Tools
- `rg "503 Service Unavailable|final_status=503|INC-2026-5301|worker_connections are not enough" evidence`
- CSV analysis in:
  - `web_status_timeseries.csv`
  - `lb_health_checks.csv`
  - `host_resource_metrics.csv`
  - `timeline_events.csv`
- JSONL filtering in `ops_alerts.jsonl` for `severity=critical`.
