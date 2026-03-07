# M1-18 Instructor Notes

## Objective
- Train learners to investigate cloud object exposure using control-plane and data-plane evidence.
- Expected answer: `CTF{confidentiality}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - bucket: `customer-database-archive`
   - object: `exports/customer_pii_snapshot_2026-03-06.parquet`
   - window: around `2026-03-06T11:20Z`
2. In `cloudtrail_events.jsonl`, confirm:
   - external `GetObject` by IP `185.22.33.41`
   - `GetBucketPolicyStatus` shows `IsPublic=true`
3. In `s3_access_logs.csv`, verify matching request/object from external requester.
4. In `bucket_policy_versions.jsonl`, locate public policy change:
   - `Principal: "*"`
   - actor `temp-ops-sync`
5. In `object_inventory.csv`, confirm accessed object is sensitive (`restricted`, PII).
6. In `identity_activity.csv`, verify suspicious policy-change actor/IP pattern.
7. In `guardduty_findings.jsonl` and `macie_findings.csv`, validate critical detection alignment.
8. In `change_approvals.csv`, confirm change was pending/unapproved.
9. Classify CIA impact.

## Key Indicators
- External source IP: `185.22.33.41`
- Sensitive key: `exports/customer_pii_snapshot_2026-03-06.parquet`
- Policy drift: `Principal "*"`, `isPublic=true`
- Detection pivot: `Policy:S3/BucketPublicAccessGranted`

## Suggested Commands / Tools
- `rg "185.22.33.41|customer_pii_snapshot_2026-03-06.parquet|IsPublic|temp-ops-sync|BucketPublicAccessGranted" evidence`
- CSV filtering in:
  - `s3_access_logs.csv`
  - `object_inventory.csv`
  - `identity_activity.csv`
  - `macie_findings.csv`
  - `change_approvals.csv`
- `jq` for:
  - `cloudtrail_events.jsonl`
  - `bucket_policy_versions.jsonl`
  - `guardduty_findings.jsonl`
