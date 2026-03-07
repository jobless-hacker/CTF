# M5-03 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Shell forensics and command-line triage on a compromised Linux account.
- Task target: identify the command used to download a malicious script.

### Learning Outcome
- Correlate shell history with audit command telemetry and network egress logs.
- Validate suspicious command behavior through process lineage and SIEM context.
- Extract command-family answer from noisy real-world evidence.

### Previous Artifact Weaknesses
- Single minimal artifact where answer is nearly immediate.
- No cross-source correlation path typical of SOC investigations.
- Missing realistic noise and operational incident context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Linux DFIR shell-analysis workflow (`bash_history` + audit `EXECVE` events).
2. Egress correlation model (proxy logs linked to command execution timestamp).
3. SIEM timeline escalation for script download + execution events.
4. SOC runbook style for compromised shell triage and command-family attribution.

### Key Signals Adopted
- Interactive shell command downloading script from external endpoint.
- Audit trail confirming exact command invocation.
- Proxy egress event matching same timestamp/path.
- Alert metadata with normalized command family.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `bash_history` (**9,273 lines**) noisy user shell history with suspicious sequence.
- `command_exec_audit.log` (**7,803 lines**) command execution telemetry with exact payload fetch.
- `proxy_egress.log` (**6,401 lines**) outbound request evidence for retrieved script.
- `process_lineage.csv` (**5,203 lines**) process ancestry around suspicious execution.
- `command_alerts.jsonl` (**4,101 lines**) SOC alerts with `command_family` classification.
- `timeline_events.csv` (**5,004 lines**) SIEM event chain and incident open marker.
- `linux_shell_monitoring_policy.txt` and `compromised_shell_triage_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source evidence with substantial operational noise.
- Timeline-based pivots rather than single-line answer giveaway.
- SOC-consumable artifacts aligned to incident-response workflow.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5503`, `lin-web-03`).
2. Find suspicious command sequence in `bash_history`.
3. Confirm exact download command in `command_exec_audit.log`.
4. Corroborate external fetch in `proxy_egress.log`.
5. Validate command family in `command_alerts.jsonl` and SIEM timeline.
6. Submit download command used.

Expected answer:
- `CTF{wget}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m5/m5-03-bash-history-review.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `recon.sh`, `wget`, `external_script_download`.
- CSV review for `process_lineage.csv` and `timeline_events.csv`.
- JSONL filter for `command_family` field in command alerts.
