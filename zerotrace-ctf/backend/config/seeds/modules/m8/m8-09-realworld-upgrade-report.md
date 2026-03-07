# M8-09 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Access token exposure and unauthorized reuse in cloud API traffic.
- Task target: identify exposed token value.

### Learning Outcome
- Investigate token compromise through audit, API, session, and security telemetry.
- Correlate token leakage indicator with downstream abuse attempts.
- Extract normalized compromised token from SIEM/security pipelines.

### Previous Artifact Weaknesses
- Single access log line made answer immediate.
- No realistic token lifecycle or abuse-correlation context.
- Missing operational incident triage artifacts.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Token audit trails with exposure-state transitions.
2. API access logs and token introspection records for misuse validation.
3. Session telemetry showing suspicious source activity.
4. Security alerts and SIEM normalization for final token extraction.

### Key Signals Adopted
- Token audit marks plaintext token leak for `abc123xyz`.
- API and session logs show suspicious external use of the same token.
- Alert/SIEM confirm exposed token value as `abc123xyz`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `token_audit.log` (**7,101 lines**) token baseline and one exposure violation.
- `api_access.log` (**6,201 lines**) API usage baseline plus suspicious token request.
- `token_introspection.jsonl` (**5,401 lines**) introspection baseline and critical exposed token record.
- `session_activity.csv` (**5,202 lines**) user session baseline and blocked suspicious token use.
- `token_exposure_alerts.jsonl` (**4,301 lines**) noisy alerts with critical token compromise finding.
- `timeline_events.csv` (**5,004 lines**) SIEM confirmation and exposed token identification.
- `access_log.txt` simple direct token artifact.
- `access_token_protection_policy.txt` and `compromised_access_token_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-noise cross-source telemetry with one true compromised token path.
- Requires pivoting token value across multiple systems.
- Includes SOC/CloudSec response context for real workflows.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5809`).
2. Identify candidate leaked token in token audit and direct access log.
3. Validate token misuse via API/session activity and introspection evidence.
4. Confirm with security alert + SIEM normalized token indicator.
5. Submit exposed token value.

Expected answer:
- `CTF{abc123xyz}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m8/m8-09-compromised-access-token.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `abc123xyz`, `exposure=yes`, `auth_token=`, `exposed_token`, `leaked_token`, `exposed_token_identified`.
- Correlate token audit/runtime/security evidence before submission.
