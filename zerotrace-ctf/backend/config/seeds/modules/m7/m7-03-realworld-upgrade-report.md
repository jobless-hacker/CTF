# M7-03 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- File path manipulation via directory traversal tokens.
- Task target: identify exploited vulnerability class.

### Learning Outcome
- Detect traversal payloads in noisy download traffic.
- Correlate request, app normalization, WAF, and file-audit evidence.
- Classify the web vulnerability precisely.

### Previous Artifact Weaknesses
- Single small web request artifact with obvious payload.
- No multi-source AppSec/SOC investigation path.
- Missing response behavior and filesystem audit context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Download endpoint requests containing `../` traversal sequences.
2. WAF signatures for OS/file path access attempts.
3. App handler normalization failures and blocked file-audit events.
4. Alert + SIEM vector classification into vulnerability class.

### Key Signals Adopted
- Suspicious payload: `../../etc/passwd`.
- App normalization fails and file access to `/etc/passwd` is denied.
- WAF/alert/SIEM consistently classify vector as `path_traversal`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `web_request.log` (**9,401 lines**) request telemetry with one traversal payload.
- `access.log` (**6,201 lines**) web access context for `/download`.
- `download_handler.log` (**5,601 lines**) app-level path normalization outcome.
- `file_access_audit.log` (**5,401 lines**) filesystem access audit with denied sensitive file read.
- `waf.log` (**6,101 lines**) traversal detection rule hit and noisy baseline.
- `web_attack_alerts.jsonl` (**4,301 lines**) security alerts with critical classification event.
- `timeline_events.csv` (**5,004 lines**) SIEM classification timeline.
- `download_path_security_policy.txt` and `file_path_access_triage_runbook.txt`.
- `threat_intel_snapshot.txt`, `response_snapshot.txt`, plus briefing files.

Realism upgrades:
- High-volume baseline logs with one true positive.
- Multi-source correlation required to classify vulnerability.
- SOC/AppSec process context embedded through policy/runbook/ticket.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5703`, endpoint `/download`).
2. Identify traversal payload in request/access logs.
3. Confirm app normalization failure + denied sensitive file audit event.
4. Validate classification through WAF, alert, and SIEM outputs.
5. Submit vulnerability class.

Expected answer:
- `CTF{path_traversal}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m7/m7-03-file-path-access.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `../../etc/passwd`, `normalization=failed`, `attack_type`.
- Correlate request -> app handler -> file audit -> WAF/alerts/SIEM.
- Use classification fields for final answer validation.
