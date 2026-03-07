# M5-09 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Linux log-tampering investigation focused on evidence destruction attempts.
- Task target: identify the altered-log indicator observed during tampering.

### Learning Outcome
- Correlate authentication, log-management commands, and integrity signals.
- Validate tampering through both raw log evidence and detection pipelines.
- Extract precise indicator value from SOC-style incident artifacts.

### Previous Artifact Weaknesses
- Minimal single-file artifact exposing answer too directly.
- No realistic multi-source chain for tampering confirmation.
- Missing integrity and SIEM correlation context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Linux log-forensics workflow for truncation/deletion detection.
2. SOC integrity monitoring with hash-baseline mismatch analysis.
3. Privileged command auditing correlated with authentication events.
4. SIEM timeline escalation patterns for anti-forensics behavior.

### Key Signals Adopted
- Suspicious root login followed by log-truncate command.
- Explicit syslog truncation marker in timeline.
- Hash mismatch on key log file post-tampering.
- Alert and SIEM fields containing normalized altered indicator.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `syslog_timeline.log` (**9,104 lines**) high-noise system log timeline with tamper sequence.
- `auth.log` (**7,601 lines**) authentication trail including suspicious root access.
- `logrotate_audit.log` (**6,201 lines**) management/audit records including truncate action.
- `log_hash_baseline.csv` (**5,602 lines**) integrity baseline with mismatch evidence.
- `log_integrity_alerts.jsonl` (**4,301 lines**) alert stream with critical altered-indicator field.
- `timeline_events.csv` (**5,103 lines**) SIEM progression from command abuse to incident open.
- `security_log_integrity_policy.txt` and `log_tampering_investigation_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source anti-forensics investigation path.
- Large noisy datasets closer to production SOC pipelines.
- Clear but non-trivial extraction of the expected indicator.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5509`, node `lin-log-04`).
2. Confirm suspicious root access and truncate command.
3. Validate truncation marker and hash mismatch aftermath.
4. Confirm normalized altered indicator via alert/SIEM.
5. Submit altered indicator value.

Expected answer:
- `CTF{log_truncated}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m5/m5-09-log-tampering.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `truncate -s 0`, `log truncated`, `altered_indicator`.
- CSV inspection for hash mismatch validation.
- JSONL/SIEM filtering for tampering indicator extraction.
