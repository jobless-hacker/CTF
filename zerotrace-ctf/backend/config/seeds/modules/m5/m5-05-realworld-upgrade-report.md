# M5-05 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Linux privilege-escalation investigation centered on risky SUID binaries.
- Task target: identify the exact SUID binary abused/risky in incident scope.

### Learning Outcome
- Review SUID permission data at scale rather than single-line samples.
- Correlate binary permissions with execution telemetry and alert context.
- Extract the risky binary indicator from a SOC-style evidence chain.

### Previous Artifact Weaknesses
- Minimal one-file artifact with immediate answer exposure.
- No realistic context for privilege-escalation triage workflow.
- No noise/false positives typical in production permission monitoring.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Linux hardening and SUID review practices in enterprise audits.
2. Privilege-escalation detections based on SUID execution and EUID shifts.
3. SOC triage flow: inventory drift -> suspicious execution -> alert -> incident.
4. Runbook-driven binary attribution for containment decisions.

### Key Signals Adopted
- SUID inventory marks `/usr/bin/find` as high-risk on affected node.
- Permission snapshot confirms active SUID bit on `find`.
- Execution audit indicates `find` invocation leading to `euid=0`.
- Alert/SIEM fields explicitly attribute risk to `find`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `suid_inventory.csv` (**7,602 lines**) large permission baseline with one high-risk entry.
- `permissions_snapshot.txt` (**6,804 lines**) host-level file mode snapshot showing SUID `find`.
- `execve_audit.log` (**6,201 lines**) command execution telemetry with escalation pivot.
- `privesc_alerts.jsonl` (**4,301 lines**) alert stream with critical risky-binary marker.
- `timeline_events.csv` (**5,104 lines**) SIEM progression for privilege-escalation case.
- `privesc_prevention_policy.txt` and `suid_abuse_triage_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source Linux DFIR path from file permissions to execution behavior.
- High-noise dataset representative of enterprise telemetry.
- Practical IOC-style answer extraction for SOC analysts.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5505`, node `lin-sec-03`).
2. Detect suspicious SUID entry in inventory/snapshot data.
3. Confirm execution abuse via audit log and EUID context.
4. Validate risky-binary identity in alert and SIEM evidence.
5. Submit binary name.

Expected answer:
- `CTF{find}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m5/m5-05-suid-binary.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `/usr/bin/find`, `euid=0`, `risky_binary`.
- CSV/text review for SUID inventory and permission snapshots.
- JSONL filtering for critical privilege-escalation alerts.
