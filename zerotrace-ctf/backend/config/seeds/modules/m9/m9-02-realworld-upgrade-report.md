# M9-02 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- OSINT handle investigation and suspicious username attribution.
- Task target: identify the suspicious username from evidence.

### Learning Outcome
- Correlate username intelligence across forum exports, activity logs, and entity enrichment.
- Distinguish high-confidence threat handle from noisy alias collisions.
- Validate final answer using SIEM normalization and intel context.

### Previous Artifact Weaknesses
- Single profile artifact made answer immediate.
- No operational OSINT enrichment workflow.
- Missing realistic noise and cross-source confirmation path.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Forum profile/user dump snapshots with broad noise.
2. Account activity telemetry with IP- and action-level context.
3. Handle-correlation datasets and entity graph enrichment outputs.
4. SIEM timeline events for final suspicious-handle confirmation.

### Key Signals Adopted
- Username `shadowfox92` appears as high-confidence suspicious in multiple sources.
- Activity and entity graph tie the handle to high-risk context.
- SIEM timeline and intel snapshot normalize the final handle value.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `forum_user_dump.csv` (**6,702 lines**) large forum snapshot with one target handle.
- `account_activity.log` (**7,102 lines**) noisy activity with two suspicious target events.
- `handle_correlation.csv` (**4,802 lines**) correlation output with one confirmed suspicious verdict.
- `entity_graph.jsonl` (**5,601 lines**) entity enrichment graph with target-risk record.
- `timeline_events.csv` (**5,103 lines**) SIEM telemetry and final answer-ready event.
- `profile.txt` direct low-fidelity clue.
- Incident briefing, case notes, and threat intel snapshot.

Realism upgrades:
- High-volume alias noise and false positives.
- Requires multi-source correlation, not single-file lookup.
- Matches SOC OSINT enrichment operations.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-5902`).
2. Find suspicious candidate in forum dump and profile evidence.
3. Validate with activity logs, handle correlation, and entity graph records.
4. Confirm with SIEM timeline and intel snapshot.
5. Submit suspicious username.

Expected answer:
- `CTF{shadowfox92}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m9/m9-02-suspicious-username.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `shadowfox92`, `confirmed_suspicious_handle`, `suspicious_handle_confirmed`, `risk\":\"high`.
- Verify consistency across at least three evidence sources before submission.
