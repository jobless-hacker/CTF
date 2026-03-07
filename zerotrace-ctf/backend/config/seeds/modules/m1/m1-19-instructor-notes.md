# M1-19 Instructor Notes

## Objective
- Train learners to investigate Kubernetes outage evidence and identify the dominant CIA impact.
- Expected answer: `CTF{availability}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - namespace: `payments`
   - deployment: `payment-api`
   - key window: around `2026-03-06T09:17Z`
2. Use `kube_events.log` to identify incident markers:
   - `OOMKilled`
   - `BackOff`
   - `CrashLoopBackOff`
   - readiness/liveness failures (`HTTP 503`)
3. Confirm restart escalation in `pod_restart_timeseries.csv`.
4. Validate node runtime evidence in `kubelet_node_logs.log`.
5. Check `metrics_samples.csv` for memory pressure and lowered memory limits.
6. Correlate deployment changes in `deployment_revisions.csv`:
   - mistaken `limits_mem=128Mi` revision
   - rollback revision restoring `1024Mi`
7. Confirm user-facing impact in `ingress_probe_results.csv` (503/timeouts).
8. Use `change_records.csv` to map emergency rollout/rollback sequence.
9. Classify CIA impact.

## Key Indicators
- Pod state: `CrashLoopBackOff`
- Exit reason: `OOMKilled` (137)
- Probe evidence: `HTTP 503`
- Config drift: memory limit changed to `128Mi`
- External impact: widespread degraded/timeouts on `/health`

## Suggested Commands / Tools
- `rg "OOMKilled|CrashLoopBackOff|Back-off|HTTP 503|128Mi" evidence`
- CSV filtering in:
  - `pod_restart_timeseries.csv`
  - `metrics_samples.csv`
  - `deployment_revisions.csv`
  - `ingress_probe_results.csv`
  - `change_records.csv`
- Build a single timeline around `09:16:58Z` to `09:18:30Z`.
