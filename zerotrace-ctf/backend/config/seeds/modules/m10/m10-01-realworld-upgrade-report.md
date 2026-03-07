# M10-01 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- File-signature analysis and true file-type attribution.
- Task target: identify real type of recovered `file.bin`.

### Learning Outcome
- Correlate signature carving, magic detection, and triage telemetry.
- Investigate misnamed files in noisy forensic datasets.
- Confirm findings using SIEM normalization events.

### Previous Artifact Weaknesses
- Minimal single-file clue made answer immediate.
- No realistic forensic triage context.
- No noisy evidence requiring correlation.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Recovered-file inventory exports from disk-image triage.
2. File-carving signature logs.
3. Magic scan and YARA triage streams.
4. SIEM timeline events for final type confirmation.

### Key Signals Adopted
- `file.bin` has PNG signature `89 50 4E 47 0D 0A 1A 0A`.
- Magic scan resolves `real_type=png` at high confidence.
- SIEM confirms final file-type event.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `recovered_files_inventory.csv` (**6,802 lines**) triage inventory with target file.
- `file_carving.log` (**7,301 lines**) carving signatures with one target PNG header event.
- `magic_scan_results.jsonl` (**5,601 lines**) magic detections with target `real_type=png`.
- `yara_triage.log` (**5,201 lines**) noisy triage stream with target embedded PNG rule.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and `file_type_confirmed` event.
- `file.bin` binary evidence and `hex_dump_target.txt`.
- Incident briefing, case notes, and intel snapshot.

Realism upgrades:
- High-noise DFIR evidence requiring pivots across tools.
- Mismatch extension vs signature workflow mirrors real triage.
- Final answer comes from correlated forensic outputs.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-6001`).
2. Locate `file.bin` in recovered inventory.
3. Confirm PNG magic in carving/hexdump evidence.
4. Validate with magic scan + SIEM confirmation.
5. Submit real file type.

Expected answer:
- `CTF{png}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m10/m10-01-suspicious-file-type.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `file.bin`, `89 50 4E 47`, `real_type\":\"png`, `file_type_confirmed`.
- Confirm file type using at least two independent forensic sources.
