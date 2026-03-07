# M6-04 Instructor Notes

## Objective
- Train learners to identify the true scanning source during a perimeter recon incident.
- Expected answer: `CTF{185.199.110.42}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5604`
   - target host: `10.30.0.12`
2. In `firewall.log`, locate rapid multi-port probe pattern from a single external source.
3. In `connection_attempt_summary.csv`, validate high `unique_ports` and high `scan_score`.
4. In `ids_alerts.log`, confirm scan signatures tied to the same source.
5. In `flow_records.csv`, verify repeated SYN attempts across multiple destination ports.
6. In `port_scan_alerts.jsonl` and `timeline_events.csv`, confirm final correlated scanner attribution.
7. Submit the scanning source IP.

## Key Indicators
- Firewall pivot:
  - `action=DROP_WITH_ALERT ... src=185.199.110.42 ... reason=possible_scan`
- Summary pivot:
  - `...,185.199.110.42,...,unique_ports=22,...,scan_score=0.99,...`
- IDS pivot:
  - `sig="ET SCAN NMAP -sS Portscan"`
- Alert pivot:
  - `"type":"port_scan_detected","scanning_ip":"185.199.110.42"`
- SIEM pivot:
  - `scan_source_confirmed ... 185.199.110.42`

## Suggested Commands / Tools
- `rg "185.199.110.42|possible_scan|port_scan_detected|scan_source_confirmed" evidence`
- Review:
  - `evidence/network/firewall.log`
  - `evidence/network/connection_attempt_summary.csv`
  - `evidence/network/ids_alerts.log`
  - `evidence/network/flow_records.csv`
  - `evidence/security/port_scan_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
