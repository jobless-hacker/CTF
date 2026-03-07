# M1-04 Instructor Notes

## Objective
- Train learners to detect and prove security-log tampering on Linux.
- Expected answer: `CTF{integrity}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and define suspicious window.
2. Inspect `auth.log` for root session and unusual command flow.
3. Pivot to `root_bash_history.txt` for possible log-clear command.
4. Confirm at syscall level in `audit.log`:
   - `comm="truncate"` with `/var/log/auth.log`
   - associated `PATH` and `PROCTITLE` records
5. Validate `rsyslog_messages.log` truncation detection messages.
6. Correlate with `log_file_metadata_timeline.csv` (same inode, size drop to 0).
7. Filter SIEM CSV to distinguish:
   - normal auth failures/noise
   - true high-severity `LOG_TAMPER` event
8. Classify primary CIA impact.

## Key Indicators
- File: `/var/log/auth.log`
- Command: `truncate -s 0 /var/log/auth.log`
- Actor context: `root` session from `10.40.8.19`
- Audit event pivot: `audit(...:88001)` with `log_integrity` key
- Metadata pivot: inode `318221`, size `184320 -> 0`

## Suggested Commands / Tools
- `rg "truncate|auth.log|log_integrity|88001" audit.log auth.log root_bash_history.txt`
- `rg "truncation detected|output position reset" rsyslog_messages.log`
- `rg "LOG_TAMPER|privileged_login_after_hours" normalized_security_events.csv`
- Timeline sort/filter by timestamp across all files

