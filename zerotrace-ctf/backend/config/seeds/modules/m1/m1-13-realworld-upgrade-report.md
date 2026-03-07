# M1-13 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- SIEM anomaly investigation tied to security-log manipulation.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate SIEM detections with host-level forensic telemetry.
- Validate whether the anomaly represents benign maintenance or malicious log alteration.
- Use timeline stitching across alert, process, and file-size evidence.

### Previous Artifact Weaknesses
- Very small evidence set with linear answer path.
- Limited background noise and false positives.
- Insufficient realism for SOC triage and correlation workflow.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK T1070.002 (Clear Linux/macOS logs):  
   https://attack.mitre.org/techniques/T1070/002/
2. Linux auditd service reference:  
   https://man7.org/linux/man-pages/man8/auditd.8.html
3. `ausearch` event investigation model for audit logs:  
   https://man7.org/linux/man-pages/man8/ausearch.8.html
4. Elastic Common Schema (ECS) event field modeling for SIEM pipelines:  
   https://www.elastic.co/guide/en/ecs/current/ecs-reference.html
5. Sigma rule format and correlation use in detection engineering:  
   https://sigmahq.io/docs/basics/rules.html
6. NIST SP 800-61 incident handling lifecycle (triage/analysis methods):  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final

### Key Signals Adopted
- SIEM anomaly alert for abrupt auth-log event-rate drop.
- Host audit records showing `truncate -s 0 /var/log/auth.log`.
- Auth-log file-size timeseries with near-instant 100% collapse.
- Privileged session records immediately preceding truncation.
- Benign logrotate/maintenance noise and false-positive alerts.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `alerts_stream.jsonl` (**7,601 lines**) noisy SIEM alert stream with one critical incident.
- `timeline.csv` (**9,105 lines**) cross-event timeline for host/security activity.
- `rule_engine_metrics.csv` (**4,302 lines**) detection-baseline/deviation telemetry.
- `auditd_full.log` (**24,807 lines**) high-volume syscall/path records.
- `auth_log_size_timeseries.csv` (**6,201 lines**) integrity drift signal.
- `sudo_session.log` (**5,804 lines**) privileged command context.
- Briefing and triage files for analyst workflow.

Realism upgrades:
- Large datasets with routine SOC noise.
- False positives and benign maintenance signals.
- Multi-source correlation required to prove tampering.
- Event-ordering and causality analysis instead of single log lookup.

## Step 4 - Flag Engineering

Expected investigation path:
1. Start from SIEM critical alert on `server01`.
2. Verify correlated timeline around `12:41:13Z`.
3. Confirm destructive log-modification command in auditd and sudo/session logs.
4. Validate matching auth-log size collapse and post-truncate rewrite behavior.
5. Filter benign logrotate and normal auth-failure noise.
6. Classify primary CIA impact.

Expected flag:
- `CTF{integrity}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-13-siem-alert-investigation.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for host, timestamp, and command pivots.
- CSV filtering for metric/timeline correlation.
- `jq` for SIEM JSONL triage.
- Cross-source timeline reconstruction.
