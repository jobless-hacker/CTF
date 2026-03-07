# M6-05 Instructor Notes

## Objective
- Train learners to identify a malware file downloaded during web browsing activity.
- Expected answer: `CTF{trojan.exe}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5605`
   - user: `employee02`
   - host: `WKSTN-432` / `192.168.20.32`
2. In `proxy_http.log`, find suspicious HTTP executable download from `malicious-domain.ru`.
3. In `dns_queries.log`, validate same domain resolution from the affected host.
4. In `download_history.csv`, confirm exact downloaded executable file name and verdict.
5. In `egress_flow.csv`, validate transfer size/time alignment for the executable fetch.
6. In `download_alerts.jsonl` and `timeline_events.csv`, confirm final malware file attribution.
7. Submit malicious file name.

## Key Indicators
- Proxy pivot:
  - `url=http://malicious-domain.ru/trojan.exe`
- DNS pivot:
  - `query=malicious-domain.ru`
- Endpoint pivot:
  - `...,malicious-domain.ru,trojan.exe,...,malicious`
- Alert pivot:
  - `"type":"malware_download_detected","suspicious_file":"trojan.exe"`
- SIEM pivot:
  - `malware_file_identified ... trojan.exe`

## Suggested Commands / Tools
- `rg "malicious-domain\\.ru|trojan\\.exe|malware_download_detected|malware_file_identified" evidence`
- Review:
  - `evidence/network/proxy_http.log`
  - `evidence/network/dns_queries.log`
  - `evidence/endpoint/download_history.csv`
  - `evidence/security/download_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
