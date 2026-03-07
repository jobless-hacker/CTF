# M9-02 Instructor Notes

## Objective
- Train learners to investigate suspicious usernames with realistic OSINT evidence.
- Expected answer: `CTF{shadowfox92}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5902`
   - goal: one high-confidence suspicious username
2. In `forum_user_dump.csv`, identify suspicious candidate handle.
3. In `account_activity.log`, verify repeated suspicious events for the same handle.
4. In `handle_correlation.csv`, confirm `confirmed_suspicious_handle` verdict.
5. In `entity_graph.jsonl`, validate high-risk enrichment for that username.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm normalized final username.
7. Submit the suspicious username.

## Key Indicators
- Username pivot:
  - `shadowfox92`
- Correlation pivot:
  - `confirmed_suspicious_handle`
- SIEM pivot:
  - `suspicious_handle_confirmed`
- Risk pivot:
  - `"risk":"high"`

## Suggested Commands / Tools
- `rg "shadowfox92|confirmed_suspicious_handle|suspicious_handle_confirmed|risk\\\":\\\"high" evidence`
- Review:
  - `evidence/profile.txt`
  - `evidence/osint/forum_user_dump.csv`
  - `evidence/osint/account_activity.log`
  - `evidence/osint/handle_correlation.csv`
  - `evidence/osint/entity_graph.jsonl`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
