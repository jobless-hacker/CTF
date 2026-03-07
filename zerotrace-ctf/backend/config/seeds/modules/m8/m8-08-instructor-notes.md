# M8-08 Instructor Notes

## Objective
- Train learners to investigate misconfigured storage policies and identify dangerous wildcard value.
- Expected answer: `CTF{*}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5808`
   - bucket: `corp-static`
2. In `bucket_policy.json` and `bucket_policy_versions.log`, identify wildcard principal usage.
3. In `policy_simulation.csv`, verify wildcard principal grants access.
4. In `cloudtrail_events.jsonl`, validate `PutBucketPolicy` event introducing wildcard principal.
5. In `object_access.log`, confirm anonymous access tied to wildcard policy.
6. In `policy_audit.log`, confirm control violation.
7. In `storage_policy_alerts.jsonl` and `timeline_events.csv`, extract normalized risky value.
8. Submit risky policy value.

## Key Indicators
- Policy pivot:
  - `"Principal": "*"`
  - `principal=*`
- CloudTrail pivot:
  - `"eventName":"PutBucketPolicy"`
  - `"principal":"*"`
- Simulation/access pivot:
  - `principal=* ... decision=allow`
  - `policy_principal=*`
- Audit/alert/SIEM pivot:
  - `risky_policy_value=*`
  - `risky_policy_value_identified ... *`

## Suggested Commands / Tools
- `rg "principal=\\*|\"Principal\": \"\\*\"|risky_policy_value|PutBucketPolicy|policy_principal=\\*" evidence`
- Review:
  - `evidence/cloud/bucket_policy.json`
  - `evidence/cloud/bucket_policy_versions.log`
  - `evidence/cloud/policy_simulation.csv`
  - `evidence/cloud/cloudtrail_events.jsonl`
  - `evidence/cloud/object_access.log`
  - `evidence/cloud/policy_audit.log`
  - `evidence/security/storage_policy_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
