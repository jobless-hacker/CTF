# M9-04 Instructor Notes

## Objective
- Train learners to perform document author attribution from realistic metadata pipelines.
- Expected answer: `CTF{John_Carter}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5904`
   - target file: `report.pdf`
2. In `document_inventory.csv`, find target file row.
3. In `pdf_metadata_extract.log`, extract author associated with target file.
4. In `doc_parser_output.jsonl`, confirm parser-normalized author metadata.
5. In `dlp_audit.log`, confirm metadata verification event for the same author.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final author attribution.
7. Submit normalized flag format.

## Key Indicators
- File pivot:
  - `report.pdf`
- Author pivot:
  - `John Carter`
  - `author=`
- SIEM pivot:
  - `document_author_confirmed`

## Suggested Commands / Tools
- `rg "report.pdf|John Carter|document_author_confirmed|author=" evidence`
- Review:
  - `evidence/report.pdf`
  - `evidence/osint/document_inventory.csv`
  - `evidence/osint/pdf_metadata_extract.log`
  - `evidence/osint/doc_parser_output.jsonl`
  - `evidence/security/dlp_audit.log`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
