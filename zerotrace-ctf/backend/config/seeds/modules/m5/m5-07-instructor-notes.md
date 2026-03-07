# M5-07 Instructor Notes

## Objective
- Train learners to identify suspicious Linux process from multi-source host telemetry.
- Expected answer: `CTF{cryptominer}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5507`
   - node: `lin-prod-03`
2. In `process_inventory.csv`, locate critical process entry.
3. In `ps_aux_snapshot.txt`, confirm suspicious process command line and high CPU.
4. In `cpu_usage_timeseries.csv`, correlate near-total CPU saturation with top process.
5. In `network_connections.log`, confirm suspicious process outbound sessions.
6. In `process_alerts.jsonl` and `timeline_events.csv`, confirm process attribution.
7. Submit suspicious process name.

## Key Indicators
- Inventory pivot:
  - `process_name=cryptominer`
- Process snapshot pivot:
  - `/tmp/.cache/cryptominer ...`
- CPU pivot:
  - `98.4` / `99.1` with `top_process=cryptominer`
- Network pivot:
  - `process=cryptominer ... remote=203.0.113.66:4444`
- Alert pivot:
  - `"suspicious_process":"cryptominer"`

## Suggested Commands / Tools
- `rg "cryptominer|4444|high_cpu_unknown_process|suspicious_process" evidence`
- Review:
  - `evidence/process/process_inventory.csv`
  - `evidence/process/ps_aux_snapshot.txt`
  - `evidence/host/cpu_usage_timeseries.csv`
  - `evidence/network/network_connections.log`
