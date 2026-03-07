# M2-09 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Web authentication anomaly investigation to identify exploited vulnerability class.
- Task target: determine the vulnerability used in suspicious login requests.

### Learning Outcome
- Correlate request payloads, WAF detections, auth behavior, and SQL execution evidence.
- Distinguish malformed noise from exploit-driven authentication bypass.
- Map incident evidence to a concrete vulnerability category.

### Previous Artifact Weaknesses
- Single small log with direct clueing and minimal context.
- No app/backend/database/defense correlation path.
- Low realism and no SOC-style noise profile.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Exploit Public-Facing Application / SQL Injection-style abuse in web applications:  
   https://attack.mitre.org/techniques/T1190/
2. OWASP SQL Injection patterns and authentication bypass payload behavior:  
   https://owasp.org/www-community/attacks/SQL_Injection
3. NIST SP 800-61 incident analysis and evidence correlation model:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final

### Key Signals Adopted
- Tautology login payloads (`' OR '1'='1`, `' OR 1=1--`) in web requests.
- WAF SQLi signatures firing with high/critical severity.
- Auth service shows bypass tied to `legacy_query_builder`.
- DB audit captures string-concatenated SQL with injected predicate.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `web_access.log` (**12,203 lines**) web request stream.
- `waf_alerts.jsonl` (**4,602 lines**) WAF detection telemetry.
- `auth_service.log` (**7,803 lines**) application authentication behavior.
- `db_audit.log` (**6,502 lines**) SQL query audit trail.
- `raw_request_corpus.txt` (**2,608 lines**) request sample set.
- `timeline_events.csv` (**5,205 lines**) SIEM event sequence.
- `secure_coding_standard.txt` (**4 lines**) policy baseline.
- Briefing files.

Realism upgrades:
- Multi-layer evidence (web + WAF + app + DB + SIEM + policy).
- Large noisy telemetry with few true positives.
- Investigation requires cross-source correlation rather than direct answer extraction.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope around login anomalies.
2. Isolate suspicious login payloads in web logs/request corpus.
3. Correlate WAF SQLi rule matches.
4. Confirm auth bypass behavior in app logs.
5. Validate unsanitized SQL in DB audit records.
6. Map to vulnerability class and return flag.

Expected answer:
- `CTF{sqli}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m2/m2-09-strange-request-pattern.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `OR%20%271%27=%271`, `OR%201=1--`, `legacy_query_builder`, `SQL Injection`.
- JSONL inspection (`jq`) for critical WAF alerts.
- Timeline correlation across web/auth/db datasets.
