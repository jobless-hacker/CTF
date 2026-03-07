# M6-07 Instructor Notes

## Objective
- Train learners to investigate DNS exfiltration behavior and derive registered exfiltration domain.
- Expected answer: `CTF{evil.com}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5607`
   - source host: `192.168.1.90`
2. In `dns_capture.pcap`, locate repeated TXT queries to chunked subdomains under `data.exfiltration.evil.com`.
3. In `dns_query_summary.csv`, confirm burst count + high entropy anomaly on same domain.
4. In `resolver.log` and `process_dns_activity.csv`, validate source host/process attribution.
5. In `dns_exfil_alerts.jsonl` and `timeline_events.csv`, extract normalized `registered_domain`.
6. Submit exfiltration domain.

## Key Indicators
- Packet pivot:
  - `*.data.exfiltration.evil.com` with `TXT` queries
- Summary pivot:
  - `data.exfiltration.evil.com,...,TXT,60,...,suspected_exfil`
- Endpoint pivot:
  - `dns_tunnel_agent.exe ... data.exfiltration.evil.com ... suspected_exfil`
- Alert pivot:
  - `"type":"dns_exfiltration_detected","registered_domain":"evil.com"`
- SIEM pivot:
  - `registered_domain_identified ... evil.com`

## Suggested Commands / Tools
- `rg "data\\.exfiltration\\.evil\\.com|registered_domain|dns_exfiltration_detected|registered_domain_identified" evidence`
- Review:
  - `evidence/network/dns_capture.pcap`
  - `evidence/network/dns_query_summary.csv`
  - `evidence/network/resolver.log`
  - `evidence/endpoint/process_dns_activity.csv`
  - `evidence/security/dns_exfil_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
