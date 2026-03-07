# M9-01 Instructor Notes

## Objective
- Train learners to perform realistic OSINT geolocation analysis from image metadata.
- Expected answer: `CTF{hyderabad}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5901`
   - target image: `IMG_8842.JPG`
2. In `camera_roll_index.csv`, locate target file and confirm geotag presence.
3. In `exif_batch_audit.log`, pivot on target file and extract GPS values.
4. In `geotag_extract.jsonl`, validate high-confidence city guess for target.
5. In `reverse_geo_lookup.csv`, confirm coordinates map to city `hyderabad`.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm normalized final city.
7. Submit city name.

## Key Indicators
- File pivot:
  - `IMG_8842.JPG`
- GPS pivot:
  - `17.3850`
  - `78.4867`
- City pivot:
  - `hyderabad`
  - `geolocation_match_confirmed`

## Suggested Commands / Tools
- `rg "IMG_8842.JPG|17.3850|78.4867|hyderabad|geolocation_match_confirmed" evidence`
- Review:
  - `evidence/metadata/camera_roll_index.csv`
  - `evidence/metadata/exif_batch_audit.log`
  - `evidence/metadata/geotag_extract.jsonl`
  - `evidence/osint/reverse_geo_lookup.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
