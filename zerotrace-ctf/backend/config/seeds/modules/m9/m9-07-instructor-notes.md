# M9-07 Instructor Notes

## Objective
- Train learners to extract camera attribution from realistic image metadata pipelines.
- Expected answer: `CTF{Canon_EOS_80D}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5907`
   - target file: `target_image.jpg`
2. In `image_inventory.csv`, locate target image entry.
3. In `exif_parser.log`, extract camera model for target image.
4. In `xmp_extraction.jsonl`, validate XMP camera model for target.
5. In `camera_fingerprint.csv`, confirm fingerprint-based model inference.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final model attribution.
7. Submit normalized answer format.

## Key Indicators
- File pivot:
  - `target_image.jpg`
- Model pivot:
  - `Canon EOS 80D`
- SIEM pivot:
  - `camera_model_confirmed`

## Suggested Commands / Tools
- `rg "target_image.jpg|Canon EOS 80D|camera_model_confirmed" evidence`
- Review:
  - `evidence/image_metadata.txt`
  - `evidence/osint/image_inventory.csv`
  - `evidence/osint/exif_parser.log`
  - `evidence/osint/xmp_extraction.jsonl`
  - `evidence/osint/camera_fingerprint.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
