# M5-10 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Unauthorized SSH key persistence and identity abuse on Linux hosts.
- Task target: identify attacker key-owner identity from investigation evidence.

### Learning Outcome
- Correlate key-file modifications with authentication and detection telemetry.
- Use key inventory and fingerprint ownership mapping for attribution.
- Extract attacker identity from noisy SOC/DFIR artifacts.

### Previous Artifact Weaknesses
- Single minimal artifact with direct answer visibility.
- No realistic event correlation across file integrity, auth, and SIEM sources.
- Missing ownership/fingerprint context typical in key-management investigations.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. SSH key compromise investigations (authorized_keys change + login correlation).
2. File integrity monitoring for `.ssh/authorized_keys` updates.
3. Fingerprint-to-owner mapping in IAM/SOC workflows.
4. SIEM escalation sequence for unauthorized key owner detection.

### Key Signals Adopted
- Unauthorized key appended to deploy account.
- File integrity events show modify and close-write during incident window.
- External key-based login accepted with attacker ownership marker.
- Alert and SIEM fields expose normalized suspicious key-owner value.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `ssh_key_inventory.csv` (**7,402 lines**) baseline + unauthorized owner record.
- `authorized_keys_snapshot.txt` (**6,703 lines**) realistic snapshot with suspicious key comment.
- `authorized_keys_integrity.log` (**5,602 lines**) file-integrity event trail.
- `sshd_auth.log` (**7,601 lines**) key-based login telemetry with suspicious owner context.
- `key_fingerprint_catalog.csv` (**6,102 lines**) fingerprint ownership mapping.
- `ssh_key_alerts.jsonl` (**4,301 lines**) alert stream with `suspicious_key_owner` field.
- `timeline_events.csv` (**5,103 lines**) SIEM timeline with unauthorized owner detection.
- `ssh_key_management_policy.txt` and `unauthorized_ssh_key_triage_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source identity + host telemetry aligned to SOC key-abuse triage.
- High-noise data and explicit ownership attribution workflow.
- Non-trivial answer path requiring evidence correlation.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5510`, node `lin-ssh-02`).
2. Find suspicious key entry in authorized_keys snapshot.
3. Correlate unauthorized owner in inventory and fingerprint catalog.
4. Confirm suspicious key-based login and alert/SIEM attribution.
5. Submit attacker key-owner value.

Expected answer:
- `CTF{attacker}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m5/m5-10-unauthorized-ssh-key.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `attacker@evil`, `suspicious_key_owner`, `authorized_keys`.
- CSV review for key inventory and fingerprint catalog.
- JSONL/SIEM filtering for unauthorized owner events.
