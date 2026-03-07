# M6-08 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Data exfiltration via high-volume outbound transfer.
- Task target: identify external exfiltration destination IP.

### Learning Outcome
- Detect suspicious egress volume patterns from noisy traffic baselines.
- Correlate flow, firewall, proxy, endpoint, DLP, and SIEM evidence.
- Extract destination IOC used for exfiltration.

### Previous Artifact Weaknesses
- Single minimal netflow artifact with direct answer path.
- No realistic multi-source SOC investigation workflow.
- No incident context, policy guidance, or false-positive background.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. NetFlow outliers with unusually large byte counts.
2. Firewall/proxy telemetry confirming same destination and transfer event.
3. Endpoint process transfer metadata for attribution.
4. DLP alert pipeline and SIEM timeline for IOC normalization.

### Key Signals Adopted
- One 80,000,000-byte outbound transfer from `192.168.1.45`.
- Destination consistently appears as `203.0.113.200` across artifacts.
- DLP and SIEM explicitly confirm exfiltration destination IOC.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `netflow.log` (**7,602 lines**) high-volume flow telemetry with exfiltration outlier.
- `egress_firewall.log` (**6,201 lines**) firewall perspective on suspicious outbound transfer.
- `proxy_transfer.log` (**5,901 lines**) upload activity with suspicious bulk POST.
- `transfer_summary.csv` (**5,602 lines**) endpoint process/file transfer context.
- `dlp_alerts.jsonl` (**4,301 lines**) DLP detection stream with one critical event.
- `timeline_events.csv` (**5,004 lines**) SIEM sequence from anomaly to incident open.
- `outbound_data_exfiltration_policy.txt` and `data_exfiltration_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Large noisy data with many benign transfers and review-worthy events.
- Multi-artifact correlation required for final IOC extraction.
- SOC operational context embedded in policy/runbook/incident files.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5608`, source `192.168.1.45`).
2. Identify high-byte outlier in NetFlow and matching firewall/proxy entries.
3. Confirm process attribution in endpoint transfer summary.
4. Validate IOC in DLP alert and SIEM destination confirmation.
5. Submit exfiltration destination IP.

Expected answer:
- `CTF{203.0.113.200}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m6/m6-08-data-exfiltration.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `203.0.113.200`, `80000000`, `data_exfiltration_detected`.
- CSV/log correlation across network + endpoint + security pipelines.
- JSONL/SIEM filtering for exfil destination confirmation.
