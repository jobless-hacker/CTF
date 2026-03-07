# M1-05 Instructor Notes

## Objective
- Train learners to investigate a realistic web-service outage and map impact to CIA.
- Expected answer: `CTF{availability}`.

## Expected Investigation Path
1. Start with `incident_ticket.txt` to establish outage window.
2. Verify user-facing impact in `nginx_access.log` (`503` burst and latency increase).
3. Confirm web-tier pressure in `nginx_error.log` (`worker_connections are not enough`).
4. Use `nginx_stub_status_timeseries.csv` to spot saturation (`accepts > handled`, high active/writing).
5. Confirm customer-impact trend in `synthetic_check_results.csv` (failed checks rising).
6. Pivot to host telemetry:
   - `systemctl_status_portal_api.txt`
   - `journal_portal_api.jsonl`
   to confirm crash/restart behavior.
7. Validate host pressure in `proc_loadavg_samples.csv`.
8. Cross-check summarized detections in `availability_events.csv` and classify CIA impact.

## Key Indicators
- Outage window around `2026-03-06 09:12:00Z` to `09:16:30Z`
- HTTP status: repeated `503`
- NGINX alert text: `worker_connections are not enough`
- Service restart loop: `portal-api.service ... status=1/FAILURE`
- Monitoring correlation: healthcheck failures + critical outage events

## Suggested Commands / Tools
- `rg " 503 |worker_connections|Connection refused|prematurely closed" nginx_access.log nginx_error.log`
- `rg "Failed with result|restart counter|FAILURE|saturated" systemctl_status_portal_api.txt journal_portal_api.jsonl`
- `rg "OUTAGE|RESOURCE_LIMIT|PROCESS_CRASH" availability_events.csv`
- CSV sort/filter by timestamp to align counter spikes and service failures.
