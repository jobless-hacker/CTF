# M10-05 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Encoded artifact triage and base64 decoding in forensic context.
- Task target: decode recovered payload and submit normalized value.

### Learning Outcome
- Correlate encoded value across queue/log/analytics/correlation/siem sources.
- Separate noisy encoded fragments from actionable indicator payloads.
- Validate decoded output with high-confidence investigation signals.

### Previous Artifact Weaknesses
- Single tiny encoded string with direct answer path.
- No realistic telemetry or DFIR pipeline context.
- No noise or multi-source corroboration.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Decode queue exports from artifact-processing pipelines.
2. Base64 candidate scans from message or gateway logs.
3. Structured decode analytics and correlation records.
4. SIEM timeline events for final indicator confirmation.

### Key Signals Adopted
- Encoded pivot: `YXR0YWNr`.
- Decoded pivot: `attack`.
- SIEM confirmation: `suspicious_decoded_indicator`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `encoded.txt` original encoded artifact.
- `decode_queue.csv` (**6,802 lines**) queue records with target payload event.
- `b64_scan.log` (**7,301 lines**) base64 scan telemetry and decode hint.
- `decode_analytics.jsonl` (**5,601 lines**) structured decode decisions.
- `correlation_matrix.csv` (**5,201 lines**) mapping confidence records.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and final answer-ready event.
- Incident briefing, handoff notes, encoded preview, case notes, and intel snapshot.

Realism upgrades:
- High-volume noisy encoded fragments across multiple sources.
- Requires pivots and corroboration instead of one-shot decoding.
- Mirrors SOC/DFIR indicator decoding workflow.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-6005`) and identify encoded payload.
2. Pivot on `YXR0YWNr` in queue, scan, analytics, and correlation artifacts.
3. Confirm decode value with SIEM `suspicious_decoded_indicator`.
4. Submit decoded token.

Expected answer:
- `CTF{attack}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m10/m10-05-base64-artifact.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `YXR0YWNr`, `decoded=attack`, `suspicious_decoded_indicator`, `ctf_answer_ready`.
- Validate with at least two forensic sources plus SIEM confirmation.
