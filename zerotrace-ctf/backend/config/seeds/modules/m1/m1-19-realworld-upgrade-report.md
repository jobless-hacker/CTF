# M1-19 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Kubernetes workload instability causing service interruption.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate cluster control-plane events with node/runtime and user-impact telemetry.
- Connect deployment configuration drift to restart storms.
- Distinguish operational outage from data leak or integrity-tampering scenarios.

### Previous Artifact Weaknesses
- Small evidence set with straightforward answer path.
- Limited realistic noise for production clusters.
- Weak linkage between rollout, resource limits, and customer-facing outage.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. Kubernetes Pod lifecycle and restart behavior:  
   https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
2. Kubernetes resource management (requests/limits, OOM behavior):  
   https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
3. Liveness and readiness probe behavior:  
   https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
4. kubelet operational log context:  
   https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/
5. NIST SP 800-61 incident handling process for triage/correlation:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final

### Key Signals Adopted
- `OOMKilled` and `CrashLoopBackOff` spikes on payment pods.
- Kubelet probe failures (`HTTP 503`) and restart backoff events.
- Metrics showing memory usage near/exceeding incorrectly reduced limits.
- Deployment revision changed memory limit to `128Mi` before incident.
- Ingress probes showing 503/timeouts during the same window.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `kube_events.log` (**9,404 lines**) cluster event stream with noise and incident pivots.
- `pod_restart_timeseries.csv` (**6,105 lines**) restart-state progression.
- `kubelet_node_logs.log` (**7,204 lines**) node-level runtime/probe evidence.
- `metrics_samples.csv` (**5,304 lines**) CPU/memory/limit/restart telemetry.
- `ingress_probe_results.csv` (**4,605 lines**) user-facing availability outcomes.
- `deployment_revisions.csv` (**2,203 lines**) rollout and config history.
- `change_records.csv` (**1,703 lines**) operational approval/rollback context.
- Briefing files for investigation flow.

Realism upgrades:
- Multi-source cluster + node + user-impact telemetry.
- High-volume baseline noise and benign warnings.
- Time-correlated causal chain: rollout -> OOM -> restart loops -> service outage.
- Includes remediation revision and rollback context.

## Step 4 - Flag Engineering

Expected investigation path:
1. Start from incident ticket and identify affected deployment/time window.
2. Confirm restart-loop signals (`OOMKilled`, `CrashLoopBackOff`) in events and restart series.
3. Validate node probe failures in kubelet logs.
4. Correlate metrics with reduced memory limit.
5. Confirm rollout revision with mistaken `128Mi` limit and subsequent rollback.
6. Validate user impact via ingress probes (503/timeouts).
7. Classify primary CIA impact.

Expected flag:
- `CTF{availability}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-19-kubernetes-crash.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for restart and OOM pivots.
- CSV filtering for rollout and probe windows.
- Timeline stitching across events, kubelet, metrics, and ingress probes.
