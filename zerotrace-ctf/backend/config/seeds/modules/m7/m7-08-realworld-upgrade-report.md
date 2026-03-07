# M7-08 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Command injection against a web diagnostics endpoint using parameter manipulation.
- Task target: identify the injected command token.

### Learning Outcome
- Detect command injection by correlating web, app, WAF, and host execution evidence.
- Trace a suspicious request ID across multiple telemetry sources.
- Extract normalized injected command indicator from SOC detections.

### Previous Artifact Weaknesses
- Single request sample revealed answer immediately.
- No realistic SOC/AppSec/host triage workflow.
- Missing noisy baseline traffic and investigation context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. API gateway/web access telemetry with high-volume benign requests.
2. App parameter logs showing raw query, validation result, and parsing signals.
3. WAF + host execution audit events for command injection confirmation.
4. Security alert stream + SIEM timeline for normalized command identification.

### Key Signals Adopted
- Suspicious request `req-9918123` to `/ping`.
- Raw query includes command separator and token `;cat`.
- WAF, host audit, alert, and SIEM converge on injected command `cat`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `gateway_access.log` (**7,201 lines**) noisy baseline and suspicious command injection request.
- `app_request_params.log` (**5,601 lines**) input parsing stream with validation failure signal.
- `waf.log` (**6,101 lines**) baseline allow logs plus critical command injection alert.
- `exec_audit.log` (**5,301 lines**) host execution audit with parsed injected command.
- `request_capture.txt` HTTP request evidence for suspicious payload.
- `command_injection_alerts.jsonl` (**4,301 lines**) alert stream with normalized command field.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression and command identification.
- `command_execution_endpoint_security_policy.txt` and `command_injection_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-volume noisy telemetry with one actionable malicious path.
- Cross-layer correlation required (web/app/waf/host/security).
- Includes operational process artifacts for realistic analyst workflow.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5708`) and request ID.
2. Pivot request ID across gateway, app params, and WAF logs.
3. Confirm command execution intent in request capture and host execution audit.
4. Validate normalized injected command from alert and SIEM artifacts.
5. Submit injected command token.

Expected answer:
- `CTF{cat}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m7/m7-08-command-injection.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `req-9918123`, `;cat`, `injected_command`, `parsed_injected_command`, `injected_command_identified`.
- Correlate endpoint/app/host/security evidence for final answer.
