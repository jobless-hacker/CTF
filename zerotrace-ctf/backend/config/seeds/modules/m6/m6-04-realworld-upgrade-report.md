# M6-04 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- External reconnaissance via multi-port scanning.
- Task target: identify the single scanning source IP.

### Learning Outcome
- Detect port scan behavior from noisy perimeter telemetry.
- Correlate firewall, IDS, flow, and SIEM evidence.
- Follow SOC triage policy and runbook for recon incidents.

### Previous Artifact Weaknesses
- Minimal single-log artifact with obvious answer.
- No realistic volume/noise or cross-source correlation.
- Lacked analyst workflow context and incident framing.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Firewall deny logs showing rapid probes across many destination ports.
2. IDS scan signatures (Nmap/recon sweep) correlated to same source.
3. NetFlow-style records confirming SYN attempts to multiple services.
4. SIEM timeline + detection alert stream for incident escalation.

### Key Signals Adopted
- One external source probes many TCP services in short window.
- High unique-port count with elevated scan score.
- Matching source appears in firewall, IDS, flow, alerts, and SIEM.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `firewall.log` (**9,422 lines**) perimeter deny stream with noisy baseline and scan burst.
- `connection_attempt_summary.csv` (**6,902 lines**) source/target port diversity and scan score.
- `ids_alerts.log` (**6,102 lines**) signature output with recon alerts.
- `flow_records.csv` (**6,205 lines**) NetFlow-style SYN telemetry.
- `port_scan_alerts.jsonl` (**4,301 lines**) alert pipeline with one critical scan detection.
- `timeline_events.csv` (**5,004 lines**) SIEM sequence from detection to incident open.
- `perimeter_recon_policy.txt` and `port_scan_triage_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Large-volume noisy telemetry with one true positive.
- Multi-source correlation path instead of single direct clue.
- SOC process context (policy, runbook, incident ticket).

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5604`, target `10.30.0.12`).
2. Pivot across firewall and summary files for high port diversity.
3. Confirm scan signature in IDS and detection alert stream.
4. Validate same source in flow and SIEM correlation events.
5. Submit scanning source IP.

Expected answer:
- `CTF{185.199.110.42}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m6/m6-04-port-scan.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `185.199.110.42`, `possible_scan`, `port_scan_detected`.
- CSV/log correlation across firewall, flow, summary, and SIEM.
- JSONL filtering for critical scan detection event.
