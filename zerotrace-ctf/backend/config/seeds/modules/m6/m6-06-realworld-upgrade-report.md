# M6-06 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Command-and-control (C2) beaconing from infected internal host.
- Task target: identify external C2 server IP.

### Learning Outcome
- Detect fixed-interval beaconing behavior in noisy network telemetry.
- Correlate packet, flow, DNS, endpoint, and SIEM evidence.
- Attribute suspicious outbound communication to one external server.

### Previous Artifact Weaknesses
- Single compact artifact with direct answer path.
- No realistic cross-source SOC investigation workflow.
- Missing policy/runbook and incident context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Periodic heartbeat detection in packet and flow records.
2. DNS enrichment mapping suspicious domain to C2 IP.
3. Endpoint network connection telemetry for process-level attribution.
4. Alert + SIEM escalation sequence for C2 confirmation.

### Key Signals Adopted
- Repeated 60-second outbound connection cadence.
- Same destination appears across packet, flow, endpoint, alert, and SIEM data.
- DNS lookup links suspicious domain to command server IP.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `traffic.pcap` (**9,844 lines**) pseudo packet export with heavy baseline and fixed-interval beacon frames.
- `dns_queries.log` (**6,401 lines**) DNS evidence including malicious domain-to-IP resolution.
- `flow_records.csv` (**6,243 lines**) flow telemetry confirming recurring beacon destination.
- `net_connections.csv` (**5,602 lines**) endpoint process-network mapping with suspicious connection row.
- `c2_alerts.jsonl` (**4,301 lines**) detection stream with critical C2 heartbeat alert.
- `timeline_events.csv` (**5,004 lines**) SIEM escalation from beacon confirmation to incident open.
- `outbound_c2_detection_policy.txt` and `c2_beacon_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Large noisy traffic across multiple hosts and destinations.
- Multi-artifact correlation path required to extract final IOC.
- Operational SOC context embedded for incident triage.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5606`, host `192.168.1.90`).
2. Identify fixed-interval beacon traffic in packet/flow data.
3. Confirm destination via DNS and endpoint connection records.
4. Validate final IOC with detection alert and SIEM timeline.
5. Submit C2 server IP.

Expected answer:
- `CTF{198.51.100.44}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m6/m6-06-c2-communication.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `198.51.100.44`, `interval=60s`, `c2_heartbeat_detected`.
- CSV/log correlation across packet, flow, DNS, endpoint, and SIEM artifacts.
- JSONL filtering for critical C2 detection event.
