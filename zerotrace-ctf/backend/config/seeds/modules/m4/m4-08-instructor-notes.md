# M4-08 Instructor Notes

## Objective
- Train learners to identify failed DNS service units during resolver outage investigations.
- Expected answer: `CTF{bind9}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5402`
   - resolver host: `dns-core-01`
2. In `named.log`, find:
   - `service bind9 stopped`
   - `dns resolution failure`
3. In `systemctl_snapshot.log`, confirm:
   - `systemctl status bind9.service`
   - `Active: failed`
4. In `dig_probe_results.csv`, verify widespread `SERVFAIL`.
5. In `dns_packet_summary.csv`, confirm response collapse (`response_count=0`, SERVFAIL spikes).
6. In `dns_alerts.jsonl`, confirm critical alert with `failed_service=bind9`.
7. In `timeline_events.csv`, confirm SIEM event `dns_service_failed`.
8. Submit `CTF{bind9}`.

## Key Indicators
- Incident ID: `INC-2026-5402`
- Service marker: `bind9.service`
- Log marker: `service bind9 stopped`
- Availability marker: widespread `SERVFAIL`
- Alert marker: `failed_service = bind9`

## Suggested Commands / Tools
- `rg "bind9|service bind9 stopped|Active: failed|SERVFAIL|INC-2026-5402" evidence`
- CSV analysis in:
  - `resolver_timeseries.csv`
  - `dig_probe_results.csv`
  - `dns_packet_summary.csv`
  - `timeline_events.csv`
- JSONL filtering in `dns_alerts.jsonl` for critical service-down events.
