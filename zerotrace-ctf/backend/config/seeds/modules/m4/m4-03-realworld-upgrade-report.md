# M4-03 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Availability failure driven by host storage exhaustion.
- Task target: identify root-cause label of outage.

### Learning Outcome
- Correlate storage telemetry, system/app write failures, and operations logs.
- Distinguish transient I/O issues from full-disk outage conditions.
- Derive final root-cause classification from multi-source evidence.

### Previous Artifact Weaknesses
- Minimal artifact with direct answer path.
- No realistic production telemetry, noisy logs, or timeline context.
- Missing operational dependencies (logrotate, disk consumers, alerts).

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NIST SP 800-61 incident evidence-correlation workflow:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
2. Linux operational troubleshooting patterns (`df`, journal errors, log growth).
3. SRE outage triage practices for storage saturation and write-path failures.
4. SOC correlation model: host metrics + service errors + SIEM classification.

### Key Signals Adopted
- Root mount reaches 100% utilization with 0GB free.
- Repeated `No space left on device` across journal and application logs.
- Disk consumers show heavy log accumulation in `/var/log/nginx`.
- Alert/siem root-cause field classifies incident as `disk_full`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `disk_usage_timeseries.csv` (**9,203 lines**) mount-level usage progression.
- `journal_errors.log` (**7,804 lines**) host/service logs with write failures.
- `app_write_failures.csv` (**5,603 lines**) application persistence failures.
- `top_disk_consumers.txt` (**6,406 lines**) disk usage breakdown by path.
- `logrotate_run.log` (**4,802 lines**) rotation behavior and failures.
- `storage_alerts.jsonl` (**4,401 lines**) alert stream with critical classification.
- `timeline_events.csv` (**5,005 lines**) SIEM event progression.
- `logrotate_nginx.conf` (**7 lines**) risky rotation config (`rotate 0`).
- `storage_outage_runbook.txt` (**5 lines**) runbook-based classification guidance.
- Briefing files.

Realism upgrades:
- End-to-end outage narrative from storage pressure to service failure.
- Cross-functional evidence (SRE + SOC + platform operations).
- High-noise datasets requiring focused pivots.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident brief and affected host/time window.
2. Confirm `/` usage hits 100% and free space reaches 0.
3. Validate repeated write failures (`No space left on device`).
4. Correlate top disk consumers + logrotate behavior with exhaustion.
5. Confirm SIEM/alerts root-cause classification and submit label.

Expected answer:
- `CTF{disk_full}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m4/m4-03-disk-full.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `No space left on device`, `100%`, `disk_full`, `INC-2026-5328`.
- CSV filtering for disk usage and write failure spikes.
- JSONL filtering for critical storage alerts.
