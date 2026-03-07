# M10-08 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Hex artifact interpretation and ASCII recovery in forensic workflows.
- Task target: decode recovered hex sequence into final ASCII word.

### Learning Outcome
- Correlate memory extraction, hexdump logs, decoding output, and SIEM confirmation.
- Filter noisy hex data to isolate investigation-relevant sequence.
- Validate decoded indicator using cross-source evidence.

### Previous Artifact Weaknesses
- Single short hex clue with direct decode path.
- No realistic DFIR context around memory artifacts.
- No noise or corroboration requirements.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Memory-segment exports from acquisition tooling.
2. Hexdump capture logs from carve pipelines.
3. ASCII-candidate decoding records with confidence values.
4. SIEM confirmation events for high-confidence decode outcomes.

### Key Signals Adopted
- Hex pivot: `66 6C 61 67`.
- ASCII pivot: `flag`.
- SIEM confirmation: `suspicious_ascii_indicator`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `hex_dump.txt` baseline recovered sequence.
- `memory_segments.csv` (**6,802 lines**) high-volume carved-segment telemetry.
- `hexdump_capture.log` (**7,301 lines**) noisy hexdump stream with target block.
- `ascii_candidates.jsonl` (**5,601 lines**) decode candidates with confidence scores.
- `pattern_correlation.csv` (**5,202 lines**) hex-to-ascii correlation mappings.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and final decode confirmation.
- Incident briefing, analyst handoff, hex preview, case notes, and intel snapshot.

Realism upgrades:
- Large mixed-signal hex telemetry across multiple tools.
- Requires correlation-based confirmation before answer submission.
- Reflects real forensic decoding workflow for memory artifacts.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-6008`) and capture hex pivot.
2. Correlate `66 6C 61 67` across memory/hexdump/decode/correlation records.
3. Confirm final decoded value with SIEM `suspicious_ascii_indicator`.
4. Submit decoded ASCII word.

Expected answer:
- `CTF{flag}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m10/m10-08-hex-artifact.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `66 6C 61 67`, `ascii=flag`, `suspicious_ascii_indicator`, `ctf_answer_ready`.
- Validate with at least two forensic sources plus SIEM confirmation.
