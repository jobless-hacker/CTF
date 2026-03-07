# M10-03 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Image metadata triage and acquisition-device attribution.
- Task target: identify the device used for target `photo.jpg`.

### Learning Outcome
- Correlate EXIF, XMP, inventory, fingerprint, and SIEM confirmation signals.
- Distinguish high-confidence attribution from normal pipeline noise.
- Validate final answer with multi-source forensic evidence.

### Previous Artifact Weaknesses
- Tiny single-file clue path.
- No realistic forensic pipeline context.
- No noisy telemetry or cross-source confirmation.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Large image inventory exports from evidence-ingest pipelines.
2. EXIF parsing logs and XMP extraction records.
3. Device-fingerprint correlation tables for attribution confidence.
4. SIEM timeline events confirming final analytic decisions.

### Key Signals Adopted
- Target file pivot: `photo.jpg`.
- Device pivot: `iPhone 13`.
- SIEM confirmation event: `device_confirmed`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- Binary image evidence: `photo.jpg`.
- `image_inventory.csv` (**6,802 lines**) with target row and ingest state.
- `exif_scan.log` (**7,301 lines**) noisy EXIF scans plus target camera model.
- `xmp_parse.jsonl` (**5,601 lines**) parsed metadata with confidence values.
- `device_fingerprint.csv` (**5,202 lines**) device attribution telemetry.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and final confirmation.
- Incident briefing, analyst handoff, case notes, metadata preview, and intel snapshot.

Realism upgrades:
- High-volume mixed-signal forensic logs.
- Requires cross-source correlation, not single-file lookup.
- Matches SOC/DFIR image-attribution workflow.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-6003`) and target file (`photo.jpg`).
2. Correlate EXIF camera model with XMP device model.
3. Validate with fingerprint confidence and SIEM `device_confirmed`.
4. Submit normalized device answer.

Expected answer:
- `CTF{iPhone_13}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m10/m10-03-image-metadata.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `photo.jpg`, `iPhone 13`, `device_confirmed`, `ctf_answer_ready`.
- Cross-check at least two forensic sources and SIEM confirmation before submission.
