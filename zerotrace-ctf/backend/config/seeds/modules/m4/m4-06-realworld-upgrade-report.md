# M4-06 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Containerized service outage caused by abrupt container termination.
- Task target: identify crashed container name.

### Learning Outcome
- Correlate runtime logs, container events, probes, and SIEM alerts.
- Distinguish noisy container operations from primary outage event.
- Extract definitive crashed container identity from multi-source data.

### Previous Artifact Weaknesses
- Small single-log challenge with low investigative depth.
- No orchestration/runtime context or service-impact correlation.
- Minimal noise and no realistic timeline progression.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NIST SP 800-61 incident analysis and cross-source correlation:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
2. Docker runtime/event operational patterns (`die`, `restart`, daemon errors).
3. SRE container outage triage model: runtime failure + probe impact + alert escalation.
4. SOC workflow integrating platform telemetry and SIEM incidenting.

### Key Signals Adopted
- Daemon error: `container web-app exited unexpectedly`.
- Event stream shows `web-app` with `die` then failed `restart`.
- Probes return `502 upstream_container_down` after crash.
- Alerts/SIEM classify same container as crash root.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `dockerd.log` (**9,203 lines**) runtime daemon logs with crash indicators.
- `container_events.jsonl` (**7,602 lines**) event stream including `die`/`restart`.
- `container_inventory.csv` (**6,802 lines**) state snapshots with exited container.
- `probe_results.csv` (**6,403 lines**) service health probes and outage impact.
- `container_resource_metrics.csv` (**7,003 lines**) metrics and restart/oom context.
- `container_alerts.jsonl` (**4,301 lines**) alert feed with `crashed_container`.
- `timeline_events.csv` (**5,004 lines**) SIEM progression and incident opening.
- `docker-compose-snippet.yml` (**7 lines**) service config context.
- `container_crash_runbook.txt` (**5 lines**) operational triage guidance.
- Briefing files.

Realism upgrades:
- Multi-layer outage evidence from runtime to customer impact.
- High-noise operational records with targeted pivots.
- Clear incident timeline matching real platform response flow.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and node/time window.
2. Confirm crash in daemon log and container event stream.
3. Validate exited state and failed restart in inventory/metrics.
4. Correlate service probes, alert feed, and SIEM events.
5. Return exact crashed container name.

Expected answer:
- `CTF{web-app}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m4/m4-06-container-crash.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `web-app`, `exited unexpectedly`, `status\":\"die`, `crashed_container`.
- CSV analysis for container state and probe degradation.
- JSONL filtering for critical container crash alerts/events.
