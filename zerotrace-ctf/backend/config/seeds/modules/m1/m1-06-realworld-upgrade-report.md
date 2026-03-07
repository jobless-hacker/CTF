# M1-06 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Source-code secret exposure in version control.
- CIA mapping target: identify the **primary impacted pillar** after credential leak.

### Learning Outcome
- Investigate leaked-secret incidents across repository, detection, and cloud-usage evidence.
- Distinguish true credential exposure from noisy/false-positive detections.
- Correlate timeline from commit -> alert -> credential abuse.

### Previous Artifact Weaknesses
- Very small, linear evidence.
- Limited noisy background activity.
- Minimal cross-system correlation (Git only, weak cloud impact context).

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. GitHub Secret Scanning overview (alerts and detection model):  
   https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning
2. GitHub Push Protection behavior (block/bypass flow):  
   https://docs.github.com/en/code-security/secret-scanning/introduction/about-push-protection
3. GitHub supported secret patterns (provider token categories):  
   https://docs.github.com/en/code-security/secret-scanning/introduction/supported-secret-scanning-patterns
4. Git commit history output structures (`git log` formats):  
   https://git-scm.com/docs/git-log
5. Patch/context output semantics (`git show`):  
   https://git-scm.com/docs/git-show
6. AWS CloudTrail event record fields (`eventVersion`, `eventName`, `sourceIPAddress`, etc.):  
   https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-record-contents.html
7. AWS IAM access key handling and risk context:  
   https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html
8. GitHub audit log event naming pattern (`category.operation`):  
   https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/auditing-enterprise-and-organization-events-for-your-enterprise

### Key Signals Adopted
- Push protection bypass immediately before merge.
- Secret-scanning critical alert pointing to production env file lines.
- CloudTrail usage of leaked access key from new external IP.
- High-volume normal repo activity and false-positive secret patterns for realism.

## Step 3 - Artifact Design Upgrade

Upgraded artifact pack includes:
- `git_log_fuller.txt` (**75,006 lines**) realistic noisy commit history.
- `push_activity_events.csv` (**13,204 lines**) push/PR telemetry plus bypass event.
- `secret_scanning_alerts.jsonl` (**4,602 lines**) alert stream with false positives and true critical alert.
- `github_audit_log.jsonl` (**2,401 lines**) repository audit events + bypass record.
- `cloudtrail_events.jsonl` (**7,802 lines**) mostly normal data events plus suspicious external key use.
- `normalized_findings.csv` (**5,404 lines**) SIEM-normalized detections.
- Briefing and response files (`incident_ticket`, `analyst_handoff`, timeline, rotation plan).
- `git_show_leak_commit.patch` containing exposed key pair in realistic diff context.

Realism upgrades:
- Multi-source evidence (Git + GitHub security + SIEM + CloudTrail).
- Large noisy datasets with false positives.
- Realistic timestamps and actor/IP variation.
- Investigation requires timeline correlation, not single-file reading.

## Step 4 - Flag Engineering

Expected investigation path:
1. Confirm leaked credentials in commit diff.
2. Verify push-protection bypass and secret-scanning critical alert.
3. Correlate cloud usage of same key from unexpected external source.
4. Conclude which CIA pillar is primarily impacted.

Expected flag:
- `CTF{confidentiality}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-06-github-secret-leak.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for commit, key, and bypass pivots.
- CSV filtering for actor/time correlation.
- `jq` for JSONL inspection (alerts, audit logs, CloudTrail).
- Timeline sorting to prove exposure before external usage.
