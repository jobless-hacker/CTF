# M3-10 Instructor Notes

## Objective
- Train learners to investigate exposed web backup paths and identify full-backup artifact leakage.
- Expected answer: `CTF{site_backup_full.tar}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5264`
   - scope: public `/backup/` exposure
2. Inspect `webserver_backup_location.conf` and detect root cause (`autoindex on;`).
3. In `directory_listing_snapshot.txt`, identify candidate backup files.
4. In `backup_object_inventory.csv`, verify full backup object metadata and classification.
5. In `web_exposure_scan.jsonl`, confirm critical finding for public full backup path.
6. In `nginx_access.log` and `cdn_edge_requests.csv`, confirm external access/download to same file.
7. In `timeline_events.csv`, validate incident chronology and escalation.
8. Submit exact full backup filename in `CTF{...}` format.

## Key Indicators
- Full backup filename: `site_backup_full.tar`
- Incident ID: `INC-2026-5264`
- External source IP: `185.199.110.42`
- SIEM event: `public_backup_detected`
- Misconfiguration marker: `autoindex on;`

## Suggested Commands / Tools
- `rg "site_backup_full.tar|autoindex on|INC-2026-5264|public_backup_detected|185.199.110.42" evidence`
- CSV analysis in:
  - `backup_object_inventory.csv`
  - `cdn_edge_requests.csv`
  - `timeline_events.csv`
- JSONL filtering in `web_exposure_scan.jsonl` for `severity=critical`.
