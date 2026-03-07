# M3-02 Instructor Notes

## Objective
- Train learners to investigate a credential leak from source-control activity using SOC + AppSec evidence.
- Expected answer: `CTF{SuperSecret123}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - repo: `org/crm-sync`
   - suspect commit: `8d39f3a1c4ef`
2. In `git_history.log`, find suspect commit metadata.
3. In `commit_diffs.patchlog`, inspect added lines and identify credential insertion.
4. In `secret_scanner_findings.csv`, confirm critical finding and leaked snippet.
5. In `pipeline_security.log`, confirm CI security gate failure tied to same secret.
6. In `repo_timeline.csv`, validate commit -> scanner -> incident sequence.
7. Cross-check with `secure_dev_policy.txt` for policy violation context.
8. Return leaked database password.

## Key Indicators
- Commit hash: `8d39f3a1c4ef`
- Secret key: `DB_PASSWORD`
- Leaked value: `SuperSecret123`
- Corroboration: scanner + CI + timeline agreement

## Suggested Commands / Tools
- `rg "8d39f3a1c4ef|DB_PASSWORD|SuperSecret123|secret_scanner_hit" evidence`
- CSV filtering in:
  - `secret_scanner_findings.csv`
  - `repo_timeline.csv`
- Diff parsing in `commit_diffs.patchlog` near suspect commit.
