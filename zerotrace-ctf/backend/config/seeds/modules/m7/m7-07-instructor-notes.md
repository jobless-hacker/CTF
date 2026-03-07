# M7-07 Instructor Notes

## Objective
- Train learners to investigate API response leakage and identify the exposed sensitive field.
- Expected answer: `CTF{password}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5707`
   - request id: `req-8807120`
2. In `gateway_access.log`, identify suspicious API request context.
3. In `response_samples.jsonl`, inspect response payload for restricted field.
4. In `schema_audit.log`, confirm field is not allow-listed.
5. In `openapi_snapshot.yaml` and `service_patch.diff`, validate intended schema excludes this field.
6. In `dlp_alerts.jsonl` and `timeline_events.csv`, use normalized detection label for final field name.
7. Submit exposed sensitive field.

## Key Indicators
- Request pivot:
  - `request_id=req-8807120`
- Endpoint pivot:
  - `/api/v2/admin/users/1442`
- Payload pivot:
  - `"password":"TempPass!2026"`
- Schema pivot:
  - `unexpected_field=password`
- Alert pivot:
  - `"type":"api_sensitive_field_exposure","sensitive_field":"password"`
- SIEM pivot:
  - `sensitive_field_identified ... password`

## Suggested Commands / Tools
- `rg "req-8807120|password|sensitive_field|unexpected_field|sensitive_field_identified" evidence`
- Review:
  - `evidence/api/gateway_access.log`
  - `evidence/api/response_samples.jsonl`
  - `evidence/api/schema_audit.log`
  - `evidence/dev/openapi_snapshot.yaml`
  - `evidence/dev/service_patch.diff`
  - `evidence/security/dlp_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
