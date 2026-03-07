# M7-02 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Reflected script injection through search query parameter.
- Task target: identify attack type.

### Learning Outcome
- Detect reflected client-side payload execution from mixed web evidence.
- Correlate request, rendering, WAF, browser, and SIEM telemetry.
- Classify web attack correctly from artifact signals.

### Previous Artifact Weaknesses
- Single request artifact with direct payload visibility.
- No realistic multi-source investigation workflow.
- Missing context around rendering behavior and client execution.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Search/query endpoints receiving `<script>` payload probes.
2. Server render logs showing unescaped reflection of input.
3. WAF signatures and browser-console clues confirming script execution.
4. Alert + SIEM classification pipeline for final vector label.

### Key Signals Adopted
- Payload marker: `<script>alert(1)</script>`.
- App render mode indicates raw reflection.
- WAF and security alert classify attack as `xss`.
- SIEM vulnerability classification confirms same vector.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `request_log.txt` (**9,201 lines**) raw request telemetry with one suspicious payload.
- `access.log` (**6,301 lines**) web access context including suspicious query.
- `render.log` (**5,601 lines**) server-side rendering behavior with reflected raw payload.
- `waf.log` (**6,101 lines**) WAF telemetry and XSS detection event.
- `browser_console.log` (**4,202 lines**) client-side execution traces.
- `response_snapshot.txt` (HTML snippet) showing reflected script in output.
- `web_attack_alerts.jsonl` (**4,301 lines**) detection stream with critical event.
- `timeline_events.csv` (**5,004 lines**) SIEM classification timeline.
- `reflected_script_detection_policy.txt` and `reflected_script_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- High-volume noisy logs plus one true-positive attack sequence.
- Multi-source evidence required to classify attack.
- SOC/AppSec process context and response artifacts included.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5702`, endpoint `/search`).
2. Identify script payload in request/access logs.
3. Confirm unsanitized reflection in render log and response snapshot.
4. Validate client-side execution clues + WAF/security alert classifications.
5. Submit attack type.

Expected answer:
- `CTF{xss}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m7/m7-02-reflected-script.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `<script>alert(1)</script>`, `render_mode=raw`, `attack_type`.
- Cross-check request -> render -> response -> client console chain.
- Confirm final attack class with alerts and SIEM output.
