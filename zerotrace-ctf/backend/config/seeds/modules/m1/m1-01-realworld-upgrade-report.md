# M1-01 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Cloud storage misconfiguration leading to unauthorized data exposure.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Read cloud evidence from multiple sources.
- Correlate control-plane and data-plane events.
- Separate real compromise signals from noisy traffic.

### Previous Artifact Weaknesses
- Very small dataset (few lines).
- Minimal noise and no realistic false-positive pressure.
- Single-source style evidence (easy answer without investigation flow).
- Limited operational context (no SOC handoff, no compliance telemetry).

## Step 2 - Real-World Artifact Investigation

Reference sources used to model realistic artifacts:

1. AWS S3 server access log format (field structure and semantics):  
   https://docs.aws.amazon.com/AmazonS3/latest/userguide/LogFormat.html
2. CloudTrail event record contents (eventName, sourceIPAddress, userIdentity, requestParameters):  
   https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-record-contents.html
3. AWS Config managed rule for S3 public-read prohibition (`s3-bucket-public-read-prohibited`):  
   https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-public-read-prohibited.html
4. AWS Security Hub finding schema (ASFF-style finding metadata):  
   https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-findings-format.html
5. S3 logging/audit guidance emphasizing CloudTrail and server-access telemetry:  
   https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-cloudtrail-logging-for-s3.html

### Key Signals Adopted
- Public bucket policy statement (`Principal: "*"` with `s3:GetObject`).
- Public-access-block drift.
- Config NON_COMPLIANT evaluation.
- Security Hub + Access Analyzer external-access findings.
- Anonymous/high-volume object reads from external IP in S3 server access logs.

## Step 3 - Artifact Design Upgrade

Upgraded pack now includes:
- `evidence/logs/s3_server_access.log` (10,570 lines with normal traffic + false positives + malicious pattern).
- `evidence/cloudtrail/cloudtrail_events.jsonl` (47 events with noisy baseline + policy-change pivot + anonymous reads).
- `evidence/config/aws_config_rule_evaluations.json`.
- `evidence/findings/security_hub_finding.json`.
- `evidence/findings/access_analyzer_finding.json`.
- `evidence/s3/bucket_policy_before.json` and `bucket_policy_after.json`.
- `evidence/s3/public_access_block_diff.json`.
- `evidence/s3/object_inventory.csv` with data classification.
- `evidence/briefing/incident_ticket.txt` and `triage_notes.txt`.

Realism upgrades:
- Multiple users/roles/IPs.
- Noise and false positives (scanner 403 events).
- Time-sequenced policy drift followed by data access.
- Sensitive and non-sensitive object mix.

## Step 4 - Flag Engineering

Expected path:
1. Confirm bucket policy drift to public-read.
2. Verify compliance findings flag the bucket as public.
3. Confirm successful reads of restricted data from external/anonymous context.
4. Map impact to CIA.

Expected flag:
- `CTF{confidentiality}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-01-public-bucket-exposure.zip`

Internal structure:
- `description.txt`
- `evidence/briefing/*`
- `evidence/s3/*`
- `evidence/config/*`
- `evidence/findings/*`
- `evidence/cloudtrail/*`
- `evidence/logs/*`

## Step 6 - Instructor Notes (Summary)

Suggested student tooling:
- `grep` / `rg` for key terms (`Principal`, `NON_COMPLIANT`, suspicious IP, sensitive prefixes).
- `jq` for JSON event pivoting.
- Spreadsheet/CLI filtering for S3 log focus windows.

Expected high-value pivots:
- `PutBucketPolicy` event around 08:08 UTC.
- Config NON_COMPLIANT around 08:10 UTC.
- Burst of successful external reads after 08:11 UTC.

