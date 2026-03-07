# M4-07 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Kubernetes workload instability caused by repeated pod/container restarts.
- Task target: identify Kubernetes error classification.

### Learning Outcome
- Correlate kubelet/runtime evidence with pod status and probe behavior.
- Differentiate transient probe issues from sustained restart loops.
- Extract standardized Kubernetes error state from multi-source telemetry.

### Previous Artifact Weaknesses
- Minimal challenge artifact with short direct path to answer.
- Missing realistic cluster telemetry and SIEM context.
- Limited noise and no lifecycle correlation depth.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NIST SP 800-61 incident analysis/correlation approach:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
2. Kubernetes operational troubleshooting patterns for restart loops and pod events.
3. SRE workflow: kubelet logs + pod events + probes + resource metrics + alerts.
4. SOC workflow integrating cluster and SIEM telemetry for outage classification.

### Key Signals Adopted
- Kubelet logs: `Back-off restarting failed container` + `CrashLoopBackOff`.
- Pod events include `BackOff` and `CrashLoopBackOff` reasons.
- Container status shows `Waiting` with `last_reason=CrashLoopBackOff`.
- Alerts and SIEM classify error as `crashloopbackoff`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `kubelet.log` (**9,403 lines**) node-level kubelet/runtime messages.
- `pod_events.jsonl` (**7,602 lines**) pod lifecycle events and warnings.
- `container_status_matrix.csv` (**7,003 lines**) container state/restart data.
- `probe_failures.csv` (**6,403 lines**) liveness/readiness probe outcomes.
- `pod_resource_metrics.csv` (**6,803 lines**) resource/restart/oom context.
- `cluster_alerts.jsonl` (**4,301 lines**) alert stream with k8s error label.
- `timeline_events.csv` (**5,004 lines**) SIEM progression and incident open.
- `deployment_web_app.yaml` (**16 lines**) workload deployment context.
- `k8s_outage_runbook.txt` (**5 lines**) triage guidance.
- Briefing files.

Realism upgrades:
- Multi-source cluster investigation resembling real SRE/SOC incident response.
- Noisy operational data with meaningful pivots.
- Timeline-driven classification path from restart symptom to root label.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and affected node/workload.
2. Confirm restart loop in kubelet and pod event streams.
3. Validate waiting state/restart growth and probe failures.
4. Correlate alert/siem labels for canonical Kubernetes error.
5. Submit normalized error value.

Expected answer:
- `CTF{crashloopbackoff}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m4/m4-07-kubernetes-restart-loop.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `CrashLoopBackOff`, `Back-off restarting failed container`, `k8s_error`, `INC-2026-5389`.
- CSV analysis for container status and probe failure trends.
- JSONL filtering for warning pod events and critical cluster alerts.
