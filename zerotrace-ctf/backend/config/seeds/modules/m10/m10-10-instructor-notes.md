# M10-10 Instructor Notes

## Objective
- Train learners to identify attacker alias from realistic attribution telemetry.
- Expected answer: `CTF{darktrace}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-6010`
   - objective: confirm attacker alias
2. In `incident_report.txt` and `report_preview.txt`, identify attribution section context.
3. In `case_timeline.csv`, locate attribution lock event.
4. In `entity_resolution.log`, find confirmed alias with high confidence.
5. In `intel_attribution.jsonl`, validate high-confidence attribution record.
6. In `attribution_matrix.csv`, confirm alias correlation result.
7. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final attacker alias token.
8. Submit attacker alias.

## Key Indicators
- Alias pivots:
  - `darktrace`
  - `attacker_alias=darktrace`
- SIEM pivots:
  - `attacker_alias_confirmed`
  - `ctf_answer_ready`

## Suggested Commands / Tools
- `rg "darktrace|attacker_alias|attacker_alias_confirmed|ctf_answer_ready" evidence`
- Review:
  - `evidence/incident_report.txt`
  - `evidence/forensics/report_preview.txt`
  - `evidence/forensics/case_timeline.csv`
  - `evidence/forensics/entity_resolution.log`
  - `evidence/forensics/intel_attribution.jsonl`
  - `evidence/forensics/attribution_matrix.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
