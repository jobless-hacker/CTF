# M6-01 Instructor Notes

## Objective
- Train learners to identify suspicious external endpoint from multi-source network evidence.
- Expected answer: `CTF{203.0.113.77}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5601`
   - source host: `192.168.1.25`
2. In `traffic.pcap`, locate repeated packet sequence toward same external IP.
3. In `netflow_records.csv`, confirm recurring flow pair with matching destination.
4. In `firewall_egress.log`, confirm alerted outbound sessions to same endpoint.
5. In `network_alerts.jsonl`, extract `suspicious_external_ip`.
6. In `timeline_events.csv`, validate SIEM corroboration.
7. Submit suspicious external IP.

## Key Indicators
- Packet pivot:
  - `192.168.1.25,203.0.113.77`
- Flow pivot:
  - `192.168.1.25,203.0.113.77,...,443,TCP`
- Firewall pivot:
  - `src=192.168.1.25 dst=203.0.113.77`
- Alert pivot:
  - `"suspicious_external_ip":"203.0.113.77"`
- SIEM pivot:
  - `unknown_external_tls_session ... 203.0.113.77`

## Suggested Commands / Tools
- `rg "203.0.113.77|192.168.1.25|suspicious_external_ip" evidence`
- Review:
  - `evidence/network/traffic.pcap`
  - `evidence/network/netflow_records.csv`
  - `evidence/network/firewall_egress.log`
  - `evidence/security/network_alerts.jsonl`
