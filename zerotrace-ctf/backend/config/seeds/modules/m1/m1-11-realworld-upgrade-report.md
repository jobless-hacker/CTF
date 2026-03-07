# M1-11 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Unauthorized/public sharing of a production cloud snapshot.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate cloud-permission changes across CloudTrail, snapshot state, and governance findings.
- Distinguish sandbox/public-test findings from production-impact findings.
- Validate whether sharing is restricted to approved accounts or the public principal.

### Previous Artifact Weaknesses
- Minimal evidence and direct answer path.
- Limited event noise and weak baseline context.
- Reduced realism for cloud-governance investigation workflows.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. AWS RDS `ModifyDBSnapshotAttribute` API (restore attribute behavior):  
   https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_ModifyDBSnapshotAttribute.html
2. AWS RDS `DescribeDBSnapshotAttributes` API (current permission state):  
   https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DescribeDBSnapshotAttributes.html
3. AWS RDS snapshot sharing model (`all` = public restore):  
   https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ShareSnapshot.html
4. AWS CloudTrail event record structure and key fields:  
   https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-record-contents.html
5. IAM Access Analyzer for external/public resource exposure findings:  
   https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html
6. AWS Security Hub RDS public snapshot control context:  
   https://docs.aws.amazon.com/securityhub/latest/userguide/rds-controls.html

### Key Signals Adopted
- CloudTrail `ModifyDBSnapshotAttribute` event adds `valuesToAdd=["all"]`.
- Snapshot current attributes confirm `restore` includes `all`.
- Governance and analyzer findings tie to production snapshot ID.
- Background sandbox findings included as false positives.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `snapshot_inventory.csv` (**5,602 lines**) large cloud snapshot inventory.
- `cloudtrail_events.jsonl` (**8,602 lines**) noisy management-event stream.
- `snapshot_attribute_history.csv` (**7,202 lines**) attribute-change timeline.
- `governance_findings.csv` (**6,302 lines**) governance control outputs.
- `access_analyzer_findings.jsonl` (**4,101 lines**) analyzer findings stream.
- `snapshot_attributes_current.json` and policy baseline for ground truth.
- Incident ticket, analyst handoff, and containment notes.

Realism upgrades:
- Multi-source cloud governance evidence.
- High-volume logs with sandbox/test false positives.
- Timeline-based correlation required for confident conclusion.
- Explicit baseline policy to evaluate drift against expected controls.

## Step 4 - Flag Engineering

Expected investigation path:
1. Identify production snapshot and approved-sharing baseline.
2. Confirm permission change event in CloudTrail (`ModifyDBSnapshotAttribute`).
3. Verify current state shows public restore permission (`all`).
4. Correlate governance/analyzer active findings for same resource.
5. Classify primary CIA impact.

Expected flag:
- `CTF{confidentiality}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-11-aws-public-snapshot.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for snapshot IDs and `valuesToAdd`.
- CSV filtering for timeline/resource correlation.
- `jq` for CloudTrail and analyzer JSONL triage.
- Compare findings against approved baseline policy.
