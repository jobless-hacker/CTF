# M5-07 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Linux host process investigation for suspicious workload detection.
- Task target: identify anomalous process name tied to compromise symptoms.

### Learning Outcome
- Pivot across process inventory, host metrics, and network telemetry.
- Correlate alert/SIEM evidence with endpoint process snapshots.
- Extract suspicious process IOC from noisy SOC-style data.

### Previous Artifact Weaknesses
- Minimal single-file artifact with direct answer exposure.
- No realistic multi-source host investigation workflow.
- Lacked metric/network correlation expected in operations environments.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Linux endpoint triage for high-CPU unknown process events.
2. Process-to-network correlation for suspicious outbound channels.
3. SOC detection pipeline (host telemetry + alert engine + SIEM timeline).
4. Incident runbook structure for process containment workflows.

### Key Signals Adopted
- Unknown process with extreme CPU utilization.
- Persistent outbound connections on mining-style port.
- Critical alert naming suspicious process field.
- SIEM events correlating performance and network anomalies.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `process_inventory.csv` (**7,602 lines**) process telemetry with one critical suspicious process.
- `ps_aux_snapshot.txt` (**7,402 lines**) realistic process listing evidence.
- `cpu_usage_timeseries.csv` (**6,303 lines**) node-level CPU saturation timeline.
- `network_connections.log` (**5,702 lines**) connection records tying process to remote endpoint.
- `process_alerts.jsonl` (**4,301 lines**) alert stream with suspicious process attribution.
- `timeline_events.csv` (**5,103 lines**) SIEM progression and incident opening.
- `linux_process_monitoring_policy.txt` and `strange_process_triage_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- High-noise, cross-domain telemetry aligned to SOC investigation workflows.
- Host performance + process + network + detection correlation path.
- Non-trivial IOC extraction with clear investigative pivots.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5507`, node `lin-prod-03`).
2. Find anomalous process in inventory and `ps` snapshot evidence.
3. Correlate high CPU windows and top process records.
4. Validate matching process in network and alert telemetry.
5. Confirm SIEM event attribution and submit suspicious process.

Expected answer:
- `CTF{cryptominer}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m5/m5-07-strange-process.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `cryptominer`, `high_cpu_unknown_process`, `tcp/4444`.
- CSV review for process inventory and CPU timelines.
- JSONL filtering for critical process alerts.
