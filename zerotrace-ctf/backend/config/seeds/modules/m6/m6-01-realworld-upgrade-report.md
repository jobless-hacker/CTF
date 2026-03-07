# M6-01 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Network traffic investigation for suspicious repeated external communication.
- Task target: identify suspicious external destination IP.

### Learning Outcome
- Correlate packet-level evidence with aggregated flow and firewall telemetry.
- Validate suspicious endpoint through alerts and SIEM event progression.
- Practice SOC-style network triage on noisy datasets.

### Previous Artifact Weaknesses
- Minimal single artifact with direct answer visibility.
- No multi-source network correlation path.
- Limited realism for SOC incident workflow training.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Packet-to-flow correlation in network incident response workflows.
2. Firewall + netflow + SIEM triangulation for suspicious endpoint attribution.
3. Alert enrichment with normalized suspicious IP indicators.
4. Incident runbook model for outbound anomaly triage.

### Key Signals Adopted
- Repeated 192.168.1.25 -> 203.0.113.77 TCP/443 sessions.
- Matching flow records and firewall allow-with-alert events.
- Critical alert carrying `suspicious_external_ip`.
- SIEM events confirming repeated unknown external endpoint contact.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `traffic.pcap` (**9,607 lines**) tshark-style packet export with suspicious sequence.
- `netflow_records.csv` (**7,003 lines**) high-noise flow telemetry with suspicious pair.
- `firewall_egress.log` (**6,402 lines**) policy/egress evidence with alerted connections.
- `dns_telemetry.log` (**6,101 lines**) resolver context near incident window.
- `network_alerts.jsonl` (**4,301 lines**) detection stream with normalized suspicious IP field.
- `timeline_events.csv` (**5,004 lines**) SIEM progression and incident open marker.
- `outbound_connection_monitoring_policy.txt` and `suspicious_connection_triage_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source SOC network investigation path with significant operational noise.
- Consistent time-correlated pivots across packet, flow, and detection layers.
- Non-trivial answer extraction requiring evidence correlation.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5601`, source `192.168.1.25`).
2. Pivot in packet export for repeated external destination.
3. Confirm same destination in netflow and firewall telemetry.
4. Validate normalized IP in network alerts and SIEM.
5. Submit suspicious external IP.

Expected answer:
- `CTF{203.0.113.77}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m6/m6-01-suspicious-connection.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `192.168.1.25,203.0.113.77`, `suspicious_external_ip`.
- CSV/log review for flow and firewall corroboration.
- JSONL/SIEM filtering for critical connection alerts.
