# M5-01 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Unauthorized Linux account creation and identity abuse on a production host.
- Task target: identify the suspicious username created outside approved process.

### Learning Outcome
- Pivot across identity sources (`/etc/passwd`, auditd, auth, SIEM, alerts).
- Separate noisy routine account telemetry from true suspicious provisioning.
- Produce a clear SOC answer with account-level evidence.

### Previous Artifact Weaknesses
- Small single-file artifact with direct answer visibility.
- No realistic SOC correlation path across multiple evidence sources.
- Limited operational context and no noise/false-positive pressure.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Linux account investigation workflow using `/etc/passwd` plus auth/audit correlation.
2. SOC escalation model for unauthorized account provisioning in production.
3. ATT&CK-style behavior mapping for account creation/valid-account abuse.
4. NIST-aligned incident triage flow: ticket -> evidence correlation -> conclusion.

### Key Signals Adopted
- New account creation event in identity audit stream.
- First login and privileged command activity for that account.
- SIEM and alert entries marking unauthorized local account behavior.
- Identity policy and runbook excerpts to anchor analyst decisioning.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `passwd_snapshot.txt` (**8,626 lines**) large Linux account dataset with noise + suspicious account.
- `user_change_audit.log` (**7,003 lines**) account lifecycle telemetry including unauthorized `useradd`.
- `auth.log` (**7,603 lines**) SSH and sudo trail including first suspicious login.
- `home_inventory.csv` (**6,402 lines**) home path inventory showing newly created home directory.
- `identity_alerts.jsonl` (**4,301 lines**) SOC identity alerts with one critical suspicious-user indicator.
- `timeline_events.csv` (**5,004 lines**) SIEM sequence for investigation progression.
- `account_provisioning_policy.txt` and `linux_user_investigation_runbook.txt` for operational context.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source evidence chain with high-noise background activity.
- Realistic timestamps, host context, and SOC incident framing.
- Clear but non-trivial investigative path to the final answer.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope in briefing files (`INC-2026-5501`, `lin-prod-01`).
2. Detect unauthorized account creation in `user_change_audit.log`.
3. Confirm same account in `auth.log` with suspicious login/sudo activity.
4. Validate critical alert marker in `identity_alerts.jsonl`.
5. Confirm user exists in `passwd_snapshot.txt`.
6. Submit the suspicious username.

Expected answer:
- `CTF{hacker}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m5/m5-01-suspicious-user.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `hacker`, `useradd account=`, `unauthorized_account_created`, `INC-2026-5501`.
- CSV review for `home_inventory.csv` and `timeline_events.csv`.
- JSONL filtering for critical identity alerts.
