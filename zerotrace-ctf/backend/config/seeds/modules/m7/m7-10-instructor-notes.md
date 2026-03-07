# M7-10 Instructor Notes

## Objective
- Train learners to investigate exposed backup artifacts on web infrastructure.
- Expected answer: `CTF{backup.zip}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5710`
2. In `web_files_inventory.log`, identify suspicious backup file under web root.
3. In `autoindex_snapshot.txt`, confirm the file is visible in directory listing.
4. In `discovery_scan.csv`, verify exposed path returns `200`.
5. In `access.log`, validate direct external retrieval of backup file.
6. In `web_config_audit.log`, confirm missing deny-rule violation for backup archive.
7. In `sensitive_backup_alerts.jsonl` and `timeline_events.csv`, extract normalized exposed backup filename.
8. Submit exposed backup file name.

## Key Indicators
- File/path pivot:
  - `/backup.zip`
- Discovery pivot:
  - `/backup.zip,200,...,application/zip,true`
- Access pivot:
  - `GET /backup.zip ... 200`
- Config pivot:
  - `status=violation path=/backup.zip`
- Alert pivot:
  - `"type":"sensitive_backup_exposed","exposed_backup_file":"backup.zip"`
- SIEM pivot:
  - `exposed_backup_file_identified ... backup.zip`

## Suggested Commands / Tools
- `rg "/backup.zip|exposed_backup_file|exposed_backup_file_identified|status=violation" evidence`
- Review:
  - `evidence/web/web_files_inventory.log`
  - `evidence/web/autoindex_snapshot.txt`
  - `evidence/web/discovery_scan.csv`
  - `evidence/web/access.log`
  - `evidence/app/web_config_audit.log`
  - `evidence/security/sensitive_backup_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
