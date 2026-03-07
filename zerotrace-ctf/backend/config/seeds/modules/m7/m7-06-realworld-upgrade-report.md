# M7-06 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Abuse of public file upload functionality to place an executable server-side script.
- Task target: identify the malicious uploaded file name.

### Learning Outcome
- Correlate upload telemetry, request content, runtime access patterns, and detection outputs.
- Distinguish noisy upload baseline from a true malicious file event.
- Extract the final malicious file indicator used for containment.

### Previous Artifact Weaknesses
- Single simple upload log made the answer immediately obvious.
- No realistic SOC/AppSec multi-source evidence correlation.
- Missing policy, runbook, and alerting context used in real investigations.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Upload endpoint audit streams with high-volume benign file activity.
2. Web access + WAF logs showing suspicious upload and post-upload execution requests.
3. AV/content scan events and upload inventory data for malicious file classification.
4. Security alert stream + SIEM timeline confirming final malicious artifact.

### Key Signals Adopted
- Suspicious upload from `185.191.171.99` with `shell.php`.
- Post-upload access to `/uploads/shell.php?cmd=id`.
- AV/WAF/SIEM agreement on malicious uploaded file `shell.php`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `upload.log` (**7,601 lines**) noisy upload baseline plus suspicious upload event.
- `access.log` (**6,202 lines**) normal web activity + suspicious upload execution request.
- `waf.log` (**6,101 lines**) baseline allow logs and one critical malicious upload alert.
- `upload_inventory.csv` (**5,602 lines**) ingestion metadata with malicious classifier signal.
- `av_scan.log` (**5,401 lines**) clean baseline scans + malicious signature hit.
- `request_capture.txt` multipart upload request containing suspicious file name.
- `upload_alerts.jsonl` (**4,301 lines**) alert stream with malicious upload finding.
- `timeline_events.csv` (**5,004 lines**) SIEM sequence confirming identified file.
- `file_upload_security_policy.txt` and `file_upload_abuse_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- Large noisy dataset across AppSec/SOC data sources.
- Requires correlation of endpoint, runtime, and detection artifacts.
- Includes process/response context (ticket, handoff, policy, runbook).

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5706`).
2. Pivot on suspicious source IP and upload endpoint records.
3. Correlate uploaded file with post-upload execution request.
4. Confirm file via AV/WAF/alerts/SIEM normalized indicators.
5. Submit malicious uploaded file name.

Expected answer:
- `CTF{shell.php}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m7/m7-06-file-upload-abuse.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `shell.php`, `malicious_file`, `webshell_upload_confirmed`, `PHP.WebShell.Generic`.
- Correlate upload + access + WAF + AV + alert/SIEM evidence for final answer.
