# M2-02 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Repeated authentication failures targeting one account and determining attack category.
- Task target: identify the attack type.

### Learning Outcome
- Detect brute-force behavior via cadence + password-guess pattern.
- Correlate endpoint login failures with WAF/SIEM/lockout controls.
- Differentiate sustained attack behavior from routine auth noise.

### Previous Artifact Weaknesses
- Single short credential list with minimal forensic depth.
- No timing, source, lockout, or control-correlation context.
- Easy guess with limited SOC realism.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK T1110 Brute Force:  
   https://attack.mitre.org/techniques/T1110/
2. NIST SP 800-61 incident analysis workflow:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. OWASP Authentication security guidance (rate limiting / lockout context):  
   https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
4. SOC triage practice: multi-source login telemetry correlation.

### Key Signals Adopted
- High-frequency failed attempts against `admin` from one IP.
- Dictionary-style password-guess rotation.
- WAF critical detection explicitly classifying brute-force behavior.
- Account hard lock triggered after large failed-attempt count.
- SIEM timeline aligns all indicators to one attack sequence.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `failed_auth.log` (**13,321 lines**) raw failed-auth stream with noise + attack burst.
- `auth_api_attempts.csv` (**7,932 lines**) auth endpoint request telemetry.
- `waf_auth_alerts.jsonl` (**4,301 lines**) WAF detections with noise and critical event.
- `account_lockouts.csv` (**3,202 lines**) account lockout lifecycle evidence.
- `timeline_events.csv` (**4,704 lines**) SIEM correlation and classification.
- `source_context.csv` (**6 lines**) IP reputation/enrichment.
- Briefing files.

Realism upgrades:
- Multi-source SOC evidence instead of simple credential list.
- High-volume baseline noise and false positives.
- Time-correlated chain from attempts -> detection -> lockout.

## Step 4 - Flag Engineering

Expected investigation path:
1. Use incident ticket to lock account + timeframe.
2. Confirm sustained failed attempts from a single source.
3. Verify rotating common password guesses (dictionary style).
4. Confirm WAF/SIEM critical brute-force detections.
5. Confirm hard lockout due to threshold breach.
6. Return attack type.

Expected answer:
- `CTF{bruteforce}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m2/m2-02-login-storm.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for IP/account and password-guess pattern pivots.
- CSV filtering for failure cadence and lockout thresholds.
- `jq` for WAF JSONL critical event triage.
