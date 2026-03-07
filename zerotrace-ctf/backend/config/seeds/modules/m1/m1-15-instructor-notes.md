# M1-15 Instructor Notes

## Objective
- Train learners to investigate ransomware impact using host, security, network, and operations evidence.
- Expected answer: `CTF{availability}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt` to fix incident scope:
   - host: `WS-FIN-22`
   - user: `finance.ap`
   - time window: around `2026-03-06T03:14Z`
2. Inspect `process_creation.log` for execution chain:
   - user document/macro execution path
   - `cipherlock.exe` launch
   - `vssadmin delete shadows /all /quiet`
3. Validate impact in `file_impact_timeline.csv`:
   - mass rename to `.vault`
   - user file-open failures (`access_denied`)
4. Cross-check `edr_alerts.jsonl`:
   - critical ransomware behavior
   - shadow-copy deletion
   - note about no confirmed large exfil in window
5. Confirm spread/scale:
   - `smb_activity.csv` encryption write spike
   - `service_desk_tickets.csv` surge of ".vault extension" complaints
6. Confirm recovery failure:
   - `snapshot_inventory.csv` -> zero snapshots post deletion
   - `recovery_attempts.log` -> restore failures and business files unavailable
7. Classify CIA pillar.

## Key Indicators
- Ransom process: `cipherlock.exe`
- Recovery inhibition: `vssadmin delete shadows /all /quiet`
- File-impact marker: extension shift to `.vault`
- Business impact: widespread inability to open files + failed restore

## Suggested Commands / Tools
- `rg "cipherlock|vssadmin|.vault|access_denied|shadow copy restore failed" evidence`
- CSV filtering by incident window across:
  - `file_impact_timeline.csv`
  - `smb_activity.csv`
  - `service_desk_tickets.csv`
  - `snapshot_inventory.csv`
- `jq` filtering in `edr_alerts.jsonl` for `severity == "critical"`.
