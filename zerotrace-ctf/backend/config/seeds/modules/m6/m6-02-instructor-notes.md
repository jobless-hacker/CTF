# M6-02 Instructor Notes

## Objective
- Train learners to detect DNS beaconing patterns and identify suspicious domain IOC.
- Expected answer: `CTF{update-check.company.com}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5602`
   - source host: `192.168.1.45`
2. In `dns_query.log`, identify repeated near-constant queries to one domain.
3. In `dns_query_summary.csv`, confirm high beacon score and interval.
4. In `firewall_dns_egress.log`, confirm high-frequency DNS notes for same domain.
5. In `process_dns_activity.csv`, map query burst to local process.
6. In `dns_beacon_alerts.jsonl` and `timeline_events.csv`, confirm final attribution.
7. Submit suspicious domain IOC.

## Key Indicators
- Query pivot:
  - `qname=update-check.company.com`
- Summary pivot:
  - `192.168.1.45,update-check.company.com,...,beacon_score=0.98`
- Firewall pivot:
  - `note=high_frequency_domain update-check.company.com`
- Host pivot:
  - `svc-update-agent ... update-check.company.com`
- Alert pivot:
  - `"suspicious_domain":"update-check.company.com"`

## Suggested Commands / Tools
- `rg "update-check.company.com|beacon_score|suspicious_domain|192.168.1.45" evidence`
- Review:
  - `evidence/network/dns_query.log`
  - `evidence/network/dns_query_summary.csv`
  - `evidence/network/firewall_dns_egress.log`
  - `evidence/host/process_dns_activity.csv`
