# M3-09 Instructor Notes

## Objective
- Train learners to triage leaked archives and identify restricted strategic documents using SOC/DFIR evidence.
- Expected answer: `CTF{company_strategy.docx}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5237`
   - primary object: `breach_archive.zip`
2. In `archive_extraction.log`, confirm extracted file list from recovered archive.
3. In nested `breach_archive.zip`, verify actual contained files.
4. In `document_registry.csv`, confirm classification of candidate strategic files.
5. In `dlp_archive_alerts.jsonl`, locate critical restricted document exposure alert.
6. In `public_download_logs.csv`, confirm external archive download.
7. In `timeline_events.csv`, validate event progression and incident opening.
8. Submit exact strategic document filename in `CTF{...}` format.

## Key Indicators
- Strategic file: `company_strategy.docx`
- Incident ID: `INC-2026-5237`
- External download IP: `185.199.110.42`
- SIEM event: `restricted_doc_identified`
- DLP event type: `restricted_doc_exposed`

## Suggested Commands / Tools
- `rg "company_strategy.docx|breach_archive.zip|restricted_doc_identified|INC-2026-5237|185.199.110.42" evidence`
- CSV analysis in:
  - `document_registry.csv`
  - `public_download_logs.csv`
  - `timeline_events.csv`
- JSONL filtering in `dlp_archive_alerts.jsonl` for `severity=critical`.
