# M9-09 Instructor Notes

## Objective
- Train learners to identify development subdomains from realistic DNS intelligence data.
- Expected answer: `CTF{dev.company.com}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5909`
   - goal: identify development subdomain
2. In `subdomain_inventory.csv`, locate suspicious development candidate.
3. In `dns_bruteforce.log`, confirm candidate was discovered during brute-force.
4. In `passive_dns.jsonl`, validate historical DNS observation for the same domain.
5. In `certificate_san_extract.csv`, confirm domain appears in certificate SAN set.
6. In `resolver_query.log`, verify active resolver response for candidate.
7. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final subdomain.
8. Submit development subdomain.

## Key Indicators
- Domain pivot:
  - `dev.company.com`
- Discovery pivot:
  - `interesting_subdomain`
- SIEM pivot:
  - `development_subdomain_confirmed`

## Suggested Commands / Tools
- `rg "dev.company.com|interesting_subdomain|development_subdomain_confirmed" evidence`
- Review:
  - `evidence/dns_records.txt`
  - `evidence/osint/subdomain_inventory.csv`
  - `evidence/osint/dns_bruteforce.log`
  - `evidence/osint/passive_dns.jsonl`
  - `evidence/osint/certificate_san_extract.csv`
  - `evidence/osint/resolver_query.log`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
