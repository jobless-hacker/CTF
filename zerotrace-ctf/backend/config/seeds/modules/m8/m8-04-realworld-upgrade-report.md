# M8-04 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Overprivileged IAM role configuration with wildcard permissions.
- Task target: identify dangerous permission value.

### Learning Outcome
- Investigate IAM risk using inventory, policy docs, simulator output, and security detections.
- Correlate posture telemetry with risk confirmation events.
- Extract normalized dangerous permission value for remediation.

### Previous Artifact Weaknesses
- Single IAM policy file exposed answer immediately.
- No realistic IAM posture or risk-correlation workflow.
- Missing policy/runbook and SOC signal context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. IAM role inventory logs for posture and risk status.
2. Policy document streams showing effective permission structures.
3. Access advisor and simulator evidence for practical risk confirmation.
4. Security alerts and SIEM timeline normalization for dangerous permission extraction.

### Key Signals Adopted
- `migration-admin-role` flagged overprivileged in role inventory.
- Policy documents and raw policy JSON include `Action: "*"`.
- Simulator confirms broad destructive action allowed due to wildcard.
- Alert/SIEM normalize dangerous permission value as `*`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `iam_role_inventory.log` (**7,101 lines**) baseline role posture and one violation signal.
- `iam_policy_documents.jsonl` (**5,601 lines**) policy stream with critical wildcard policy.
- `access_advisor.csv` (**5,202 lines**) usage profile showing role overreach risk.
- `iam_simulator.log` (**5,401 lines**) decision traces confirming wildcard impact.
- `iam_risk_alerts.jsonl` (**4,301 lines**) noisy alerts and one critical overprivileged role alert.
- `timeline_events.csv` (**5,004 lines**) SIEM confirmation and dangerous permission identification.
- `iam_policy.json` direct evidence artifact.
- `iam_least_privilege_policy.txt` and `overprivileged_iam_role_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-noise IAM telemetry requiring pivots across multiple data sources.
- Combines policy static analysis and permission simulation context.
- Includes operational incident-handling material.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5804`) and target role.
2. Identify overprivileged role signal in inventory/policy artifacts.
3. Confirm dangerous permission behavior through simulator output.
4. Validate alert/SIEM normalized dangerous permission value.
5. Submit dangerous permission value.

Expected answer:
- `CTF{*}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m8/m8-04-overprivileged-iam-role.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `dangerous_permission`, `Action":"*"`, `wildcard_action`, `decision=allowed`, `dangerous_permission_identified`.
- Correlate inventory/policy/simulator/alert evidence before submission.
