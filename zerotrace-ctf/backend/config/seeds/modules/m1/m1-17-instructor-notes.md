# M1-17 Instructor Notes

## Objective
- Train learners to investigate unauthorized code modification in a protected Git workflow.
- Expected answer: `CTF{integrity}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - repo: `payments-platform`
   - suspect commit: `82hfd9a77b61c4da090f6e2a213e831d7f31a1aa`
2. Inspect `suspicious_commit.patch`:
   - payment verification logic changed
   - retry path bypass returns `True`
3. Confirm commit entry in `commit_history.log` with `author=unknown`.
4. Pivot into `repo_audit_events.jsonl`:
   - direct `repo.push` to `main`
   - details indicate push occurred without PR
5. Validate auth context in `git_server_auth.log`:
   - unknown user/token
   - anomalous IP
   - no MFA requirement
6. Confirm signature state in `commit_signature_verification.csv`:
   - `unverified` for suspicious commit
7. Check review workflow in `pr_review_events.csv`:
   - `direct_push` / `PR-NA`
8. Use `change_calendar.csv` and audit protection updates to understand control relaxation window.
9. Classify CIA impact.

## Key Indicators
- Commit: `82hfd9a77b61c4da090f6e2a213e831d7f31a1aa`
- Actor: `unknown`
- Branch event: direct push to `main` without PR
- Signature: `unverified`
- Code effect: verification logic bypass for retry payloads

## Suggested Commands / Tools
- `rg "82hfd9a77b61c4da090f6e2a213e831d7f31a1aa|unknown|direct push|unverified|retry" evidence`
- CSV filtering in:
  - `commit_signature_verification.csv`
  - `pipeline_runs.csv`
  - `pr_review_events.csv`
  - `change_calendar.csv`
- `jq` triage in `repo_audit_events.jsonl` by `action`, `branch`, and `commit`.
