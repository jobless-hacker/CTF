# M2-04 Instructor Notes

## Objective
- Train learners to investigate unauthorized sudo escalation using realistic Linux and SOC evidence.
- Expected answer: `CTF{john}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - host: `prod-app-01`
   - focus window: `2026-03-06 01:40-01:50 UTC`
2. In `sudo_activity.csv`, identify high/critical sudo operations tied to a non-privileged account.
3. In `auth.log`, confirm the same user performed root-level sudo commands.
4. In `session_commands.csv`, verify the command sequence in one session.
5. In `auditd_execve.log`, validate root command execution with `auid` mapping to same user.
6. In `privileged_access_baseline.txt`, confirm account is restricted from privileged operations.
7. In `change_window_registry.csv`, confirm no approved change ticket (`NO-CHANGE`).
8. In `timeline_events.csv`, confirm SIEM policy-violation escalation and finalize account.

## Key Indicators
- User: `john`
- Unauthorized root actions: `su -`, `useradd backup_temp`, `usermod -aG sudo backup_temp`, `cat /etc/shadow`
- Audit evidence: `uid=0` with `auid=1007`
- Policy context: `john` listed as restricted account
- Change-control mismatch: `NO-CHANGE`

## Suggested Commands / Tools
- `rg "john|NO-CHANGE|backup_temp|/etc/shadow|auid=1007|policy_violation" evidence`
- CSV filtering in:
  - `sudo_activity.csv`
  - `session_commands.csv`
  - `change_window_registry.csv`
  - `timeline_events.csv`
- Optional timeline reconstruction in spreadsheet or `awk`.
