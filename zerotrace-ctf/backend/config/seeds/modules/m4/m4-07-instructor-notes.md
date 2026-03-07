# M4-07 Instructor Notes

## Objective
- Train learners to investigate Kubernetes restart loops and identify the canonical error label.
- Expected answer: `CTF{crashloopbackoff}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5389`
   - node: `k8s-node-04`
2. In `kubelet.log`, locate:
   - `Back-off restarting failed container web-app`
   - `entered CrashLoopBackOff`
3. In `pod_events.jsonl`, identify warning reasons `BackOff` and `CrashLoopBackOff`.
4. In `container_status_matrix.csv`, confirm `Waiting` with `last_reason=CrashLoopBackOff`.
5. In `probe_failures.csv`, verify liveness/readiness failures during loop.
6. In `pod_resource_metrics.csv`, inspect restart and oom indicators.
7. In `cluster_alerts.jsonl` and `timeline_events.csv`, confirm classification (`k8s_error=crashloopbackoff`).
8. Submit `CTF{crashloopbackoff}`.

## Key Indicators
- Incident ID: `INC-2026-5389`
- Kubelet marker: `Back-off restarting failed container`
- Pod event marker: `reason=CrashLoopBackOff`
- Alert marker: `k8s_error = crashloopbackoff`
- SIEM marker: `pod_restart_loop_detected`

## Suggested Commands / Tools
- `rg "CrashLoopBackOff|Back-off restarting failed container|k8s_error|INC-2026-5389" evidence`
- CSV analysis in:
  - `container_status_matrix.csv`
  - `probe_failures.csv`
  - `pod_resource_metrics.csv`
  - `timeline_events.csv`
- JSONL filtering in:
  - `pod_events.jsonl`
  - `cluster_alerts.jsonl`
