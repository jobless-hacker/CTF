# M8-10 Instructor Notes

## Objective
- Train learners to investigate exposed full backup archives in cloud storage environments.
- Expected answer: `CTF{full_backup_2025.zip}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5810`
   - bucket: `corp-backups`
2. In `backup_inventory.log`, find the full archive exposure indicator.
3. In `backup_catalog.csv`, validate the archive is classified `full,true,public,critical`.
4. In `object_access.log` and `cloudtrail_events.jsonl`, confirm anonymous access to the archive.
5. In `backup_policy_audit.log`, verify policy violation for public full archive.
6. In `backup_archive_alerts.jsonl` and `timeline_events.csv`, extract normalized exposed archive.
7. Submit exposed full backup archive filename.

## Key Indicators
- Archive pivot:
  - `full_backup_2025.zip`
  - `category=full_archive exposure=public`
- Classification pivot:
  - `full,true,365d,public,critical`
- Access pivot:
  - `auth=anonymous`
  - `"principalId":"AWS:Anonymous"`
- Detection pivot:
  - `"type":"full_backup_archive_exposed"`
  - `full_backup_archive_identified ... full_backup_2025.zip`

## Suggested Commands / Tools
- `rg "full_backup_2025.zip|full,true,public,critical|auth=anonymous|exposed_archive|full_backup_archive_identified" evidence`
- Review:
  - `evidence/cloud/backup_inventory.log`
  - `evidence/cloud/backup_catalog.csv`
  - `evidence/cloud/object_access.log`
  - `evidence/cloud/cloudtrail_events.jsonl`
  - `evidence/cloud/backup_policy_audit.log`
  - `evidence/security/backup_archive_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
