# M3-07 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Cloud credential exposure through leaked repository configuration.
- Task target: identify exposed AWS secret key value.

### Learning Outcome
- Correlate repository evidence, secret-detection telemetry, and cloud API usage.
- Distinguish normal cloud activity from post-leak abuse.
- Extract the true compromised secret from noisy data sources.

### Previous Artifact Weaknesses
- Minimal standalone config artifact with immediate answer visibility.
- No realistic leak chain or attacker-behavior confirmation.
- Missing SOC context across code, cloud, and SIEM systems.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Unsecured Credentials / Cloud Accounts:  
   https://attack.mitre.org/techniques/T1552/  
   https://attack.mitre.org/techniques/T1078/004/
2. AWS CloudTrail investigation model and API event correlation:  
   https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-record-contents.html
3. NIST SP 800-61 incident correlation workflow for containment and evidence triage:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
4. Secret-scanning workflows (repo commit + alerting + remediation sequencing).

### Key Signals Adopted
- Commit `91be7f0c12aa` introduces `config/cloud/config.json`.
- Exposed material includes `aws_secret_key` in plaintext.
- Secret scanner flags critical open finding for the same commit/file.
- CloudTrail records external IP usage shortly after exposure.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `config.json` (**8 lines**) leaked cloud config with secret material.
- `repo_file_index.csv` (**8,602 lines**) repo metadata and noise.
- `commit_history.log` (**7,201 lines**) commit stream with malicious pivot.
- `commit_diff.patchlog` (**61,614 lines**) diff telemetry including leaked secret commit.
- `secret_scanner_alerts.csv` (**4,702 lines**) scanner findings with false positives/noise.
- `cloudtrail_usage.jsonl` (**5,202 lines**) cloud API activity and suspicious external usage.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression.
- `cloud_credential_policy.txt` (**4 lines**) expected governance baseline.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- End-to-end sequence from code leak to external credential abuse.
- Multi-source analyst workflow (Repo + Scanner + CloudTrail + SIEM + Policy).
- High-noise datasets with realistic timestamps and pivots.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident brief and pivot to suspect commit/file.
2. Validate leaked secret in commit diff and leaked config.
3. Confirm detection in secret scanner alerts.
4. Correlate with suspicious external CloudTrail API usage.
5. Extract exposed secret key value.

Expected answer:
- `CTF{XyZSecretKey987}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m3/m3-07-cloud-access-leak.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `91be7f0c12aa`, `aws_secret_key`, `XyZSecretKey987`, `185.199.110.42`.
- CSV filtering for scanner and SIEM timelines.
- JSONL parsing for CloudTrail (`jq`, `grep`).
