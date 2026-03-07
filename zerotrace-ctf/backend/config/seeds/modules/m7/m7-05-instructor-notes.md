# M7-05 Instructor Notes

## Objective
- Train learners to identify an exposed sensitive management directory.
- Expected answer: `CTF{admin}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5705`
2. In `directory_listing.txt`, identify candidate sensitive directory path.
3. In `discovery_scan.csv` and `access.log`, confirm path is reachable.
4. In `route_manifest.log` and `robots_snapshot.txt`, validate exposure context.
5. In `web_exposure_alerts.jsonl` and `timeline_events.csv`, extract normalized sensitive directory label.
6. Submit sensitive directory name.

## Key Indicators
- Listing pivot:
  - `admin/` appears in index
- Discovery/access pivot:
  - `/admin/` returns `200`
- Route pivot:
  - `route=/admin/ visibility=public auth=weak`
- Alert pivot:
  - `"type":"sensitive_directory_exposed","sensitive_directory":"admin"`
- SIEM pivot:
  - `sensitive_directory_identified ... admin`

## Suggested Commands / Tools
- `rg "/admin/|sensitive_directory|sensitive_directory_identified|visibility=public auth=weak" evidence`
- Review:
  - `evidence/web/directory_listing.txt`
  - `evidence/web/discovery_scan.csv`
  - `evidence/web/access.log`
  - `evidence/web/route_manifest.log`
  - `evidence/security/web_exposure_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
