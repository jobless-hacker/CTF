# M10-06 Instructor Notes

## Objective
- Train learners to identify executable file format from realistic binary-triage artifacts.
- Expected answer: `CTF{exe}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-6006`
   - objective: classify suspicious sample format
2. In `file_signature.txt` and `signature_preview.txt`, capture key magic bytes.
3. In `triage_inventory.csv`, locate target sample `sample.bin`.
4. In `header_scan.log`, confirm target magic `4D 5A` and candidate format.
5. In `string_extraction.jsonl`, validate executable indicators (`MZ` / DOS-mode string).
6. In `pe_analysis.csv`, confirm high-confidence detected format.
7. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final format token.
8. Submit normalized format value.

## Key Indicators
- Signature pivots:
  - `4D 5A`
  - `MZ`
- File pivot:
  - `sample.bin`
- Verdict pivots:
  - `format=exe`
  - `suspicious_executable_confirmed`
  - `ctf_answer_ready`

## Suggested Commands / Tools
- `rg "4D 5A|MZ|sample.bin|format=exe|suspicious_executable_confirmed|ctf_answer_ready" evidence`
- Review:
  - `evidence/file_signature.txt`
  - `evidence/forensics/signature_preview.txt`
  - `evidence/forensics/triage_inventory.csv`
  - `evidence/forensics/header_scan.log`
  - `evidence/forensics/string_extraction.jsonl`
  - `evidence/forensics/pe_analysis.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
