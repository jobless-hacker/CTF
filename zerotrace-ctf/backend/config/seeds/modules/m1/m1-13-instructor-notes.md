# M1-13 Instructor Notes

## Objective
- Train learners to investigate a SIEM-detected host log-tampering sequence.
- Expected answer: `CTF{integrity}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and identify scope:
   - host: `server01`
   - file: `/var/log/auth.log`
   - key window: around `2026-03-06T12:41`
2. Pivot in SIEM evidence:
   - `alerts_stream.jsonl` for critical `linux_security_log_anomaly`
   - `timeline.csv` for correlated process events
   - `rule_engine_metrics.csv` for event-rate collapse evidence
3. Validate host-level causality:
   - `auditd_full.log` shows `truncate` against `/var/log/auth.log`
   - `sudo_session.log` shows privileged execution context
4. Confirm file integrity impact:
   - `auth_log_size_timeseries.csv` sudden drop to zero
5. Separate benign noise:
   - expected logrotate patterns
   - low-severity auth-failure and maintenance alerts
6. Classify CIA impact.

## Key Indicators
- Incident alert: `ALRT-INC-1301`
- Process chain:
  - `tail -n 50 /var/log/auth.log`
  - `truncate -s 0 /var/log/auth.log`
- Log-size behavior: abrupt 100% drop then small rewrites
- Root session source: `10.40.8.19`

## Suggested Commands / Tools
- `rg "ALRT-INC-1301|server01|linux_security_log_anomaly" evidence/siem`
- `rg "truncate|/var/log/auth.log|log_clear|99441" evidence/host`
- CSV filter by timestamp in:
  - `evidence/siem/timeline.csv`
  - `evidence/host/auth_log_size_timeseries.csv`
  - `evidence/siem/rule_engine_metrics.csv`
