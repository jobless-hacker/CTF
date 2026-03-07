# M1-08 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Unauthorized configuration modification leading to abnormal redirect behavior.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Compare baseline/current config state and verify unauthorized changes.
- Correlate behavior evidence (traffic + synthetic checks) with host-level file-write telemetry.
- Distinguish expected change activity from unauthorized drift.

### Previous Artifact Weaknesses
- Small dataset and direct answer path.
- Minimal operational noise.
- Limited cross-source validation between config, runtime behavior, and change control.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NGINX access log format and logging fields:  
   https://nginx.org/en/docs/http/ngx_http_log_module.html
2. NGINX rewrite/return behavior used for redirect handling:  
   https://nginx.org/en/docs/http/ngx_http_rewrite_module.html
3. NGINX `error_log` semantics and reload behavior context:  
   https://nginx.org/en/docs/ngx_core_module.html#error_log
4. Linux auditd file monitoring model (`auditd` + watched file events):  
   https://man7.org/linux/man-pages/man8/auditd.8.html
5. Linux audit event querying model (`ausearch`) for syscall/path pivots:  
   https://man7.org/linux/man-pages/man8/ausearch.8.html
6. Unified diff format reference (`diff -u` style):  
   https://man7.org/linux/man-pages/man1/diff.1.html

### Key Signals Adopted
- Redirect toggle and target change in config diff.
- Audit records showing direct write activity on `/etc/portal/server.conf`.
- Traffic and synthetic checks confirming runtime redirect to external host.
- Change-control dataset showing no approved ticket for that file change.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `nginx_access.log` (**16,200 lines**) with noisy baseline traffic and incident redirect window.
- `nginx_error.log` (**5,800 lines**) routine noise + reload events.
- `audit_config_watch.log` (**18,208 lines**) high-volume file access/write telemetry.
- `synthetic_http_checks.csv` (**7,601 lines**) probe evidence for redirect drift.
- `change_tickets.csv` (**1,502 lines**) mostly approved changes plus unapproved draft.
- `normalized_events.csv` (**6,804 lines**) SIEM stream with false positives and true drift alerts.
- Config evidence: baseline/current files, diff patch, and hash timeline.
- Briefing context: incident ticket and analyst handoff.

Realism upgrades:
- High-volume logs with false positives.
- Multiple evidence sources that require timeline correlation.
- Attack pattern embedded in normal deploy noise.
- Behavioral validation plus governance validation (change control) before conclusion.

## Step 4 - Flag Engineering

Expected investigation path:
1. Identify config drift in baseline/current + patch evidence.
2. Confirm actual runtime impact in access logs and synthetic checks.
3. Validate write activity against watched file in audit records.
4. Confirm no approved ticket mapped to the changed config.
5. Classify primary CIA impact.

Expected flag:
- `CTF{integrity}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-08-config-file-tampering.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for redirect and file-write pivots.
- CSV filtering for change-control and synthetic validation correlation.
- Timeline stitching across audit, web, and SIEM records.
