# M9-07 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Hidden image metadata and hardware attribution.
- Task target: identify camera model from multi-source metadata evidence.

### Learning Outcome
- Pivot across EXIF, XMP, and camera fingerprint telemetry.
- Distinguish target camera signal from high-volume parser noise.
- Confirm attribution using SIEM normalized events.

### Previous Artifact Weaknesses
- Single metadata file exposed camera model directly.
- No realistic pipeline context or noisy image-processing evidence.
- No cross-source corroboration workflow.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Image inventory exports from media ingestion systems.
2. EXIF parsing logs with varied camera-model values.
3. XMP extraction outputs and camera-fingerprint datasets.
4. SIEM timeline confirmation for final hardware attribution.

### Key Signals Adopted
- Target file: `target_image.jpg`.
- EXIF/XMP/fingerprint all converge on `Canon EOS 80D`.
- SIEM confirms final camera model attribution event.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `image_inventory.csv` (**6,902 lines**) ingestion inventory noise plus target row.
- `exif_parser.log` (**7,301 lines**) parser output with target camera model line.
- `xmp_extraction.jsonl` (**5,601 lines**) XMP metadata stream with high-risk target record.
- `camera_fingerprint.csv` (**5,202 lines**) fingerprint inference stream with 0.99 target confidence.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and model-confirmed event.
- `image_metadata.txt` direct low-fidelity clue.
- Incident briefing, case notes, and intel snapshot.

Realism upgrades:
- High-noise image-forensics telemetry similar to real attribution workflows.
- Requires multi-source consistency checks before submission.
- Clear analyst pivot path from target file to model conclusion.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-5907`) and target file.
2. Pivot on `target_image.jpg` across EXIF/XMP/fingerprint sources.
3. Confirm with SIEM and intel notes.
4. Submit normalized camera model.

Expected answer:
- `CTF{Canon_EOS_80D}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m9/m9-07-hidden-image-info.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `target_image.jpg`, `Canon EOS 80D`, `camera_model_confirmed`.
- Validate model in at least two metadata sources plus SIEM event.
