# M4-02 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Availability incident caused by extreme inbound traffic flood.
- Task target: classify the attack type.

### Learning Outcome
- Correlate edge/firewall, flow, IDS, LB, and SIEM evidence to classify volumetric attacks.
- Distinguish distributed flood behavior from routine traffic spikes.
- Identify outage-causing attack type from noisy operational datasets.

### Previous Artifact Weaknesses
- Small single-artifact challenge with direct answer visibility.
- No multi-source network telemetry or timeline context.
- Lacked realistic noise/false positives and distributed-source indicators.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NIST SP 800-61 incident analysis and correlation model:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
2. CISA DDoS guidance and operational indicators:  
   https://www.cisa.gov/resources-tools/resources/understanding-denial-service-attacks
3. MITRE ATT&CK network denial context:  
   https://attack.mitre.org/techniques/T1498/
4. SOC/NOC workflow: firewall + netflow + IDS + LB impact + SIEM classification.

### Key Signals Adopted
- Edge firewall shows surge: `Inbound requests/sec: 42000`.
- Multiple source IPs and high unique source counts.
- IDS critical alert: `distributed_syn_flood`, `attack_class=ddos`.
- Service unreachable with LB 503 during flood window.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `firewall_event.log` (**9,803 lines**) edge firewall events and surge markers.
- `edge_rate_timeseries.csv` (**8,604 lines**) requests/packets/source cardinality timeline.
- `netflow_summary.csv` (**7,404 lines**) flow-level transport evidence.
- `ids_alerts.jsonl` (**4,501 lines**) IDS alerts with critical flood classification.
- `lb_service_health.csv` (**6,203 lines**) backend service impact data.
- `timeline_events.csv` (**5,005 lines**) SIEM progression and final classification.
- `mitigation_notes.txt` (**5 lines**) operator response context.
- `network_availability_runbook.txt` (**5 lines**) classification guidance.
- Briefing files.

Realism upgrades:
- Multi-source evidence chain with operational noise and false positives.
- High-cardinality distributed attack indicators across systems.
- Realistic outage progression from detection to incident opening.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and outage window.
2. Confirm distributed surge pattern in firewall/edge/netflow data.
3. Validate IDS critical attack classification and LB impact.
4. Confirm SIEM final classification event.
5. Submit attack type.

Expected answer:
- `CTF{ddos}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m4/m4-02-traffic-flood.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `42000`, `multiple IP addresses`, `distributed_syn_flood`, `attack_class`.
- CSV analysis for edge rates, netflow, and LB health.
- JSONL filtering for critical IDS alert.
