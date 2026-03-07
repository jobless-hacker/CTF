# M1-05 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Service outage investigation with CIA mapping.
- Learner must identify the **primary impacted pillar** during an availability incident.

### Learning Outcome
- Correlate web-tier logs, monitoring signals, and host/service telemetry.
- Separate true outage indicators from noisy but non-critical events.
- Explain impact using evidence instead of guessing from a single log line.

### Previous Artifact Weaknesses
- Small and linear evidence set.
- Minimal background noise or false positives.
- Limited realism for SOC/SRE-style incident triage.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NGINX HTTP log module (real access-log structure and fields):  
   https://nginx.org/en/docs/http/ngx_http_log_module.html
2. NGINX stub status module (active/accepts/handled/reading/writing/waiting counters):  
   https://nginx.org/en/docs/http/ngx_http_stub_status_module.html
3. NGINX `error_log` behavior and severity model:  
   https://nginx.org/en/docs/ngx_core_module.html#error_log
4. systemd `systemctl` status semantics for failed/auto-restart services:  
   https://www.freedesktop.org/software/systemd/man/latest/systemctl.html
5. systemd journal field model for structured event records:  
   https://www.freedesktop.org/software/systemd/man/latest/systemd.journal-fields.html
6. Linux `/proc/loadavg` format for host load interpretation:  
   https://man7.org/linux/man-pages/man5/proc_loadavg.5.html

### Key Signals Adopted
- Burst of HTTP `503` in a narrow outage window.
- NGINX `worker_connections are not enough` alerts.
- `accepts` diverging from `handled` under saturation.
- Backend service auto-restart loop (`status=1/FAILURE`).
- Host load spike during failure window.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `nginx_access.log` (**16,800 lines**) with heavy baseline traffic + 503 surge.
- `nginx_error.log` (**6,400 lines**) with alert/error patterns and benign noise.
- `nginx_stub_status_timeseries.csv` (**521 lines**) for capacity counters over time.
- `synthetic_check_results.csv` (**8,801 lines**) with transient false positives + real outage.
- `journal_portal_api.jsonl` (**5,204 lines**) structured service telemetry.
- `proc_loadavg_samples.csv` (**1,301 lines**) host pressure timeline.
- `availability_events.csv` (**6,205 lines**) normalized SIEM event stream.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`) and challenge `description.txt`.

Realism upgrades:
- High-volume noisy logs.
- Multiple clients/regions/probes.
- False positives and planned-change noise.
- Cross-source timeline correlation required to solve confidently.

## Step 4 - Flag Engineering

Expected investigation path:
1. Confirm user-facing outage with `503` concentration.
2. Validate web tier resource exhaustion in error logs/status counters.
3. Correlate backend crash-loop evidence in systemd/journal.
4. Confirm service degradation period across synthetic and SIEM feeds.
5. Classify the dominant CIA impact.

Expected flag:
- `CTF{availability}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-05-web-server-crash.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for HTTP code and error pivots.
- CSV filtering (`Import-Csv`, `awk`, spreadsheet) for counter trends.
- `jq` optional for JSONL parsing.
- Time-based correlation across logs, monitoring, and host telemetry.
