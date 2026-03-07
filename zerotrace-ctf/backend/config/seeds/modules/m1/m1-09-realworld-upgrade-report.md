# M1-09 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Volumetric/distributed denial-of-service impact investigation.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate perimeter surges with flow telemetry and service degradation.
- Separate benign scanner/load-test noise from real attack behavior.
- Use distributed-source and SYN/ACK imbalance evidence to justify conclusion.

### Previous Artifact Weaknesses
- Small evidence footprint and short path to answer.
- Limited cross-correlation between network and service layers.
- Minimal noisy background traffic.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NetFlow v9 export model (flow telemetry baseline):  
   https://www.rfc-editor.org/rfc/rfc3954
2. IPFIX information model (flow-field semantics):  
   https://www.rfc-editor.org/rfc/rfc7011
3. HTTP semantics for service-level error states (including 503):  
   https://www.rfc-editor.org/rfc/rfc9110
4. MITRE ATT&CK Network Denial of Service technique (T1498):  
   https://attack.mitre.org/techniques/T1498/
5. NIST SP 800-61 incident handling lifecycle (triage/correlation model):  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final

### Key Signals Adopted
- Firewall `conn_per_sec` spike and SYN-heavy ratios.
- NetFlow surge with high source-IP diversity and low ACK ratio.
- LB health collapse and uptime timeouts in same window.
- Noisy WAF probes and scheduled load tests as false positives.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `edge_firewall.log` (**15,400 lines**) perimeter telemetry with incident surge.
- `netflow_timeseries.csv` (**9,101 lines**) high-volume flow trends.
- `waf_events.jsonl` (**5,200 lines**) noisy app-layer probe context.
- `load_balancer_health.csv` (**6,201 lines**) backend degradation timeline.
- `uptime_monitor.csv` (**3,501 lines**) external probe outcomes.
- `normalized_events.csv` (**6,904 lines**) SIEM stream with true + false positives.
- `top_talkers.csv`, `netflow_summary.txt`, incident ticket, analyst handoff, mitigation notes.

Realism upgrades:
- Multi-source network + service evidence.
- High-volume datasets with benign bursts and scanner noise.
- Time correlation required to prove service outage cause.
- Distributed attack pattern embedded in realistic baseline traffic.

## Step 4 - Flag Engineering

Expected investigation path:
1. Confirm surge window and perimeter impact in firewall logs.
2. Validate distributed SYN-heavy flow characteristics in NetFlow.
3. Correlate service degradation in LB and uptime monitors.
4. Discard benign load-test and routine scanner noise.
5. Classify primary CIA impact.

Expected flag:
- `CTF{availability}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-09-firewall-ddos-alert.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for surge markers and incident timestamps.
- CSV filtering for flow/LB/uptime trend alignment.
- `jq` for WAF JSONL triage.
- Timeline stitching to justify outage attribution.
