# M1-18 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Unintended public cloud object exposure resulting in external access to restricted data.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate cloud control-plane and data-plane evidence.
- Validate policy-state drift against access events and sensitive-object metadata.
- Distinguish approved internal data reads from unauthorized external access.

### Previous Artifact Weaknesses
- Minimal single-event evidence.
- Low realism for cloud triage workflows.
- Little noise, weak policy/version context, and limited governance linkage.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. AWS CloudTrail event reference:  
   https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-record-contents.html
2. Amazon S3 server access logging format:  
   https://docs.aws.amazon.com/AmazonS3/latest/userguide/LogFormat.html
3. S3 bucket policy and public access behavior:  
   https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
4. AWS GuardDuty finding types for S3/policy exposure:  
   https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-active.html
5. Amazon Macie sensitive data discovery findings:  
   https://docs.aws.amazon.com/macie/latest/user/findings-types.html

### Key Signals Adopted
- External IP `185.22.33.41` executed `GetObject` on restricted export object.
- CloudTrail policy status indicates `IsPublic = true` during incident window.
- Bucket policy version shows `Principal: "*"` public-read misconfiguration.
- Macie/GuardDuty elevated findings aligned to same object and time.
- Change record for public read exists as pending/unapproved.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `cloudtrail_events.jsonl` (**9,102 lines**) control/data plane event telemetry.
- `s3_access_logs.csv` (**7,803 lines**) object-level access records.
- `bucket_policy_versions.jsonl` (**2,602 lines**) policy drift timeline.
- `object_inventory.csv` (**5,602 lines**) sensitivity and object context.
- `identity_activity.csv` (**4,802 lines**) principal-level activity.
- `guardduty_findings.jsonl` (**3,401 lines**) noisy threat signals + critical incident.
- `macie_findings.csv` (**2,902 lines**) sensitivity findings with noise.
- `change_approvals.csv` (**1,802 lines**) governance/approval context.
- Briefing files for incident workflow.

Realism upgrades:
- Multi-source cloud evidence (IAM + S3 + detections + governance).
- High-volume baseline noise and false positives.
- Explicit policy-version drift and rollback sequence.
- Cross-correlation required by timestamp, request ID, and object key.

## Step 4 - Flag Engineering

Expected investigation path:
1. Start with ticket and identify object + incident window.
2. Confirm external object read in CloudTrail and S3 access logs.
3. Verify object is restricted (`contains_pii=yes`) in inventory.
4. Prove bucket became public via policy-version and policy-status evidence.
5. Correlate GuardDuty/Macie critical findings and change-approval gap.
6. Classify primary CIA impact.

Expected flag:
- `CTF{confidentiality}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-18-cloudtrail-incident.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for object key, external IP, and policy pivots.
- CSV filtering across access and finding timelines.
- `jq` for CloudTrail, policy-version, and GuardDuty JSONL analysis.
- Cross-source timeline stitching around `2026-03-06T11:20Z`.
