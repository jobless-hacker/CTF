# M4-05 Instructor Notes

## Objective
- Train learners to identify database connection exhaustion during outage analysis.
- Expected answer: `CTF{connection_limit}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5361`
   - host: `db-prod-01`
2. In `postgres.log`, find:
   - `sorry, too many clients already`
   - `connection limit exceeded`
3. In `db_connection_timeseries.csv`, confirm total connections pinned at max with high rejects.
4. In `pool_stats.csv`, confirm exhausted pool and elevated waiting clients.
5. In `app_db_error.log`, confirm application-facing DB connection failures.
6. In `postgresql.conf`, verify configured `max_connections`.
7. In `db_alerts.jsonl` and `timeline_events.csv`, confirm `connection_limit` classification.
8. Submit `CTF{connection_limit}`.

## Key Indicators
- Incident ID: `INC-2026-5361`
- DB fatal: `too many clients already`
- Capacity marker: `max_connections = 300`
- Pool marker: waiting clients spikes with exhausted pool
- Root classification: `connection_limit`

## Suggested Commands / Tools
- `rg "too many clients already|connection limit exceeded|connection_limit|max_connections = 300|INC-2026-5361" evidence`
- CSV analysis in:
  - `db_connection_timeseries.csv`
  - `pool_stats.csv`
  - `slow_query_summary.csv`
  - `timeline_events.csv`
- JSONL filtering in `db_alerts.jsonl` for critical alerts.
