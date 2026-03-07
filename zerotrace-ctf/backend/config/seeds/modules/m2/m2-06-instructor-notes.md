# M2-06 Instructor Notes

## Objective
- Train learners to investigate suspicious privileged account creation and first-use activity in a SOC workflow.
- Expected answer: `CTF{backup_admin}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - identity host: `idm-srv-01`
   - access host: `bastion-01`
   - window: `2026-03-07 00:13-00:15 UTC`
2. In `admin_account_changes.csv`, identify a new admin account created with `NO-CHANGE`.
3. In `directory_audit.jsonl`, confirm high/critical identity alerts for same account.
4. In `command_audit.csv`, correlate root commands that created and modified the account.
5. In `privileged_sessions.log`, verify first privileged login and sudo actions by that account.
6. In `change_registry.csv`, confirm no approved change for this account creation.
7. In `admin_governance_baseline.txt`, verify policy violation.
8. In `timeline_events.csv`, confirm end-to-end escalation and return suspicious account name.

## Key Indicators
- Account: `backup_admin`
- Actor: `john`
- Change status: `NO-CHANGE`
- Security violation: MFA disabled on newly created admin account
- Rapid first-use privileged session on bastion

## Suggested Commands / Tools
- `rg "backup_admin|NO-CHANGE|mfa_disable|useradd|first_admin_login" evidence`
- CSV filtering in:
  - `admin_account_changes.csv`
  - `command_audit.csv`
  - `change_registry.csv`
  - `timeline_events.csv`
- `jq` for high/critical events in `directory_audit.jsonl`.
