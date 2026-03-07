# M10-02 Instructor Notes

## Objective
- Train learners to identify hidden files from realistic archive triage evidence.
- Expected answer: `CTF{secret.txt}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-6002`
   - target archive: `archive.zip`
2. In `recovered_archives_inventory.csv`, locate target archive row.
3. In `zip_listing_scan.log`, find hidden/overlooked entry event.
4. In `archive_contents_index.csv`, confirm entry presence under target archive.
5. In `hash_catalog.jsonl`, validate critical entry record for same filename.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final hidden file.
7. Submit filename.

## Key Indicators
- Archive pivot:
  - `archive.zip`
- File pivot:
  - `secret.txt`
  - `overlooked_entry`
- SIEM pivot:
  - `hidden_file_confirmed`

## Suggested Commands / Tools
- `rg "archive.zip|secret.txt|overlooked_entry|hidden_file_confirmed" evidence`
- Review:
  - `evidence/archive.zip`
  - `evidence/forensics/recovered_archives_inventory.csv`
  - `evidence/forensics/zip_listing_scan.log`
  - `evidence/forensics/archive_contents_index.csv`
  - `evidence/forensics/hash_catalog.jsonl`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
