# M2-07 Instructor Notes

## Objective
- Train learners to identify a malicious domain by correlating web, DNS, endpoint, firewall, and EDR evidence.
- Expected answer: `CTF{malicious-site.ru}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - host: `ws-43`
   - user: `john`
   - window: around `2026-03-07 14:22 UTC`
2. In `proxy.log`, find suspicious HTTP requests for executable/script artifacts.
3. In `dns_queries.csv`, confirm domain resolution and destination IP.
4. In `firewall_egress.csv`, validate matching outbound sessions to same IP/domain context.
5. In `download_history.csv`, confirm downloaded file names and source domain.
6. In `edr_web_alerts.jsonl`, confirm high/critical detections referencing same domain.
7. In `domain_reputation.csv`, verify malicious classification and low reputation score.
8. In `timeline_events.csv`, confirm end-to-end incident sequence and return domain.

## Key Indicators
- Domain: `malicious-site.ru`
- Destination IP: `185.225.19.77`
- Files: `payload.exe`, `loader.ps1`
- Detection signals: suspicious executable download + malware stager behavior

## Suggested Commands / Tools
- `rg "malicious-site.ru|payload.exe|185.225.19.77|suspicious_executable_download" evidence`
- CSV filtering in:
  - `dns_queries.csv`
  - `firewall_egress.csv`
  - `download_history.csv`
  - `timeline_events.csv`
- `jq` filtering of high/critical alerts in `edr_web_alerts.jsonl`.
