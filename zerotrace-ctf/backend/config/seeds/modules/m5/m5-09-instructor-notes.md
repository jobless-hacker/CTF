# M5-09 Instructor Notes

## Objective
- Train learners to detect Linux log tampering and extract altered-log indicator.
- Expected answer: `CTF{log_truncated}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5509`
   - node: `lin-log-04`
2. In `syslog_timeline.log`, identify suspicious sequence and truncation marker.
3. In `auth.log`, confirm root login timing.
4. In `logrotate_audit.log`, confirm explicit truncate command on syslog.
5. In `log_hash_baseline.csv`, confirm integrity mismatch for `/var/log/syslog`.
6. In `log_integrity_alerts.jsonl` and `timeline_events.csv`, extract normalized altered indicator.
7. Submit altered indicator value.

## Key Indicators
- Access/tamper pivots:
  - `Accepted password for root from 203.0.113.72`
  - `truncate -s 0 /var/log/syslog`
  - `*** log truncated ***`
- Integrity pivot:
  - `/var/log/syslog ... mismatch`
- Alert/SIEM pivots:
  - `"altered_indicator":"log_truncated"`
  - `log_tamper_marker ... log_truncated`

## Suggested Commands / Tools
- `rg "truncate -s 0|log truncated|altered_indicator|mismatch" evidence`
- Review:
  - `evidence/logs/syslog_timeline.log`
  - `evidence/logs/logrotate_audit.log`
  - `evidence/logs/log_hash_baseline.csv`
  - `evidence/security/log_integrity_alerts.jsonl`
