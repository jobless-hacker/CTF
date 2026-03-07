# M4-06 Instructor Notes

## Objective
- Train learners to identify the exact crashed container during runtime outage triage.
- Expected answer: `CTF{web-app}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5375`
   - node: `container-node-02`
2. In `dockerd.log`, find:
   - `container web-app exited unexpectedly`
   - restart failure lines
3. In `container_events.jsonl`, locate `actor=web-app` with `status=die` and failed restart.
4. In `container_inventory.csv`, confirm `web-app` state as `exited`.
5. In `probe_results.csv`, confirm downstream impact (`502`, `upstream_container_down`).
6. In `container_resource_metrics.csv`, verify restart/oom indicators for `web-app`.
7. In `container_alerts.jsonl` and `timeline_events.csv`, confirm crash classification.
8. Submit crashed container name as `CTF{web-app}`.

## Key Indicators
- Incident ID: `INC-2026-5375`
- Runtime marker: `container web-app exited unexpectedly`
- Event marker: `status = die` for `web-app`
- Alert marker: `crashed_container = web-app`
- SIEM marker: `container_died`

## Suggested Commands / Tools
- `rg "web-app|exited unexpectedly|status\":\"die|crashed_container|INC-2026-5375" evidence`
- CSV analysis in:
  - `container_inventory.csv`
  - `probe_results.csv`
  - `container_resource_metrics.csv`
  - `timeline_events.csv`
- JSONL filtering in:
  - `container_events.jsonl`
  - `container_alerts.jsonl`
