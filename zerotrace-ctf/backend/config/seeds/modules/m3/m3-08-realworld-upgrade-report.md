# M3-08 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Sensitive authentication token exposure via production log leakage.
- Task target: identify the exact exposed token.

### Learning Outcome
- Correlate application, gateway, observability, WAF, SIEM, and policy evidence.
- Separate real exposure from noisy token-like data.
- Confirm exposure source and extract correct token value.

### Previous Artifact Weaknesses
- Single short log artifact with immediate answer.
- No telemetry correlation or production incident context.
- No noise, false positives, or realistic investigation pivots.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. OWASP Logging Cheat Sheet (sensitive-data logging pitfalls):  
   https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
2. NIST SP 800-61 incident handling evidence-correlation model:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. MITRE ATT&CK data collection and credential/token exposure patterns:  
   https://attack.mitre.org/techniques/T1552/
4. Operational SOC model: app logs + gateway + WAF + SIEM timeline correlation.

### Key Signals Adopted
- Raw request dump enabled in production logging config.
- Token appears in app log headers (`Authorization: Bearer ...`).
- Same token value appears in gateway and WAF correlated records.
- SIEM opens high-severity incident for token exposure.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `app_server.log` (**9,457 lines**) high-noise production application logs.
- `api_gateway_requests.csv` (**7,802 lines**) gateway telemetry with one exposed token record.
- `trace_events.jsonl` (**5,201 lines**) observability traces and error correlation.
- `waf_alerts.csv` (**4,302 lines**) WAF noise + high-value token leakage alert.
- `timeline_events.csv` (**5,004 lines**) SIEM progression and incident open event.
- `logging_runtime.conf` (**6 lines**) misconfiguration root cause (`enable_raw_request_dump=true`).
- `token_handling_policy.txt` (**5 lines**) governance baseline.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-system telemetry with timeline-based correlation.
- False positives and token-like noise entries.
- Root-cause + detection + response path represented in artifacts.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident brief for scope and time window.
2. Validate logging misconfiguration in runtime config.
3. Find exposed token in app log, then confirm in gateway/WAF/trace evidence.
4. Verify SIEM timeline that confirms critical exposure.
5. Extract exact token value and submit.

Expected answer:
- `CTF{9f8a7b6c}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m3/m3-08-log-file-exposure.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `9f8a7b6c`, `raw-request-dump`, `token_exposed_in_logs`, `INC-2026-5211`.
- CSV filtering for gateway/WAF/SIEM.
- JSONL filtering for trace correlation.
