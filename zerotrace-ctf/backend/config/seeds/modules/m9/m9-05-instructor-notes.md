# M9-05 Instructor Notes

## Objective
- Train learners to discover legacy infrastructure domains from realistic archive intelligence.
- Expected answer: `CTF{oldportal.company.net}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5905`
   - goal: identify legacy portal domain
2. In `wayback_index.csv`, locate archived legacy portal URL.
3. In `archive_crawler.log`, verify crawler hit on legacy portal host.
4. In `historical_dns.jsonl`, validate passive DNS observation for same domain.
5. In `ct_log_extract.csv`, confirm certificate record for legacy domain.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm normalized final domain.
7. Submit old portal domain.

## Key Indicators
- Domain pivot:
  - `oldportal.company.net`
- Archive/crawler pivot:
  - `legacy_portal_detected`
- SIEM pivot:
  - `legacy_portal_confirmed`

## Suggested Commands / Tools
- `rg "oldportal.company.net|legacy_portal_detected|legacy_portal_confirmed" evidence`
- Review:
  - `evidence/archive.txt`
  - `evidence/osint/wayback_index.csv`
  - `evidence/osint/archive_crawler.log`
  - `evidence/osint/historical_dns.jsonl`
  - `evidence/osint/ct_log_extract.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
