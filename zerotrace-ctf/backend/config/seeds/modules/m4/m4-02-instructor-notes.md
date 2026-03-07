# M4-02 Instructor Notes

## Objective
- Train learners to analyze a distributed traffic flood incident and classify the attack type.
- Expected answer: `CTF{ddos}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5312`
   - window: `2026-03-07 18:11 UTC`
2. In `firewall_event.log`, identify:
   - `Inbound requests/sec: 42000`
   - `Traffic source: multiple IP addresses`
3. In `edge_rate_timeseries.csv`, confirm high request/packet rates and large unique source-IP counts.
4. In `netflow_summary.csv`, confirm large SYN-heavy distributed flows.
5. In `ids_alerts.jsonl`, locate critical `distributed_syn_flood` alert with `attack_class=ddos`.
6. In `lb_service_health.csv`, verify outage impact (`503`, service unreachable).
7. In `timeline_events.csv`, confirm classification and incident open event.
8. Submit attack type as `CTF{ddos}`.

## Key Indicators
- Incident ID: `INC-2026-5312`
- Surge marker: `42000 requests/sec`
- Distribution marker: `multiple IP addresses`
- IDS marker: `distributed_syn_flood`
- Final class: `attack_class=ddos`

## Suggested Commands / Tools
- `rg "42000|multiple IP addresses|distributed_syn_flood|attack_class|INC-2026-5312" evidence`
- CSV analysis in:
  - `edge_rate_timeseries.csv`
  - `netflow_summary.csv`
  - `lb_service_health.csv`
  - `timeline_events.csv`
- JSONL filtering in `ids_alerts.jsonl` for `severity=critical`.
