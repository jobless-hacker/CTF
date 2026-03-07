# M8-05 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Exposure of production payment API key in plaintext config.
- Task target: identify leaked API key value.

### Learning Outcome
- Investigate credential exposure across config history, source control, CI, and runtime API traces.
- Correlate noisy telemetry with true compromised key indicators.
- Extract normalized leaked key value for emergency rotation.

### Previous Artifact Weaknesses
- Single config file revealed answer immediately.
- No realistic multi-system investigation path.
- Missing operational detection and incident workflow context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. App config history drift showing shift from secret manager to plaintext.
2. Repository scan failures and commit-level leakage evidence.
3. CI pipeline policy violations for dotenv-based secret injection.
4. API usage anomaly, security alerts, and SIEM normalization.

### Key Signals Adopted
- `PAYMENT_API_KEY` moved to plaintext value `pk_live_9a82d2`.
- Repo and CI logs independently report same leaked key.
- Runtime API usage shows suspicious use of leaked key.
- Alert/SIEM converge on leaked key value `pk_live_9a82d2`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `app_config_history.log` (**7,101 lines**) config baseline plus one plaintext key violation.
- `repo_scan.log` (**5,601 lines**) repository scan telemetry with one failed leaked key detection.
- `pipeline_audit.log` (**5,201 lines**) CI policy stream with leaked key propagation event.
- `payment_api_usage.log` (**5,401 lines**) runtime usage baseline plus suspicious leaked-key request.
- `api_key_exposure_alerts.jsonl` (**4,301 lines**) noisy alerts with one critical key exposure event.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression and key normalization.
- `api_config.txt` direct config artifact.
- `api_credential_management_policy.txt` and `exposed_api_key_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-noise, cross-domain evidence (Cloud + Dev + CI + Runtime + SOC).
- Requires value-level pivoting across all evidence sources.
- Includes actionable process context for response teams.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5805`) and affected service.
2. Identify key leak in config history and direct config artifact.
3. Confirm leak propagation in repo scan and CI pipeline logs.
4. Validate suspicious downstream usage and alert/SIEM normalized key value.
5. Submit leaked API key value.

Expected answer:
- `CTF{pk_live_9a82d2}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m8/m8-05-exposed-api-key.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `PAYMENT_API_KEY`, `pk_live_9a82d2`, `result=failed`, `leaked_api_key`, `leaked_api_key_identified`.
- Correlate config/dev/ci/runtime/security evidence before submission.
