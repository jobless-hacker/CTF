# M6-03 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Plaintext credential exposure in HTTP traffic.
- Task target: identify leaked username observed in cleartext login flow.

### Learning Outcome
- Inspect packet-level HTTP traffic for exposed form credentials.
- Correlate host and proxy telemetry with detection outputs.
- Extract identity indicator from noisy SOC network evidence.

### Previous Artifact Weaknesses
- Single small artifact with straightforward answer visibility.
- No realistic multi-source investigation path.
- Missing operational context for incident response decisions.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. HTTP credential leak triage from packet and proxy telemetry.
2. Correlation of network events with endpoint process activity.
3. Alert + SIEM normalization workflows for leaked identity extraction.
4. Runbook-driven cleartext credential incident handling.

### Key Signals Adopted
- HTTP POST `/login` body carries cleartext `username` and `password`.
- Proxy log confirms cleartext form submission.
- Host process/network mapping links traffic to source workstation process.
- Alert and SIEM fields normalize leaked username.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `http_capture.pcap` (**9,205 lines**) pseudo packet capture export with credential leak frames.
- `http_session_summary.csv` (**7,002 lines**) HTTP session analytics with anomaly flags.
- `proxy_http.log` (**6,401 lines**) proxy telemetry confirming POST to `/login`.
- `workstation_process_net.csv` (**5,702 lines**) host process-to-connection correlation.
- `http_credential_alerts.jsonl` (**4,301 lines**) alert stream with leaked-username field.
- `timeline_events.csv` (**5,003 lines**) SIEM escalation and incident open timeline.
- `cleartext_credential_policy.txt` and `plaintext_credential_leak_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source SOC workflow with high baseline traffic noise.
- Time-correlated host/network/detection artifacts.
- Investigative extraction of identity indicator instead of direct one-liner.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5603`, source `192.168.1.60`).
2. Identify plaintext login body in HTTP capture export.
3. Confirm login anomaly in session summary and proxy evidence.
4. Validate host process and alert/SIEM leaked-username attribution.
5. Submit leaked username.

Expected answer:
- `CTF{john}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m6/m6-03-plaintext-credentials.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `username=john`, `/login`, `leaked_username`.
- CSV/log review for session and process correlation.
- JSONL/SIEM filtering for credential exposure events.
