# M7-04 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Broken authentication from weak/default privileged credentials.
- Task target: identify authentication weakness class.

### Learning Outcome
- Detect weak-password exploitation amid noisy login activity.
- Correlate auth, policy, debug, and detection pipelines.
- Classify weakness as a concrete auth control failure.

### Previous Artifact Weaknesses
- Single simple auth log with direct clue path.
- No realistic multi-source SOC/AppSec investigation flow.
- Missing policy misconfiguration context and detection enrichment.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Login event streams with repeated failures then successful weak-credential auth.
2. Debug/trace logs exposing accepted low-strength credential behavior.
3. Password-policy audit gaps for privileged profile controls.
4. Alert and SIEM classification into auth weakness category.

### Key Signals Adopted
- Admin login success after weak credential attempt pattern.
- Debug row shows accepted `admin/admin` behavior.
- Legacy admin policy disables complexity/dictionary checks.
- Security alert and SIEM classify weakness as `weak_password`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `auth.log` (**9,210 lines**) high-volume auth telemetry with suspicious admin sequence.
- `login_debug.log` (**5,301 lines**) debug trace revealing accepted weak credential.
- `access.log` (**6,101 lines**) login endpoint web context.
- `password_policy_audit.txt` policy snapshot showing weak legacy controls.
- `bruteforce_summary.csv` (**5,501 lines**) auth analytics summary with weak-credential candidate.
- `auth_alerts.jsonl` (**4,301 lines**) security detection stream with critical weakness event.
- `timeline_events.csv` (**5,004 lines**) SIEM classification and incident sequence.
- `authentication_hygiene_policy.txt` and `broken_authentication_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- Noisy baseline plus one true-positive weak-password sequence.
- Multi-source evidence required for correct weakness classification.
- SOC/AppSec process context embedded via policy and runbook.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5704`, `/login`).
2. Identify suspicious admin auth pattern (failures -> success).
3. Confirm accepted weak credential in debug trace.
4. Validate weak policy controls and detection classification.
5. Submit authentication weakness class.

Expected answer:
- `CTF{weak_password}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m7/m7-04-broken-authentication.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `password=admin`, `legacy-admin`, `weak_password`.
- Correlate auth gateway, debug, policy, and alert/SIEM evidence.
- Use classification fields for final answer confirmation.
