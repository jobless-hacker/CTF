# M2-03 Instructor Notes

## Objective
- Train learners to investigate an unknown process incident using correlated host, network, EDR, and reputation evidence.
- Expected answer: `CTF{cryptominer}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - host: `prod-srv-11`
   - window: around `2026-03-06T08:31Z`
2. In `process_snapshot.csv`, identify process outside baseline with abnormal CPU/memory profile.
3. In `process_creation.log`, trace execution chain:
   - `curl` download
   - `chmod +x`
   - execution from `/tmp/.xmr/cryptominer`
4. In `resource_usage_timeseries.csv`, confirm sustained >95% CPU by same process.
5. In `process_connections.csv`, confirm outbound connection to mining-style destination/port.
6. In `edr_process_alerts.jsonl`, verify high/critical detections for the same process.
7. In `hash_reputation.csv` and `approved_runtime_baseline.txt`, confirm malicious reputation and baseline mismatch.
8. Conclude the suspicious process name.

## Key Indicators
- Suspicious process: `cryptominer`
- Execution origin: `/tmp/.xmr/cryptominer`
- Behavior: sustained high CPU + outbound `:4444` mining-pool connection
- Detection context: critical EDR alert + malicious hash reputation

## Suggested Commands / Tools
- `rg "cryptominer|unknown_process_execution|cryptomining_behavior|4444|/tmp/.xmr" evidence`
- CSV filtering in:
  - `process_snapshot.csv`
  - `resource_usage_timeseries.csv`
  - `process_connections.csv`
  - `hash_reputation.csv`
- `jq` filter in `edr_process_alerts.jsonl` for `severity` high/critical.
