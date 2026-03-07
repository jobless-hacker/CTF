# M5-06 Instructor Notes

## Objective
- Train learners to investigate hidden-file persistence evidence on Linux hosts.
- Expected answer: `CTF{.hidden_backdoor}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5506`
   - node: `lin-hunt-02`
2. In `home_inventory.csv`, find suspicious hidden file entry under `/home/deploy`.
3. In `recursive_ls_hidden_scan.txt`, validate file presence and executable permissions.
4. In `file_hash_catalog.csv`, confirm suspicious file classification.
5. In `inotify_events.log`, confirm create/attrib/exec chain for hidden file.
6. In `hidden_file_alerts.jsonl` and `timeline_events.csv`, confirm final attribution.
7. Submit the suspicious hidden filename.

## Key Indicators
- Inventory pivot:
  - `/home/deploy,.hidden_backdoor,true,...`
- Listing pivot:
  - `-rwx------ ... .hidden_backdoor`
- Hash pivot:
  - `/home/deploy/.hidden_backdoor ... elf64,suspicious`
- Runtime pivot:
  - `event=IN_EXEC path=/home/deploy/.hidden_backdoor`
- Alert pivot:
  - `"suspicious_file":".hidden_backdoor"`

## Suggested Commands / Tools
- `rg "\\.hidden_backdoor|IN_EXEC|suspicious_file|hidden_executable" evidence`
- Review:
  - `evidence/filesystem/home_inventory.csv`
  - `evidence/filesystem/recursive_ls_hidden_scan.txt`
  - `evidence/filesystem/inotify_events.log`
