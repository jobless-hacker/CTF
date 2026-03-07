# M4-04 Instructor Notes

## Objective
- Train learners to identify failed service units during web outage investigations.
- Expected answer: `CTF{nginx}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5344`
   - host: `web-prod-03`
2. In `systemctl_snapshot.log`, locate:
   - `systemctl status nginx.service`
   - `Active: failed`
3. In `journal_service.log`, confirm service startup failure and exit-code result.
4. In `service_health_matrix.csv`, confirm `nginx` enters failed state.
5. In `port_probe_results.csv`, verify failed checks on ports 80/443.
6. In `service_alerts.jsonl`, find critical alert with `failed_service: nginx`.
7. In `timeline_events.csv`, confirm SIEM `service_failed` event.
8. Submit failed service name in `CTF{...}` format.

## Key Indicators
- Incident ID: `INC-2026-5344`
- Unit marker: `nginx.service`
- Failure marker: `Active: failed`, `status=1/FAILURE`
- Alert marker: `failed_service = nginx`
- SIEM marker: `service_failed`

## Suggested Commands / Tools
- `rg "nginx.service|Active: failed|status=1/FAILURE|failed_service|INC-2026-5344" evidence`
- CSV analysis in:
  - `service_health_matrix.csv`
  - `port_probe_results.csv`
  - `timeline_events.csv`
- JSONL filtering in `service_alerts.jsonl` for critical events.
