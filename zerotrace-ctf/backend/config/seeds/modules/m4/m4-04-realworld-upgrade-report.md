# M4-04 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Service-level outage investigation using systemd and runtime telemetry.
- Task target: identify failed service name.

### Learning Outcome
- Correlate service manager output, journal failures, probes, and SIEM events.
- Distinguish noisy transient service events from true failed unit state.
- Extract definitive failed-service indicator from realistic artifact set.

### Previous Artifact Weaknesses
- Single lightweight artifact with immediate answer disclosure.
- Missing multi-source operational context and incident timeline.
- No realistic noise/false positives in service monitoring data.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NIST SP 800-61 incident triage/correlation practices:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
2. Systemd operational troubleshooting model (`systemctl status`, journal correlation).
3. SRE service outage workflow: failed units + failed probes + alert escalation.
4. SOC workflow: SIEM incident confirmation from host/service telemetry.

### Key Signals Adopted
- `systemctl status nginx.service -> Active: failed`.
- Journal shows startup/bind failure and `status=1/FAILURE`.
- Port probes on 80/443 fail with `connection_refused`.
- Alert feed and SIEM both classify failed service as `nginx`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `systemctl_snapshot.log` (**7,603 lines**) service-manager state snapshots.
- `journal_service.log` (**8,405 lines**) host journal telemetry with failure block.
- `service_health_matrix.csv` (**6,903 lines**) service runtime health records.
- `port_probe_results.csv` (**6,403 lines**) web port probe evidence.
- `service_alerts.jsonl` (**4,301 lines**) alert stream with critical failed_service field.
- `timeline_events.csv` (**5,004 lines**) SIEM progression and incident open event.
- `nginx.service` (**13 lines**) relevant unit file context.
- `service_failure_runbook.txt` (**5 lines**) operational triage guidance.
- Briefing files.

Realism upgrades:
- Multi-layer service-failure investigation path (systemd -> journal -> probe -> SIEM).
- Large noisy operational datasets with focused pivots.
- Root service determination requires cross-correlation, not single-file lookup.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident ticket and outage window.
2. Confirm failed unit in systemd snapshots.
3. Validate with journal startup failure entries.
4. Correlate probe failures and critical alert fields.
5. Confirm SIEM `service_failed` event and return service name.

Expected answer:
- `CTF{nginx}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m4/m4-04-service-failure.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `nginx.service`, `Active: failed`, `status=1/FAILURE`, `failed_service`.
- CSV filtering for service-health and probe failures.
- JSONL filtering for critical service-down alert.
