# M2-05 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Off-hours data exfiltration investigation through network and endpoint correlation.
- Task target: identify the file that was exfiltrated.

### Learning Outcome
- Correlate egress telemetry, proxy upload metadata, endpoint file activity, and DLP findings.
- Validate incident context against user permissions and data egress policy.
- Extract the exact exfiltrated filename from noisy SOC evidence.

### Previous Artifact Weaknesses
- Single short transfer log with direct answer exposure.
- No realistic telemetry volume, no false positives, and no cross-source validation.
- No policy or identity context to support investigation logic.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Exfiltration Over Web Service / Exfiltration Over C2 Channel:  
   https://attack.mitre.org/techniques/T1567/  
   https://attack.mitre.org/techniques/T1041/
2. NIST SP 800-61 incident handling and evidence correlation:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. DLP and endpoint/network triage patterns used in SOC workflows (proxy + DLP + host + SIEM timeline correlation).

### Key Signals Adopted
- Large outbound after-hours transfer to unapproved external IP `198.51.100.7`.
- Proxy upload metadata includes filename parameter `payroll.xlsx`.
- Endpoint file audit shows access/copy/prepare operations for `payroll.xlsx` just before upload.
- DLP raises high/critical alerts for restricted payroll PII data.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `netflow_egress.csv` (**11,804 lines**) outbound flow telemetry.
- `proxy_egress.log` (**9,303 lines**) egress web/upload metadata.
- `file_access_audit.csv` (**7,604 lines**) endpoint file operations.
- `dlp_alerts.jsonl` (**4,302 lines**) high-volume DLP signal stream.
- `timeline_events.csv` (**4,906 lines**) SIEM event correlation.
- `user_context.csv` (**6 lines**) user role/privilege context.
- `data_egress_policy.txt` (**5 lines**) policy baseline.
- Briefing files.

Realism upgrades:
- Multi-source SOC evidence with noise and false positives.
- Time-window correlation around attack sequence.
- Realistic policy and identity constraints to support analyst decision-making.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident ticket and scope window (~23:50-23:53 UTC).
2. Identify unapproved external destination and large transfer in netflow/proxy logs.
3. Pivot to endpoint file-access records for same host/user/time.
4. Confirm DLP high/critical alerts and filename.
5. Validate user privileges and policy violations.
6. Return exfiltrated filename.

Expected answer:
- `CTF{payroll.xlsx}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m2/m2-05-midnight-upload.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for pivots (`198.51.100.7`, `sarah.k`, `payroll.xlsx`, `policy_violation`).
- CSV filtering by host/user/timestamp for netflow and endpoint events.
- `jq` for extracting high/critical DLP alerts in JSONL.
