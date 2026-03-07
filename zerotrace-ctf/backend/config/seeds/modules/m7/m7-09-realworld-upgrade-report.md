# M7-09 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Session cookie hardening failure in production HTTP responses.
- Task target: identify missing cookie security flag.

### Learning Outcome
- Investigate cookie security issues across edge, app, browser-scan, and SOC artifacts.
- Correlate request-level evidence with config and detection signals.
- Extract normalized missing cookie flag indicator for remediation.

### Previous Artifact Weaknesses
- Single header sample made answer immediate.
- No realistic telemetry noise or multi-source investigation flow.
- Missing policy/runbook and detection pipeline context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Edge gateway request logs with suspicious request ID pivoting.
2. Response header capture streams and browser security scan outputs.
3. App session config audit showing profile-level hardening drift.
4. Security alert stream and SIEM timeline with normalized missing flag.

### Key Signals Adopted
- Suspicious request `req-9927333` on `/login`.
- Set-Cookie response missing `HttpOnly` attribute.
- Browser scan/config/aalert/SIEM converge on missing flag `httponly`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `gateway_access.log` (**7,101 lines**) noisy edge traffic plus suspicious login response event.
- `response_headers.log` (**5,601 lines**) captured header stream with one missing flag case.
- `browser_security_scan.csv` (**5,202 lines**) scan baseline and one failed hardening check.
- `session_config_audit.log` (**5,101 lines**) config baseline plus legacy profile violation.
- `http_headers.txt` raw response header evidence.
- `cookie_security_alerts.jsonl` (**4,301 lines**) noisy alerts and one critical open incident.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression and normalized indicator.
- `session_cookie_security_policy.txt` and `insecure_cookie_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-volume noisy signals requiring request-id and field-level correlation.
- Cross-layer validation (edge/web/app/security) before conclusion.
- Includes operational incident-response context.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5709`) and request ID.
2. Pivot request ID across gateway and response header logs.
3. Confirm missing cookie attribute in raw header capture.
4. Validate missing flag via browser scan, config audit, alerts, and SIEM.
5. Submit normalized missing cookie security flag.

Expected answer:
- `CTF{httponly}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m7/m7-09-insecure-cookie.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `req-9927333`, `missing_flag=httponly`, `Set-Cookie`, `missing_cookie_flag_identified`.
- Correlate edge/header/scan/config/alert evidence to derive final flag.
