# M10-10 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Forensic attribution review and attacker-alias confirmation.
- Task target: identify attacker alias from final investigation package.

### Learning Outcome
- Correlate report narratives, timeline events, entity linking, and attribution telemetry.
- Distinguish high-confidence attacker identity from noisy candidate aliases.
- Validate final identity via SIEM confirmation workflow.

### Previous Artifact Weaknesses
- Very small report-only clue path.
- Limited realism for SOC/DFIR attribution workflows.
- No noisy data or cross-source evidence confirmation.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Case-timeline exports from investigation orchestration systems.
2. Entity-resolution logs with candidate alias confidence.
3. Intel-attribution records and correlation matrices.
4. SIEM final-confirmation events for attribution locking.

### Key Signals Adopted
- Attacker alias pivot: `darktrace`.
- Cross-source pivots: incident report, entity resolution, intel attribution, and matrix correlation.
- SIEM confirmation: `attacker_alias_confirmed`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `incident_report.txt` base report artifact with attribution section.
- `case_timeline.csv` (**6,802 lines**) timeline telemetry with attribution lock event.
- `entity_resolution.log` (**7,301 lines**) noisy candidate aliases plus confirmed alias.
- `intel_attribution.jsonl` (**5,601 lines**) structured attribution records.
- `attribution_matrix.csv` (**5,202 lines**) correlation matrix with high-confidence match.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and final attacker-alias confirmation.
- Incident briefing, analyst handoff, report preview, case notes, and intel snapshot.

Realism upgrades:
- High-volume, multi-source attribution evidence.
- Requires corroboration across multiple forensic systems.
- Reflects practical IR/SOC attacker attribution process.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-6010`) and report attribution section.
2. Pivot on alias candidates across entity/intel/matrix sources.
3. Confirm final alias with SIEM `attacker_alias_confirmed`.
4. Submit normalized attacker alias.

Expected answer:
- `CTF{darktrace}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m10/m10-10-forensic-report.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `darktrace`, `attacker_alias`, `attacker_alias_confirmed`, `ctf_answer_ready`.
- Validate with at least two forensic sources plus SIEM confirmation.
