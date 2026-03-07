# M8-01 Instructor Notes

## Objective
- Train learners to investigate a public cloud bucket exposure and identify the sensitive payroll file.
- Expected answer: `CTF{payroll.xlsx}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5801`
   - bucket: `corp-analytics-prod`
2. In `bucket_listing_snapshot.txt`, identify candidate sensitive object.
3. In `bucket_object_inventory.log`, confirm object classification as restricted.
4. In `object_access.log` and `cloudtrail_events.jsonl`, validate anonymous/public retrieval.
5. In `bucket_policy_audit.log`, confirm public-read policy violation for object.
6. In `storage_exposure_alerts.jsonl` and `timeline_events.csv`, extract normalized exposed object name.
7. Submit exposed sensitive payroll filename.

## Key Indicators
- Listing pivot:
  - `payroll.xlsx`
- Inventory pivot:
  - `object=payroll.xlsx ... classification=restricted_data`
- Access pivot:
  - `auth=anonymous ... object=payroll.xlsx`
- CloudTrail pivot:
  - `"type":"Anonymous"` with `"key":"payroll.xlsx"`
- Policy pivot:
  - `status=violation principal=* action=s3:GetObject scope=payroll.xlsx`
- Alert/SIEM pivot:
  - `"exposed_object":"payroll.xlsx"`
  - `exposed_sensitive_file_identified ... payroll.xlsx`

## Suggested Commands / Tools
- `rg "payroll.xlsx|anonymous|principal=\\*|exposed_object|exposed_sensitive_file_identified" evidence`
- Review:
  - `evidence/cloud/bucket_listing_snapshot.txt`
  - `evidence/cloud/bucket_object_inventory.log`
  - `evidence/cloud/object_access.log`
  - `evidence/cloud/cloudtrail_events.jsonl`
  - `evidence/cloud/bucket_policy_audit.log`
  - `evidence/security/storage_exposure_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
