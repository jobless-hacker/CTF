# M7-01 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Authentication bypass attempt via crafted login parameters.
- Task target: identify exploited vulnerability class.

### Learning Outcome
- Detect malicious login-query patterns in noisy web telemetry.
- Correlate web, app, WAF, and DB evidence to classify attack vector.
- Map investigation signals to a concrete vulnerability class.

### Previous Artifact Weaknesses
- Single small access log with obvious payload.
- No realistic SOC/AppSec multi-source investigation workflow.
- Missing policy/runbook guidance and context artifacts.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Access logs containing injection payloads in query parameters.
2. WAF rules triggering SQL injection signatures.
3. Auth and DB audit traces showing unsanitized query construction.
4. Security alert + SIEM correlation for final vector classification.

### Key Signals Adopted
- Login payload marker: `admin'+OR+'1'='1`.
- WAF SQLi detection rule hit (`942100`).
- Raw-string DB query contains tautology auth bypass pattern.
- Alert and SIEM normalize vector as `sqli`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `access.log` (**9,601 lines**) realistic web access baseline with one suspicious login request.
- `waf.log` (**6,201 lines**) WAF telemetry with SQL injection detection event.
- `auth_service.log` (**5,601 lines**) authentication service outcomes and suspicious username parameter.
- `query_audit.log` (**5,401 lines**) DB audit trail including tainted raw query row.
- `web_attack_alerts.jsonl` (**4,301 lines**) detection stream with critical auth-bypass attempt.
- `timeline_events.csv` (**5,004 lines**) SIEM timeline confirming vulnerability classification.
- `web_auth_attack_detection_policy.txt` and `suspicious_login_query_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- High-volume noisy traffic and routine benign events.
- Multi-system evidence path required for accurate classification.
- SOC + AppSec process context embedded in policy/runbook/ticket.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5701`, endpoint `/login`).
2. Identify crafted login query in access log.
3. Validate SQLi detection in WAF and suspicious auth event.
4. Confirm SQL-tautology backend query pattern in DB audit.
5. Verify vector classification from alert/SIEM and submit.

Expected answer:
- `CTF{sqli}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m7/m7-01-suspicious-login-query.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `OR+'1'='1`, `942100`, `attack_vector`, `sqli`.
- Cross-check access/WAF/auth/DB logs before concluding.
- Use alert + SIEM records for final vulnerability classification.
