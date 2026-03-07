# M10-09 Instructor Notes

## Objective
- Train learners to identify hidden stego keyword using realistic forensic telemetry.
- Expected answer: `CTF{shadow}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-6009`
   - target artifact: `picture.png`
2. In `stego_preview.txt` and `image_intake.csv`, verify target image and scan need.
3. In `steg_scan.log`, locate high-anomaly hidden-keyword detection.
4. In `lsb_probe.jsonl`, validate high-confidence extracted token.
5. In `keyword_correlation.csv`, confirm mapped keyword result.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final keyword token.
7. Submit hidden keyword.

## Key Indicators
- Artifact pivots:
  - `picture.png`
- Keyword pivots:
  - `shadow`
  - `hidden_keyword_detected`
- SIEM pivots:
  - `suspicious_stego_keyword`
  - `ctf_answer_ready`

## Suggested Commands / Tools
- `rg "picture.png|shadow|hidden_keyword_detected|suspicious_stego_keyword|ctf_answer_ready" evidence`
- Review:
  - `evidence/picture.png`
  - `evidence/forensics/stego_preview.txt`
  - `evidence/forensics/image_intake.csv`
  - `evidence/forensics/steg_scan.log`
  - `evidence/forensics/lsb_probe.jsonl`
  - `evidence/forensics/keyword_correlation.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
