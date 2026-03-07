# M6-05 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Malware delivery through direct executable download from suspicious domain.
- Task target: identify the malicious file name.

### Learning Outcome
- Investigate suspicious web downloads across proxy, DNS, endpoint, and SIEM data.
- Separate benign software downloads from malicious executable retrieval.
- Use correlation workflow aligned to SOC malware-download triage.

### Previous Artifact Weaknesses
- Single small proxy log with direct answer visibility.
- No realistic noise, false positives, or cross-telemetry validation.
- Missing incident context and operational workflow guidance.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Enterprise proxy logs containing mixed software/document downloads.
2. DNS query evidence validating suspicious domain resolution timing.
3. Endpoint download inventory with file-level metadata and verdicts.
4. SIEM and alert-pipeline correlation to confirm malicious file identity.

### Key Signals Adopted
- Suspicious executable fetched over HTTP from `malicious-domain.ru`.
- Endpoint history records same file with malicious verdict.
- Alert stream normalizes `suspicious_file` for final extraction.
- SIEM timeline confirms malware file identification event.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `proxy_http.log` (**7,601 lines**) noisy proxy telemetry with one malicious executable download.
- `dns_queries.log` (**6,201 lines**) DNS evidence including suspicious domain lookup.
- `download_history.csv` (**5,602 lines**) endpoint download inventory and hash metadata.
- `egress_flow.csv` (**6,002 lines**) egress transfer records supporting download event.
- `download_alerts.jsonl` (**4,301 lines**) alert stream with one critical malware download detection.
- `timeline_events.csv` (**5,004 lines**) SIEM sequence from suspicious activity to incident open.
- `web_download_protection_policy.txt` and `malware_download_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- High-volume mixed benign traffic and false-positive review entries.
- Multi-source correlation path with consistent IOC pivots.
- SOC process context and triage guidance embedded.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5605`, host `WKSTN-432` / `192.168.20.32`).
2. Locate suspicious proxy URL and file path.
3. Confirm domain resolution and endpoint download artifact.
4. Validate alert/SIEM correlation for identified malicious file.
5. Submit malicious file name.

Expected answer:
- `CTF{trojan.exe}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m6/m6-05-malware-download.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `malicious-domain.ru`, `trojan.exe`, `malware_download_detected`.
- CSV/log correlation for host, user, and timestamp alignment.
- JSONL/SIEM filtering to confirm final malicious file indicator.
