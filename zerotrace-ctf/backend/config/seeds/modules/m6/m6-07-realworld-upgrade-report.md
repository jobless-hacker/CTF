# M6-07 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- DNS tunneling / DNS-based exfiltration through suspicious query patterns.
- Task target: identify registered exfiltration domain.

### Learning Outcome
- Detect exfiltration indicators in noisy DNS traffic.
- Correlate packet, resolver, endpoint, alert, and SIEM telemetry.
- Distill suspicious FQDN activity to registered domain indicator.

### Previous Artifact Weaknesses
- Single compact artifact made answer extraction too direct.
- No realistic multi-source SOC workflow or noisy baseline.
- Missing incident process context and triage guidance.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. High-entropy TXT query bursts in packet/resolver telemetry.
2. Repetitive subdomain labels indicating chunked exfiltration.
3. Endpoint process attribution for suspicious DNS behavior.
4. Alert and SIEM enrichment with registered domain extraction.

### Key Signals Adopted
- Suspicious FQDN burst: `*.data.exfiltration.evil.com`.
- Source host `192.168.1.90` repeatedly querying TXT records.
- Alert and SIEM outputs normalize final domain as `evil.com`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `dns_capture.pcap` (**9,662 lines**) pseudo packet export with heavy baseline and TXT burst sequence.
- `dns_query_summary.csv` (**6,802 lines**) aggregation including entropy/label-length anomaly.
- `resolver.log` (**6,101 lines**) resolver telemetry with suspicious burst pivot.
- `process_dns_activity.csv` (**5,602 lines**) endpoint process-level DNS activity.
- `dns_exfil_alerts.jsonl` (**4,301 lines**) detection stream with critical exfiltration event.
- `timeline_events.csv` (**5,004 lines**) SIEM sequence confirming registered domain.
- `dns_exfiltration_monitoring_policy.txt` and `dns_exfiltration_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Large noisy DNS telemetry and false-positive style monitoring events.
- Multi-source correlation required to derive final answer.
- SOC operational context embedded with policy + runbook.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5607`, source `192.168.1.90`).
2. Identify suspicious TXT burst and encoded labels in DNS capture.
3. Confirm anomaly in summary/resolver/endpoint process data.
4. Validate registered domain from alert and SIEM enrichment.
5. Submit exfiltration domain.

Expected answer:
- `CTF{evil.com}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m6/m6-07-suspicious-dns-query.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `data.exfiltration.evil.com`, `registered_domain`, `dns_exfiltration_detected`.
- CSV/log analysis for entropy, query burst, and source host correlation.
- JSONL/SIEM filtering for confirmed registered domain indicator.
