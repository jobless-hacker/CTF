# M10-08 Instructor Notes

## Objective
- Train learners to decode a recovered hex artifact using realistic forensic datasets.
- Expected answer: `CTF{flag}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-6008`
   - objective: decode memory-carved hex artifact
2. In `hex_dump.txt` and `hex_preview.txt`, identify target hex sequence.
3. In `memory_segments.csv`, locate segment carrying the target sequence.
4. In `hexdump_capture.log`, confirm block-level appearance and ASCII hint.
5. In `ascii_candidates.jsonl`, validate high-confidence decode candidate.
6. In `pattern_correlation.csv`, verify mapped hex-to-ascii correlation.
7. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final ASCII indicator.
8. Submit ASCII word.

## Key Indicators
- Hex pivots:
  - `66 6C 61 67`
- ASCII pivots:
  - `flag`
  - `ascii=flag`
- SIEM pivots:
  - `suspicious_ascii_indicator`
  - `ctf_answer_ready`

## Suggested Commands / Tools
- `rg "66 6C 61 67|ascii=flag|suspicious_ascii_indicator|ctf_answer_ready" evidence`
- Review:
  - `evidence/hex_dump.txt`
  - `evidence/forensics/hex_preview.txt`
  - `evidence/forensics/memory_segments.csv`
  - `evidence/forensics/hexdump_capture.log`
  - `evidence/forensics/ascii_candidates.jsonl`
  - `evidence/forensics/pattern_correlation.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
