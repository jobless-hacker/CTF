# M1-01 Instructor Notes

## Objective
- Train students to classify CIA impact from realistic cloud telemetry.
- Expected answer: `CTF{confidentiality}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and define incident window.
2. Check `bucket_policy_before.json` vs `bucket_policy_after.json`.
3. Confirm `public_access_block_diff.json` indicates relaxed controls.
4. Validate `aws_config_rule_evaluations.json` shows NON_COMPLIANT for target bucket.
5. Validate `security_hub_finding.json` and `access_analyzer_finding.json`.
6. Pivot into `cloudtrail_events.jsonl` for policy-change actor/IP/time.
7. Verify data-plane impact in `s3_server_access.log`:
   - successful (`200`) object reads
   - external IP
   - anonymous requester (`-`)
   - restricted object keys from inventory

## Key Indicators
- Public read principal (`"*"`).
- Control drift in Public Access Block settings.
- External source IP reads of restricted datasets.
- Temporal sequence: policy change -> compliance alert -> object access burst.

## Recommended Tools
- `rg "PutBucketPolicy|NON_COMPLIANT|AWS:Anonymous|185.199.110.42"`
- `jq -r '.eventTime + " " + .eventName + " " + .sourceIPAddress' cloudtrail_events.jsonl`
- `rg "patients/|finance/" s3_server_access.log`
- Optional SIEM simulation:
  - import JSONL to Splunk/Elastic
  - filter by eventName and sourceIPAddress

