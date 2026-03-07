# M3-06 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Confidential internal document exposure and insider-risk investigation.
- Task target: identify confidential project name from leaked document evidence.

### Learning Outcome
- Correlate document content with repository, sharing, email, DLP, identity, and SIEM telemetry.
- Validate confidentiality breach and external access path.
- Extract key intelligence (project name) from realistic noisy artifacts.

### Previous Artifact Weaknesses
- Single short document artifact with immediate answer visibility.
- No evidence of leak pathway or SOC context.
- Minimal realism and no investigative depth.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Data from Information Repositories / Data staged/shared externally:  
   https://attack.mitre.org/techniques/T1213/  
   https://attack.mitre.org/techniques/T1567/
2. NIST SP 800-61 incident analysis and correlation workflow:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. Insider-risk monitoring model: document classification + external sharing + DLP/UEBA + access logs.

### Key Signals Adopted
- Leaked file `strategic_program_briefing.txt` marked confidential.
- Outbound email + public share access indicate external exposure chain.
- DLP high/critical signals confirm confidential leak and external retrieval.
- Document content contains `Project Name: Falcon`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `strategic_program_briefing.txt` (**5,410 lines**) leaked document content.
- `document_repo_index.csv` (**8,902 lines**) repository metadata.
- `public_share_access.log` (**7,602 lines**) public access telemetry.
- `outbound_mail_log.csv` (**5,202 lines**) possible exfil path.
- `dlp_document_alerts.jsonl` (**4,302 lines**) data-protection detections.
- `timeline_events.csv` (**5,004 lines**) SIEM progression.
- `identity_context.csv` (**6 lines**) account-role context.
- `confidential_document_policy.txt` (**4 lines**) policy baseline.
- Briefing files.

Realism upgrades:
- End-to-end leak chain from unauthorized share to public download.
- High-noise operational records with targeted malicious indicators.
- Multi-source analyst workflow typical for insider/document incidents.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and exposed document name.
2. Confirm confidential classification in repo metadata and policy.
3. Correlate external email/share activity and public retrieval.
4. Confirm DLP/SIEM critical events.
5. Inspect leaked document and extract project name.

Expected answer:
- `CTF{Falcon}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m3/m3-06-internal-document.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `strategic_program_briefing.txt`, `confidential`, `Falcon`.
- CSV filtering in repo and mail logs.
- JSONL filtering for high/critical DLP events.
