# M3-04 Instructor Notes

## Objective
- Train learners to investigate a leaked SQL dump and extract compromised admin credentials.
- Expected answer: `CTF{AdminPass!}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - leaked object: `incident_drop/users_dump_2026_03_07.sql`
   - window: around `2026-03-07 10:21 UTC`
2. In `backup_catalog.csv`, confirm leaked dump metadata and ACL status.
3. In `acl_change_events.jsonl`, confirm public ACL assignment event.
4. In `public_object_access.log`, confirm external download activity.
5. In `dlp_dump_alerts.jsonl`, validate plaintext-credential exposure alerts.
6. In `timeline_events.csv`, confirm incident progression.
7. Inspect `users_dump_2026_03_07.sql` and locate admin row.
8. Return the admin password value.

## Key Indicators
- Exposed object: `users_dump_2026_03_07.sql`
- ACL: `public-read`
- External retrieval: non-corporate IP access
- Credential row: `admin` user with password `AdminPass!`

## Suggested Commands / Tools
- `rg "users_dump_2026_03_07.sql|public-read|AdminPass!|external_dump_access" evidence`
- JSONL filtering in:
  - `acl_change_events.jsonl`
  - `dlp_dump_alerts.jsonl`
- SQL-focused grep in `users_dump_2026_03_07.sql` for `admin`.
