# M5-05 Instructor Notes

## Objective
- Train learners to investigate potential Linux SUID privilege escalation and identify risky binary.
- Expected answer: `CTF{find}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5505`
   - node: `lin-sec-03`
2. In `suid_inventory.csv`, locate high-risk SUID entry.
3. In `permissions_snapshot.txt`, confirm SUID bit on matching binary.
4. In `execve_audit.log`, confirm suspicious command usage and `euid=0`.
5. In `privesc_alerts.jsonl`, confirm `risky_binary` field.
6. In `timeline_events.csv`, confirm SIEM attribution and incident sequence.
7. Submit the risky binary name.

## Key Indicators
- Inventory pivot:
  - `/usr/bin/find ... high_risk`
- Snapshot pivot:
  - `-rwsr-xr-x ... /usr/bin/find`
- Execution pivot:
  - `command="/usr/bin/find ..."` with `euid=0`
- Alert pivot:
  - `"type":"suid_binary_abuse"`
  - `"risky_binary":"find"`
- SIEM pivot:
  - `suid_scan_flagged ... /usr/bin/find`

## Suggested Commands / Tools
- `rg "/usr/bin/find|risky_binary|euid=0|suid"` evidence
- Review:
  - `evidence/filesystem/suid_inventory.csv`
  - `evidence/filesystem/permissions_snapshot.txt`
  - `evidence/audit/execve_audit.log`
