# M9-03 Instructor Notes

## Objective
- Train learners to perform domain registrar attribution using realistic OSINT datasets.
- Expected answer: `CTF{NameCheap}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5903`
   - target domain: `suspicious-site.com`
2. In `domain_inventory.csv`, locate target domain and candidate registrar.
3. In `whois_batch.log` and `whois.txt`, validate WHOIS registrar evidence.
4. In `rdap_responses.jsonl`, confirm normalized `registrarName` for target.
5. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final registrar attribution.
6. Submit registrar value.

## Key Indicators
- Domain pivot:
  - `suspicious-site.com`
- Registrar pivot:
  - `NameCheap`
  - `NameCheap Inc.`
- SIEM pivot:
  - `registrar_confirmed`
- RDAP pivot:
  - `"registrarName":"NameCheap"`

## Suggested Commands / Tools
- `rg "suspicious-site.com|NameCheap|registrar_confirmed|registrarName" evidence`
- Review:
  - `evidence/whois.txt`
  - `evidence/osint/domain_inventory.csv`
  - `evidence/osint/whois_batch.log`
  - `evidence/osint/rdap_responses.jsonl`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
