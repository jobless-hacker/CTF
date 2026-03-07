# M1-17 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Unauthorized source-code modification introduced into protected branch.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate git history, branch/audit events, auth telemetry, and review workflow evidence.
- Validate whether a code path was changed outside approved controls.
- Separate legitimate emergency windows from unauthorized abuse.

### Previous Artifact Weaknesses
- Small commit-only evidence with limited context.
- No realistic repo/audit/auth noise.
- Weak demonstration of control bypass chain.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. Git commit signing and verification concepts:  
   https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work
2. GitHub branch protection controls (PR/signature requirements):  
   https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
3. OWASP CI/CD Security guidance (pipeline and SCM trust boundaries):  
   https://owasp.org/www-project-top-10-ci-cd-security-risks/
4. NIST SP 800-61 incident handling (evidence correlation workflow):  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
5. SLSA provenance/integrity principles (software supply chain):  
   https://slsa.dev/spec/v1.0/

### Key Signals Adopted
- Direct push to `main` from unknown actor and anomalous IP.
- Unverified commit signature on suspicious commit.
- PR/review flow bypass (`PR-NA`, direct push event).
- Payment verification logic altered to bypass checks on retry traffic.
- Temporary protection-relaxation window + immediate restore sequence.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `commit_history.log` (**8,602 lines**) repository history with noise + suspicious entry.
- `repo_audit_events.jsonl` (**7,203 lines**) high-volume audit trail across repo actions.
- `git_server_auth.log` (**6,103 lines**) authentication/session evidence.
- `commit_signature_verification.csv` (**5,702 lines**) signature state telemetry.
- `pipeline_runs.csv` (**4,202 lines**) CI context including suspicious short test run.
- `pr_review_events.csv` (**3,602 lines**) code review workflow signals.
- `change_calendar.csv` (**2,202 lines**) approved change-window context.
- `suspicious_commit.patch` + briefing files.

Realism upgrades:
- Multi-source DevSecOps evidence instead of single patch file.
- High-volume background activity and false positives.
- End-to-end control-bypass investigation path.
- Attribution via request/commit/time pivots across logs.

## Step 4 - Flag Engineering

Expected investigation path:
1. Start with incident ticket and suspect commit ID.
2. Confirm malicious logic drift in `suspicious_commit.patch`.
3. Validate direct push to protected branch from unknown actor/IP.
4. Confirm commit signature is unverified.
5. Confirm missing PR/review workflow for this commit.
6. Use change calendar + protection updates to understand abuse context.
7. Classify primary CIA impact.

Expected flag:
- `CTF{integrity}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-17-unauthorized-git-commit.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for commit hash and direct-push pivots.
- CSV filtering for signature, CI, and review records.
- `jq` for audit JSONL triage.
- Timeline stitching by timestamp around `2026-03-06T09:12Z`.
