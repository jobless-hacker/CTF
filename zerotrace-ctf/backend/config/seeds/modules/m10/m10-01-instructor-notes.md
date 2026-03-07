# M10-01 Instructor Notes

## Objective
- Train learners to determine true file type from realistic forensic evidence.
- Expected answer: `CTF{png}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-6001`
   - target file: `file.bin`
2. In `recovered_files_inventory.csv`, locate target file record.
3. In `file_carving.log` and `hex_dump_target.txt`, identify PNG signature bytes.
4. In `magic_scan_results.jsonl`, confirm `real_type` for `file.bin`.
5. In `yara_triage.log`, verify related signature-based high-severity hit.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final type.
7. Submit file type.

## Key Indicators
- File pivot:
  - `file.bin`
- Signature pivot:
  - `89 50 4E 47 0D 0A 1A 0A`
- Type pivot:
  - `real_type":"png`
  - `file_type_confirmed`

## Suggested Commands / Tools
- `rg "file.bin|89 50 4E 47|real_type\\\":\\\"png|file_type_confirmed" evidence`
- Review:
  - `evidence/file.bin`
  - `evidence/forensics/hex_dump_target.txt`
  - `evidence/forensics/recovered_files_inventory.csv`
  - `evidence/forensics/file_carving.log`
  - `evidence/forensics/magic_scan_results.jsonl`
  - `evidence/security/yara_triage.log`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
