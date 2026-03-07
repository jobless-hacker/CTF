# M10-07 Instructor Notes

## Objective
- Train learners to identify a deleted sensitive file from realistic filesystem telemetry.
- Expected answer: `CTF{credentials.txt}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-6007`
   - objective: identify deleted sensitive file
2. In `filesystem.log` and `deleted_files_preview.txt`, identify initial deleted-file candidates.
3. In `deletion_journal.csv`, locate high-signal deletion event for sensitive path.
4. In `fs_audit.log`, confirm unlink event and normalized deleted-file token.
5. In `recovery_catalog.jsonl`, validate deleted candidate with high confidence.
6. In `index_correlation.csv`, confirm correlation mapping for deleted file.
7. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final answer token.
8. Submit normalized filename.

## Key Indicators
- File pivots:
  - `credentials.txt`
  - `normalized_deleted_file=credentials.txt`
- SIEM pivots:
  - `sensitive_deleted_file_confirmed`
  - `ctf_answer_ready`

## Suggested Commands / Tools
- `rg "credentials.txt|normalized_deleted_file|sensitive_deleted_file_confirmed|ctf_answer_ready" evidence`
- Review:
  - `evidence/filesystem.log`
  - `evidence/forensics/deleted_files_preview.txt`
  - `evidence/forensics/deletion_journal.csv`
  - `evidence/forensics/fs_audit.log`
  - `evidence/forensics/recovery_catalog.jsonl`
  - `evidence/forensics/index_correlation.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
