# M4-10 Instructor Notes

## Objective
- Train learners to assess ransomware impact and classify primary CIA impact correctly.
- Expected answer: `CTF{availability}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5433`
   - host: `fin-app-01`
2. In `endpoint_security.log`, confirm ransomware behavior:
   - `file_encrypt_burst`
   - ransom note drop
3. In `ransom_note.txt`, confirm extortion note presence.
4. In `file_access_failures.csv`, validate inability to access encrypted files.
5. In `service_availability_checks.csv`, confirm dependent services failing due to unavailable data.
6. In `backup_restore.log`, confirm recovery attempts blocked by encryption.
7. In `edr_alerts.jsonl` and `timeline_events.csv`, confirm primary impact classification.
8. Submit `CTF{availability}`.

## Key Indicators
- Incident ID: `INC-2026-5433`
- Ransomware markers: encryption burst + ransom note
- Business impact marker: users cannot access encrypted files
- Alert field: `primary_impact = availability`
- SIEM marker: `impact_classified ... availability`

## Suggested Commands / Tools
- `rg "file_encrypted|primary_impact|users cannot access|availability|INC-2026-5433" evidence`
- CSV analysis in:
  - `file_access_failures.csv`
  - `service_availability_checks.csv`
  - `timeline_events.csv`
- JSONL filtering in `edr_alerts.jsonl` for critical ransomware events.
