# M9-10 Instructor Notes

## Objective
- Train learners to attribute developer identity from leaked public-code artifacts.
- Expected answer: `CTF{alice_dev}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5910`
   - goal: identify leaked developer username
2. In `repo_commit_history.csv`, locate suspicious commit row and author username.
3. In `git_audit.log`, confirm actor associated with target repository push.
4. In `contributor_graph.jsonl`, validate contributor node for same username.
5. In `code_search_hits.csv`, confirm author hint linked to target repository context.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final username attribution.
7. Submit developer username.

## Key Indicators
- Username pivot:
  - `alice_dev`
- Commit pivot:
  - `92ad8f`
- SIEM pivot:
  - `developer_identity_confirmed`

## Suggested Commands / Tools
- `rg "alice_dev|92ad8f|developer_identity_confirmed" evidence`
- Review:
  - `evidence/github_commit.txt`
  - `evidence/code/repo_commit_history.csv`
  - `evidence/code/git_audit.log`
  - `evidence/code/contributor_graph.jsonl`
  - `evidence/code/code_search_hits.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
