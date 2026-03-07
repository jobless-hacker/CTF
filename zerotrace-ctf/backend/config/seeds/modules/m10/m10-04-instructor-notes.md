# M10-04 Instructor Notes

## Objective
- Train learners to identify suspicious privileged actions from realistic timeline evidence.
- Expected answer: `CTF{password_changed}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-6004`
   - objective: determine suspicious action token
2. In `timeline.log` and `timeline_preview.txt`, identify candidate privileged activity.
3. In `session_timeline.csv`, confirm suspicious event type for admin session.
4. In `auth_events.log`, validate matching `action=password_changed` evidence.
5. In `change_audit.jsonl`, confirm action record in identity workflow.
6. In `shell_audit.log`, confirm command context (`passwd admin`) with normalized action.
7. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final action token.
8. Submit normalized action answer.

## Key Indicators
- Action pivots:
  - `password_changed`
  - `admin_password_changed`
- SIEM pivots:
  - `suspicious_action_confirmed`
  - `ctf_answer_ready`

## Suggested Commands / Tools
- `rg "password_changed|admin_password_changed|suspicious_action_confirmed|ctf_answer_ready" evidence`
- Review:
  - `evidence/timeline.log`
  - `evidence/forensics/timeline_preview.txt`
  - `evidence/forensics/session_timeline.csv`
  - `evidence/forensics/auth_events.log`
  - `evidence/forensics/change_audit.jsonl`
  - `evidence/forensics/shell_audit.log`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
