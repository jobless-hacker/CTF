# M10-04 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Timeline reconstruction and suspicious action identification.
- Task target: identify the risky action token in incident timeline evidence.

### Learning Outcome
- Correlate timeline, authentication, command, and audit trails.
- Identify high-signal administrative actions among noisy events.
- Validate conclusions with SIEM confirmation records.

### Previous Artifact Weaknesses
- Tiny static timeline with obvious answer.
- No realistic SOC/DFIR telemetry context.
- No noisy multi-source evidence correlation.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Session timeline exports from DFIR pipelines.
2. Authentication event logs and identity change-audit streams.
3. Shell audit traces for command-level context.
4. SIEM normalized timeline events confirming final verdict.

### Key Signals Adopted
- Suspicious action token: `password_changed`.
- Target context appears across timeline, auth, audit, shell, and SIEM datasets.
- Confirmation event: `suspicious_action_confirmed`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `timeline.log` baseline preview for entry-level orientation.
- `session_timeline.csv` (**6,802 lines**) high-volume session telemetry.
- `auth_events.log` (**7,301 lines**) authentication traces with noise and target action.
- `change_audit.jsonl` (**5,601 lines**) identity change records.
- `shell_audit.log` (**5,201 lines**) command audit context.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and final action confirmation.
- Incident briefing, analyst handoff, timeline preview, case notes, and intel snapshot.

Realism upgrades:
- Multiple correlated evidence sources with timestamped pivots.
- High noise-to-signal ratio requiring methodical investigation.
- Practical SOC/DFIR workflow for timeline-based investigation.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-6004`) and pivot on timeline anomaly.
2. Locate suspicious action token in timeline/auth/audit records.
3. Validate with SIEM `suspicious_action_confirmed` and `ctf_answer_ready`.
4. Submit normalized action token.

Expected answer:
- `CTF{password_changed}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m10/m10-04-timeline-event.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `password_changed`, `admin_password_changed`, `suspicious_action_confirmed`, `ctf_answer_ready`.
- Validate with at least two forensic sources plus SIEM confirmation.
