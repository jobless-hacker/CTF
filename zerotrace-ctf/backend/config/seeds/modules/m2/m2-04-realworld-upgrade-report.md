# M2-04 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Unexpected privileged-access behavior and sudo misuse investigation.
- Task target: identify the account that escalated privileges.

### Learning Outcome
- Correlate sudo, auth, command, audit, and policy evidence.
- Distinguish approved operational sudo usage from unauthorized escalation.
- Validate findings against change-control and role baseline.

### Previous Artifact Weaknesses
- Single short `sudo.log` file with minimal context.
- No policy or change-window cross-checks.
- No realistic SOC noise, timeline correlation, or multi-source depth.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Abuse Elevation Control Mechanism: Sudo and Valid Accounts:  
   https://attack.mitre.org/techniques/T1548/003/  
   https://attack.mitre.org/techniques/T1078/
2. Linux audit and privileged-command telemetry patterns (`sudo`, PAM, `auditd`):  
   https://man7.org/linux/man-pages/man8/sudo.8.html  
   https://man7.org/linux/man-pages/man8/auditd.8.html
3. NIST SP 800-61 incident analysis workflow for evidence correlation:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final

### Key Signals Adopted
- Restricted user `john` executes root commands (`su -`, `useradd`, `usermod`, `/etc/shadow` access).
- Audit log shows `auid=1007` driving root-level `EXECVE` actions.
- No approved change ticket for suspicious window (`NO-CHANGE`).
- Baseline policy explicitly marks `john` as non-privileged.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `sudo_activity.csv` (**12,506 lines**) high-volume sudo telemetry.
- `auth.log` (**9,073 lines**) PAM + sudo session evidence.
- `session_commands.csv` (**8,206 lines**) user/session command history.
- `auditd_execve.log` (**5,203 lines**) execution-level audit trail.
- `timeline_events.csv` (**4,705 lines**) SOC/SIEM event sequence.
- `change_window_registry.csv` (**2,602 lines**) change-control context.
- `privileged_access_baseline.txt` (**11 lines**) role and policy constraints.
- Briefing files.

Realism upgrades:
- Multi-source Linux + SOC evidence with significant noise.
- False positives from routine operations and denied events.
- Clear correlation path anchored on policy violation and unauthorized root actions.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and focus time window.
2. Find high-risk sudo events in `sudo_activity.csv`.
3. Correlate same user in `auth.log`, `session_commands.csv`, and `auditd_execve.log`.
4. Validate user role in `privileged_access_baseline.txt`.
5. Confirm no approved change in `change_window_registry.csv`.
6. Validate SIEM escalation in `timeline_events.csv`.
7. Return offending account.

Expected answer:
- `CTF{john}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m2/m2-04-unexpected-sudo-activity.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for pivots (`john`, `NO-CHANGE`, `auid=1007`, `policy_violation`).
- CSV filtering by time/user across sudo + session + timeline files.
- Optional `awk`/spreadsheet sorting for sequence reconstruction.
