# M9-01 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- OSINT and digital metadata analysis from a recovered image.
- Task target: identify the city linked to image geolocation metadata.

### Learning Outcome
- Analyze image-metadata investigations using multiple evidence sources.
- Correlate EXIF parsing with geotag extraction and reverse geocoding.
- Avoid single-source bias by confirming with SIEM and analyst context.

### Previous Artifact Weaknesses
- Single short text artifact revealed the answer immediately.
- No investigative noise or cross-source confirmation workflow.
- Missing SOC OSINT handoff structure.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Camera roll inventory exports from mobile/device collections.
2. EXIF extraction logs (`exiftool`-style) with mixed GPS/no-GPS records.
3. Reverse-geocoding outputs from multiple providers with confidence variance.
4. SIEM timeline normalization for final analyst confirmation.

### Key Signals Adopted
- Target image: `IMG_8842.JPG`.
- GPS signal: `lat=17.3850` and `lon=78.4867`.
- Cross-source city confirmation resolves to `hyderabad`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `camera_roll_index.csv` (**6,502 lines**) noisy device inventory plus target image entry.
- `exif_batch_audit.log` (**7,001 lines**) EXIF parser output with sparse GPS patterns.
- `geotag_extract.jsonl` (**5,401 lines**) normalized geotag records with one high-confidence target hit.
- `reverse_geo_lookup.csv` (**4,203 lines**) provider-based reverse geocode outputs with mixed city noise.
- `timeline_events.csv` (**5,004 lines**) SIEM pipeline events and final geolocation confirmation.
- `photo.jpg` (binary evidence placeholder), briefing files, OSINT notes, and intel snapshot.

Realism upgrades:
- Large noisy dataset requiring pivots across metadata, OSINT, and SIEM evidence.
- Includes false positives (`secunderabad` and other city noise) before final confirmation.
- Mimics real SOC OSINT enrichment pipelines.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5901`) and target file (`IMG_8842.JPG`).
2. Locate target in camera roll and EXIF outputs for GPS coordinates.
3. Validate coordinates across geotag extraction and reverse-geocode evidence.
4. Confirm final city in timeline/intel context.
5. Submit city value.

Expected answer:
- `CTF{hyderabad}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m9/m9-01-image-metadata.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `IMG_8842.JPG`, `17.3850`, `78.4867`, `hyderabad`, `geolocation_match_confirmed`.
- Cross-check at least two independent evidence sources before answer submission.
