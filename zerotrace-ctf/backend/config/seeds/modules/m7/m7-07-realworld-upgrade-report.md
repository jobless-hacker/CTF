# M7-07 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Exposure of restricted credential data in API response payloads.
- Task target: identify the exposed sensitive field name.

### Learning Outcome
- Investigate API data exposure through multi-source telemetry.
- Compare runtime payload evidence against declared response schema.
- Use SOC/AppSec detections to confirm the final sensitive field indicator.

### Previous Artifact Weaknesses
- Single API response file made the answer immediate.
- No realistic API gateway, schema, and detection correlation path.
- Missing engineering/process context for production triage.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. API gateway logs with request IDs and endpoint telemetry.
2. Response sample streams and schema audit outputs to detect field drift.
3. DLP alerts and SIEM timelines for normalized sensitive field classification.
4. OpenAPI + patch diff context to show intended response contract.

### Key Signals Adopted
- Suspicious request `req-8807120` to `/api/v2/admin/users/1442`.
- Response payload includes restricted field `password`.
- DLP/SIEM normalize final exposed field as `password`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `gateway_access.log` (**7,101 lines**) API traffic baseline plus suspicious request event.
- `response_samples.jsonl` (**5,601 lines**) response baseline and one leaked sensitive field sample.
- `schema_audit.log` (**5,301 lines**) expected-vs-observed field checks with violation signal.
- `dlp_alerts.jsonl` (**4,201 lines**) noisy alert stream with one critical API exposure event.
- `timeline_events.csv` (**5,004 lines**) SIEM sequence confirming exposed field identification.
- `openapi_snapshot.yaml` and `service_patch.diff` for contract and remediation context.
- `api_response_data_minimization_policy.txt` and `api_data_exposure_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-volume noisy API evidence requiring request-id based pivots.
- Multi-team correlation (SOC + AppSec + Dev) before final answer.
- Includes process artifacts for incident response flow.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5707`) and suspicious request ID.
2. Pivot gateway/request telemetry into response samples.
3. Validate schema drift in audit logs and OpenAPI contract.
4. Confirm sensitive field via DLP/SIEM normalized indicators.
5. Submit exposed sensitive field name.

Expected answer:
- `CTF{password}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m7/m7-07-api-data-exposure.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `req-8807120`, `password`, `sensitive_field`, `schema_audit`, `sensitive_field_identified`.
- Correlate gateway + response + schema + DLP + SIEM evidence for final answer.
