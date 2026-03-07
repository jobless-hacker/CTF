# M1-09 Instructor Notes

## Objective
- Train learners to investigate DDoS-driven service disruption with realistic telemetry.
- Expected answer: `CTF{availability}`.

## Expected Investigation Path
1. Start with `incident_ticket.txt` and lock the suspected outage window.
2. Validate perimeter surge in `edge_firewall.log`:
   - high `conn_per_sec`
   - high `syn_ratio`
   - `rate-limit` / `drop` actions
3. Confirm attack profile in `netflow_timeseries.csv`:
   - high session rates
   - high unique source counts
   - SYN-heavy imbalance
4. Correlate service impact:
   - `load_balancer_health.csv` (`healthy_backend_pct` collapse, high `http_5xx_pct`)
   - `uptime_monitor.csv` (503 + timeouts across probe regions)
5. Filter noise:
   - scheduled internal load-test entries
   - routine WAF scanner probes from `waf_events.jsonl`
6. Validate severity context in `normalized_events.csv`.
7. Classify CIA impact.

## Key Indicators
- Target VIP: `203.0.113.40:443`
- Incident window around `2026-03-06 11:16Z - 11:19Z`
- NetFlow pattern: distributed short-lived SYN-heavy bursts
- Service impact: health degradation + external timeouts
- SIEM pivots:
  - `ddos_l3_l4_surge_detected`
  - `service_availability_degraded`

## Suggested Commands / Tools
- `rg "conn_per_sec|syn_ratio|rate-limit|drop" evidence/firewall/edge_firewall.log`
- CSV filter by timestamp on:
  - `evidence/network/netflow_timeseries.csv`
  - `evidence/service/load_balancer_health.csv`
  - `evidence/service/uptime_monitor.csv`
- `jq` filter on `evidence/network/waf_events.jsonl` for false-positive context.
- Use minute-level timeline alignment to prove cause -> impact.
