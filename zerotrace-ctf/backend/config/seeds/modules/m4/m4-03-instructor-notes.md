# M4-03 Instructor Notes

## Objective
- Train learners to investigate host storage exhaustion and classify outage root cause.
- Expected answer: `CTF{disk_full}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5328`
   - host: `web-prod-02`
   - outage window near `2026-03-07 19:02 UTC`
2. In `disk_usage_timeseries.csv`, confirm root mount (`/`) reaches `100%` with `0.00` available.
3. In `journal_errors.log`, locate `No space left on device` service and system errors.
4. In `app_write_failures.csv`, confirm write failures from application paths.
5. In `top_disk_consumers.txt`, identify dominant disk consumers.
6. In `logrotate_run.log` + `logrotate_nginx.conf`, verify rotation issue contributing to disk growth.
7. In `storage_alerts.jsonl` and `timeline_events.csv`, confirm root-cause classification.
8. Submit `CTF{disk_full}`.

## Key Indicators
- Incident ID: `INC-2026-5328`
- Core error: `No space left on device`
- Root mount state: `100%` used, `0GB` available
- Alert root-cause field: `disk_full`
- SIEM marker: `root_cause_classified`

## Suggested Commands / Tools
- `rg "No space left on device|100%|disk_full|INC-2026-5328" evidence`
- CSV analysis in:
  - `disk_usage_timeseries.csv`
  - `app_write_failures.csv`
  - `timeline_events.csv`
- JSONL filtering in `storage_alerts.jsonl` for critical events.
