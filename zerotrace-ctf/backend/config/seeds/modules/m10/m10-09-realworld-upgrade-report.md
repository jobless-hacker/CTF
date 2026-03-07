# M10-09 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Steganography investigation and hidden-keyword extraction.
- Task target: identify keyword embedded in the picture artifact.

### Learning Outcome
- Correlate intake telemetry, stego scans, LSB probing, and SIEM confirmation.
- Separate noisy image-analysis output from high-confidence hidden content.
- Validate hidden keyword with multi-source evidence.

### Previous Artifact Weaknesses
- Single simple clue path with little forensic realism.
- No high-volume noise or multi-source corroboration.
- No structured SOC/DFIR investigation flow.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Image-ingest pipeline inventories.
2. Stego scan logs with anomaly scoring.
3. LSB probe extraction records and confidence values.
4. SIEM event timelines confirming high-confidence keyword findings.

### Key Signals Adopted
- File pivot: `picture.png`.
- Keyword pivot: `shadow`.
- SIEM confirmation: `suspicious_stego_keyword`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- Binary image evidence: `picture.png`.
- `image_intake.csv` (**6,802 lines**) large image-ingest telemetry with target row.
- `steg_scan.log` (**7,301 lines**) noisy scan output with target hidden-keyword detection.
- `lsb_probe.jsonl` (**5,601 lines**) extraction records and confidence scores.
- `keyword_correlation.csv` (**5,202 lines**) multi-source keyword correlation telemetry.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and final keyword confirmation.
- Incident briefing, analyst handoff, stego preview, case notes, and intel snapshot.

Realism upgrades:
- High-noise, multi-tool stego-analysis workflow.
- Requires cross-source pivots before submission.
- Mirrors practical forensic steganography investigations.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-6009`) and target artifact (`picture.png`).
2. Pivot on hidden-keyword signals across scan/probe/correlation evidence.
3. Confirm keyword with SIEM `suspicious_stego_keyword`.
4. Submit decoded hidden token.

Expected answer:
- `CTF{shadow}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m10/m10-09-stego-image.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `picture.png`, `shadow`, `hidden_keyword_detected`, `suspicious_stego_keyword`, `ctf_answer_ready`.
- Validate with at least two forensic sources plus SIEM confirmation.
