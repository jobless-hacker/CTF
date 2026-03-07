# M3-06 Instructor Notes

## Objective
- Train learners to investigate a confidential document leak and extract the sensitive project identifier.
- Expected answer: `CTF{Falcon}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - exposed file: `strategic_program_briefing.txt`
   - window: `2026-03-07 13:52-13:53 UTC`
2. In `document_repo_index.csv`, verify file classification and repository context.
3. In `outbound_mail_log.csv`, identify unauthorized external sharing event.
4. In `public_share_access.log`, confirm external public retrieval.
5. In `dlp_document_alerts.jsonl`, confirm high/critical confidentiality alerts.
6. In `identity_context.csv`, inspect actor role and access scope.
7. In `timeline_events.csv`, validate incident progression.
8. Inspect leaked document and return confidential project name.

## Key Indicators
- Leaked file: `strategic_program_briefing.txt`
- Confidentiality breach: external share + external download
- Document marker: `Project Name: Falcon`
- SOC corroboration: critical `public_confidential_access` event

## Suggested Commands / Tools
- `rg "Falcon|strategic_program_briefing.txt|confidential|public_confidential_access" evidence`
- CSV filtering in:
  - `document_repo_index.csv`
  - `outbound_mail_log.csv`
  - `timeline_events.csv`
- `jq` filtering for high/critical in `dlp_document_alerts.jsonl`.
