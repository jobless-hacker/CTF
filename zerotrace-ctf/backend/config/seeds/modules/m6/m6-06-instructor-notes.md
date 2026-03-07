# M6-06 Instructor Notes

## Objective
- Train learners to investigate beaconing behavior and identify external C2 infrastructure.
- Expected answer: `CTF{198.51.100.44}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5606`
   - suspected host: `192.168.1.90`
2. In `traffic.pcap`, identify repeated heartbeat frames (`interval=60s`) from host to one external IP.
3. In `flow_records.csv`, confirm fixed-interval destination persistence and `c2-beacon` tag.
4. In `dns_queries.log`, verify suspicious domain resolution to same destination IP.
5. In `net_connections.csv`, correlate endpoint process to same external destination.
6. In `c2_alerts.jsonl` and `timeline_events.csv`, validate final C2 server attribution.
7. Submit command-and-control server IP.

## Key Indicators
- Packet pivot:
  - `192.168.1.90,198.51.100.44,...,beacon heartbeat interval=60s`
- DNS pivot:
  - `query=telemetry-sync.evilcontrol.net ... answer=198.51.100.44`
- Flow pivot:
  - `...,192.168.1.90,198.51.100.44,...,c2-beacon,...`
- Alert pivot:
  - `"type":"c2_heartbeat_detected","c2_server":"198.51.100.44"`
- SIEM pivot:
  - `c2_server_identified ... 198.51.100.44`

## Suggested Commands / Tools
- `rg "198\\.51\\.100\\.44|interval=60s|c2_heartbeat_detected|c2_server_identified" evidence`
- Review:
  - `evidence/network/traffic.pcap`
  - `evidence/network/flow_records.csv`
  - `evidence/network/dns_queries.log`
  - `evidence/endpoint/net_connections.csv`
  - `evidence/security/c2_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
