# M2-06 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Investigation of suspicious privileged account provisioning and subsequent admin usage.
- Task target: identify the unexpected admin account.

### Learning Outcome
- Correlate identity management changes with endpoint command/audit and privileged login data.
- Validate account actions against governance policy and change management controls.
- Distinguish approved admin lifecycle events from malicious account creation.

### Previous Artifact Weaknesses
- Single short admin activity log with direct clueing.
- No policy baseline, no change-ticket validation, and no multi-source SOC workflow.
- Limited noise, low realism, and weak investigative depth.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Create Account / Valid Accounts / Account Manipulation:  
   https://attack.mitre.org/techniques/T1136/  
   https://attack.mitre.org/techniques/T1078/  
   https://attack.mitre.org/techniques/T1098/
2. NIST SP 800-61 incident handling for evidence correlation and triage:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. Identity governance and privileged-access monitoring patterns (directory audit + admin session telemetry + change control).

### Key Signals Adopted
- Unauthorized creation of `backup_admin` by `john` with `NO-CHANGE`.
- Immediate privilege expansion and MFA disablement on the new account.
- Near-immediate privileged login and root command execution by `backup_admin`.
- Governance baseline prohibits this flow.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `admin_account_changes.csv` (**11,204 lines**) identity change stream with noise.
- `command_audit.csv` (**8,406 lines**) endpoint command telemetry.
- `privileged_sessions.log` (**7,904 lines**) bastion/sudo session evidence.
- `directory_audit.jsonl` (**4,702 lines**) structured directory event alerts.
- `timeline_events.csv` (**5,205 lines**) SIEM correlation timeline.
- `change_registry.csv` (**2,802 lines**) approved-change context.
- `admin_governance_baseline.txt` (**9 lines**) privileged account policy.
- Briefing files.

Realism upgrades:
- Multi-source identity + host + auth + SIEM evidence.
- High-noise baseline entries and review events to simulate SOC triage.
- Practical investigative chain from creation to first abuse.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident window and hosts from ticket.
2. Detect suspicious account creation in identity changes and directory audit.
3. Correlate actor/session in command audit.
4. Validate first login and privileged usage in auth logs.
5. Check change ticket status and governance baseline.
6. Confirm SIEM escalation and return suspicious account.

Expected answer:
- `CTF{backup_admin}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m2/m2-06-new-admin-session.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` pivots: `backup_admin`, `NO-CHANGE`, `mfa_disable`, `first_admin_login`.
- CSV filtering by account and time in identity/endpoint/timeline records.
- `jq` for high-severity directory events.
