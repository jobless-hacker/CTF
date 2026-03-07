# M1-15 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Ransomware-style host impact causing widespread loss of access to business files.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate endpoint process behavior with file-system impact and operational outage signals.
- Distinguish noisy endpoint detections from confirmed ransomware impact.
- Tie failed recovery attempts to real user/business unavailability.

### Previous Artifact Weaknesses
- Minimal files and linear path to answer.
- Low realism for SOC/IR triage at scale.
- Limited noise, weak timeline correlation, and little operational impact context.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK T1486 (Data Encrypted for Impact):  
   https://attack.mitre.org/techniques/T1486/
2. MITRE ATT&CK T1490 (Inhibit System Recovery):  
   https://attack.mitre.org/techniques/T1490/
3. CISA StopRansomware guide (investigation and response signals):  
   https://www.cisa.gov/stopransomware
4. Microsoft `vssadmin` command reference (shadow copy behavior):  
   https://learn.microsoft.com/windows-server/administration/windows-commands/vssadmin
5. NIST SP 800-61 Rev.2 incident handling lifecycle:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final

### Key Signals Adopted
- Process chain from user app -> PowerShell -> ransomware binary (`cipherlock.exe`).
- Shadow-copy deletion behavior (`vssadmin delete shadows /all /quiet`).
- Mass extension change to `.vault` with user access failures.
- Helpdesk surge and SOC recovery failures indicating business disruption.
- EDR note for no confirmed large exfiltration in impact window.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `process_creation.log` (**8,805 lines**) endpoint process telemetry with benign baseline + attack chain.
- `file_impact_timeline.csv` (**11,263 lines**) high-volume file operations and mass encryption sequence.
- `edr_alerts.jsonl` (**7,603 lines**) noisy endpoint detections with critical ransomware signals.
- `smb_activity.csv` (**6,204 lines**) file-share traffic with encryption write spike.
- `service_desk_tickets.csv` (**3,643 lines**) user-impact surge and triage queue context.
- `recovery_attempts.log` (**2,904 lines**) SOC/IT recovery workflow and failures.
- `snapshot_inventory.csv` (**3,103 lines**) restore readiness and shadow-copy loss state.
- Briefing artifacts and ransom note.

Realism upgrades:
- Large multi-source evidence, not single-file puzzles.
- Routine endpoint and ticketing noise to force triage discipline.
- Time-correlated host + operations evidence for realistic IR workflow.
- False-positive/benign automation context included.

## Step 4 - Flag Engineering

Expected investigation path:
1. Use incident ticket/handoff to set scope (`WS-FIN-22`, `03:14Z` window).
2. Confirm suspicious process chain and recovery-inhibition commands.
3. Validate mass `.vault` extension change and post-encryption access failures.
4. Correlate EDR critical events with SMB write spike and helpdesk impact.
5. Confirm failed restore path (shadow copy removal, restore failures).
6. Classify primary CIA impact.

Expected flag:
- `CTF{availability}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-15-ransomware-lock.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for process and impact pivots.
- CSV filtering for time-window correlation.
- `jq` for EDR JSONL triage.
- Timeline stitching across endpoint, SMB, and recovery evidence.
