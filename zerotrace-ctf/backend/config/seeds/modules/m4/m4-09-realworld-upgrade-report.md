# M4-09 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Load balancer availability incident caused by unhealthy backend target.
- Task target: identify affected backend service name.

### Learning Outcome
- Correlate LB health checks, upstream proxy behavior, and backend probes.
- Distinguish broad transient errors from persistent backend failure.
- Extract specific impacted backend from noisy telemetry.

### Previous Artifact Weaknesses
- Small direct artifact with low investigation depth.
- Missing realistic proxy/pool/registration/SIEM evidence chain.
- Limited noise and weak timeline context.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NIST SP 800-61 incident evidence-correlation methodology:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
2. SRE load balancer outage triage patterns (health checks + probe failures + traffic shift).
3. Reverse-proxy upstream diagnostics for backend service failures.
4. SOC practice for correlating LB telemetry and SIEM incident timelines.

### Key Signals Adopted
- LB checks explicitly show `backend server api01 unhealthy`.
- Proxy logs show upstream `api01` returning 503 and downstream 502.
- Target registration logs remove `api01` from rotation.
- Alerts/SIEM classify `api01` as affected backend.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `lb_health_checks.csv` (**9,204 lines**) LB node health telemetry.
- `upstream_proxy.log` (**8,402 lines**) request/upstream response evidence.
- `backend_pool_stats.csv` (**7,004 lines**) backend utilization/error state metrics.
- `backend_probe_results.csv` (**6,403 lines**) backend /health probe outcomes.
- `target_registration.log` (**5,202 lines**) target health/rotation transitions.
- `lb_alerts.jsonl` (**4,301 lines**) alert stream with affected backend field.
- `timeline_events.csv` (**5,004 lines**) SIEM progression and incident record.
- `lb_backend_config.conf` (**5 lines**) backend definition context.
- `lb_outage_runbook.txt` (**5 lines**) operational decision guidance.
- Briefing files.

Realism upgrades:
- Full LB outage chain from unhealthy checks to traffic rerouting.
- Multi-source noisy telemetry with clear root backend pivots.
- Practical SOC+SRE investigation flow.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and outage window.
2. Identify consistently unhealthy backend in LB checks.
3. Confirm upstream proxy and probe failures for same backend.
4. Validate removal from rotation and alert/siem classification.
5. Submit exact affected backend service name.

Expected answer:
- `CTF{api01}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m4/m4-09-load-balancer-failure.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `api01`, `backend server api01 unhealthy`, `affected_backend`.
- CSV analysis for LB health, backend probes, and pool state.
- JSONL filtering for critical backend_service_down alerts.
