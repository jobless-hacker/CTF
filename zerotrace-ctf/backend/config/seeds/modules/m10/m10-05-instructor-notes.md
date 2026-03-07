# M10-05 Instructor Notes

## Objective
- Train learners to decode a suspicious base64 indicator using realistic forensic telemetry.
- Expected answer: `CTF{attack}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-6005`
   - objective: decode encoded payload
2. In `encoded.txt` and `encoded_preview.txt`, identify encoded target string.
3. In `decode_queue.csv`, locate target payload processing row.
4. In `b64_scan.log`, confirm candidate validity and decoded value.
5. In `decode_analytics.jsonl`, validate high-confidence decoded result.
6. In `correlation_matrix.csv`, confirm mapping of encoded to decoded token.
7. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final decoded indicator.
8. Submit decoded token.

## Key Indicators
- Encoded pivots:
  - `YXR0YWNr`
- Decoded pivots:
  - `attack`
  - `decoded=attack`
- SIEM pivots:
  - `suspicious_decoded_indicator`
  - `ctf_answer_ready`

## Suggested Commands / Tools
- `rg "YXR0YWNr|decoded=attack|suspicious_decoded_indicator|ctf_answer_ready" evidence`
- Review:
  - `evidence/encoded.txt`
  - `evidence/forensics/encoded_preview.txt`
  - `evidence/forensics/decode_queue.csv`
  - `evidence/forensics/b64_scan.log`
  - `evidence/forensics/decode_analytics.jsonl`
  - `evidence/forensics/correlation_matrix.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
