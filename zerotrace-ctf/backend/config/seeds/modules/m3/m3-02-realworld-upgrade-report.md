# M3-02 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Git repository secret exposure and credential leak triage.
- Task target: identify leaked database password from commit evidence.

### Learning Outcome
- Correlate repository history, commit diff content, secret scanner detections, and CI pipeline failures.
- Validate secret exposure against secure development policy.
- Extract leaked credential value from noisy, high-volume evidence.

### Previous Artifact Weaknesses
- Single short commit text with direct answer.
- No pipeline, scanner, or timeline context.
- Minimal realism and little investigation depth.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Credentials in Files and source-control exposure patterns:  
   https://attack.mitre.org/techniques/T1552/001/
2. NIST SP 800-61 incident analysis process for corroborating multi-source evidence:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. Secure SDLC practices around secret scanning and CI security gates in repository workflows.

### Key Signals Adopted
- Suspect commit `8d39f3a1c4ef` introduces plaintext `DB_PASSWORD`.
- Secret scanner marks critical finding with snippet `DB_PASSWORD=SuperSecret123`.
- CI pipeline security gate fails on exposed secret.
- Timeline confirms commit push -> scanner hit -> incident creation.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `git_history.log` (**9,801 lines**) commit stream.
- `commit_diffs.patchlog` (**59,210 lines**) diff evidence with noise.
- `secret_scanner_findings.csv` (**4,602 lines**) scanner outputs.
- `pipeline_security.log` (**5,203 lines**) CI security events.
- `repo_timeline.csv` (**5,004 lines**) SOC timeline.
- `secure_dev_policy.txt` (**4 lines**) policy controls.
- Briefing files.

Realism upgrades:
- High-volume repository telemetry with one critical secret leak.
- Cross-functional evidence (Dev + CI + Security + SOC).
- Investigative path requires commit correlation, not direct single-line answer.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident ticket to identify suspect commit.
2. Locate commit in history and diff evidence.
3. Confirm secret scanner critical match and snippet.
4. Confirm CI gate failure context.
5. Validate incident progression in timeline.
6. Extract leaked DB password.

Expected answer:
- `CTF{SuperSecret123}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m3/m3-02-github-credentials.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `8d39f3a1c4ef`, `DB_PASSWORD`, `SuperSecret123`.
- CSV filtering in scanner findings and timeline.
- Patch inspection around suspect commit region.
