# M9-10 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Public code leak investigation and developer identity attribution.
- Task target: identify leaked developer username.

### Learning Outcome
- Pivot across commit history, audit telemetry, and contributor-link evidence.
- Validate identity attribution through multiple noisy code intelligence sources.
- Use SIEM timeline normalization to confirm final answer.

### Previous Artifact Weaknesses
- One commit snippet directly disclosed username.
- No realistic repository-scale noise.
- Missing cross-source attribution process.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Repository commit-history exports with broad operational commits.
2. Git audit logs for push activity correlation.
3. Contributor graph and code-search evidence for attribution confidence.
4. SIEM timeline events for final identity confirmation.

### Key Signals Adopted
- Username `alice_dev` appears in target commit and supporting telemetry.
- Corroborated by git audit actor, contributor graph node, and code-search hint.
- SIEM confirms final developer identity event.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `repo_commit_history.csv` (**6,902 lines**) high-noise commit inventory with target row.
- `git_audit.log` (**7,401 lines**) audit stream with target push actor event.
- `contributor_graph.jsonl` (**5,601 lines**) contributor relationships with target contributor node.
- `code_search_hits.csv` (**5,202 lines**) code-search telemetry with target author hint.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and identity-confirmation event.
- `github_commit.txt` direct low-fidelity clue.
- Incident briefing, case notes, and intel snapshot.

Realism upgrades:
- High-volume code intelligence dataset resembling enterprise telemetry.
- Requires identity pivot across multiple evidence classes.
- Better emulates practical OSINT developer attribution workflow.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-5910`).
2. Locate suspicious commit and candidate username in commit history.
3. Confirm actor in git audit and contributor graph.
4. Validate with code-search hints and SIEM timeline.
5. Submit developer username.

Expected answer:
- `CTF{alice_dev}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m9/m9-10-public-code-leak.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `alice_dev`, `92ad8f`, `developer_identity_confirmed`.
- Confirm username appears in at least three independent evidence sources.
