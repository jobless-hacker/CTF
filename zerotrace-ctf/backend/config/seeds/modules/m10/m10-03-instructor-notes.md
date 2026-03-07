# M10-03 Instructor Notes

## Objective
- Train learners to attribute image acquisition device using realistic forensic telemetry.
- Expected answer: `CTF{iPhone_13}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-6003`
   - target file: `photo.jpg`
2. In `image_inventory.csv`, locate the `photo.jpg` entry.
3. In `exif_scan.log`, identify camera model for `photo.jpg`.
4. In `xmp_parse.jsonl`, confirm `deviceModel` for same file.
5. In `device_fingerprint.csv`, validate high-confidence candidate device.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final device attribution.
7. Submit normalized device value.

## Key Indicators
- File pivot:
  - `photo.jpg`
- Device pivot:
  - `iPhone 13`
- SIEM pivot:
  - `device_confirmed`
  - `ctf_answer_ready`

## Suggested Commands / Tools
- `rg "photo.jpg|iPhone 13|device_confirmed|ctf_answer_ready" evidence`
- Review:
  - `evidence/photo.jpg`
  - `evidence/forensics/metadata_preview.txt`
  - `evidence/forensics/image_inventory.csv`
  - `evidence/forensics/exif_scan.log`
  - `evidence/forensics/xmp_parse.jsonl`
  - `evidence/forensics/device_fingerprint.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
