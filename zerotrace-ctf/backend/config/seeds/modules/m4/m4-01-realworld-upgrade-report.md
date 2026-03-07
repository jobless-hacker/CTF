# M4-01 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Availability outage investigation for customer-facing web service.
- Task target: identify the HTTP error code returned during outage.

### Learning Outcome
- Correlate multi-source outage telemetry (web, LB, host, alerts, SIEM).
- Distinguish root-cause signals from noisy operational logs.
- Extract precise customer-visible impact code.

### Previous Artifact Weaknesses
- Minimal single-log challenge with immediate answer exposure.
- No cross-layer outage evidence (web + LB + host + SIEM).
- Limited realism, no noise, and no incident timeline context.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NIST SP 800-61 incident triage and evidence correlation model:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
2. Google SRE monitoring and incident response principles:  
   https://sre.google/sre-book/monitoring-distributed-systems/
3. NGINX error log semantics and upstream failure patterns:  
   https://nginx.org/en/docs/
4. Operational outage workflow: edge/LB/backend error correlation with SIEM escalation.

### Key Signals Adopted
- NGINX critical errors: connection limits and generated `503 Service Unavailable`.
- LB checks confirm backend unhealthy with HTTP 503.
- Status timeseries shows sharp spike in `status_503`.
- SIEM opens incident with explicit outage code.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `nginx_error.log` (**9,804 lines**) noisy error telemetry with outage pivots.
- `web_status_timeseries.csv` (**8,603 lines**) HTTP code distribution over time.
- `lb_health_checks.csv` (**6,203 lines**) load balancer health and code checks.
- `host_resource_metrics.csv` (**7,003 lines**) saturation signals (connections/fds/queue).
- `ops_alerts.jsonl` (**4,401 lines**) operational alerts with one critical outage finding.
- `timeline_events.csv` (**5,004 lines**) SIEM event progression.
- `nginx_runtime.conf` (**9 lines**) runtime config with worker connection limit.
- `web_availability_runbook.txt` (**6 lines**) analyst runbook context.
- Briefing files.

Realism upgrades:
- Multi-layer outage evidence across web, infra, and SIEM.
- High-noise logs with realistic timestamps and false positives.
- Root-cause and impact code derivation path represented.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident ticket and outage window.
2. Pivot in NGINX error log for generated outage response.
3. Confirm matching code in status timeseries and LB health checks.
4. Validate alert and SIEM critical events.
5. Return exact customer-facing HTTP error code.

Expected answer:
- `CTF{503}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m4/m4-01-web-server-crash.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `503 Service Unavailable`, `final_status=503`, `INC-2026-5301`.
- CSV filtering for status, LB, and host metric anomalies.
- JSONL filtering for critical outage alert.
