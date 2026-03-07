# M8-05 Instructor Notes

## Objective
- Train learners to investigate exposed production API key incidents across cloud/dev/CI evidence.
- Expected answer: `CTF{pk_live_9a82d2}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5805`
   - service: `billing-gateway`
2. In `app_config_history.log`, identify plaintext key violation entry.
3. In `api_config.txt`, confirm explicit `PAYMENT_API_KEY` value.
4. In `repo_scan.log`, verify leaked key found by repository scan.
5. In `pipeline_audit.log`, confirm deployment pipeline propagated leaked key.
6. In `payment_api_usage.log`, validate suspicious runtime usage tied to leaked key.
7. In `api_key_exposure_alerts.jsonl` and `timeline_events.csv`, extract normalized leaked key value.
8. Submit leaked API key value.

## Key Indicators
- Config pivot:
  - `PAYMENT_API_KEY=pk_live_9a82d2`
- Repo pivot:
  - `result=failed ... detected_key_value=pk_live_9a82d2`
- CI pivot:
  - `leaked_api_key=pk_live_9a82d2`
- Runtime pivot:
  - `api_key=pk_live_9a82d2`
- Alert/SIEM pivot:
  - `"leaked_api_key":"pk_live_9a82d2"`
  - `leaked_api_key_identified ... pk_live_9a82d2`

## Suggested Commands / Tools
- `rg "PAYMENT_API_KEY|pk_live_9a82d2|result=failed|leaked_api_key|leaked_api_key_identified" evidence`
- Review:
  - `evidence/cloud/app_config_history.log`
  - `evidence/cloud/api_config.txt`
  - `evidence/dev/repo_scan.log`
  - `evidence/ci/pipeline_audit.log`
  - `evidence/cloud/payment_api_usage.log`
  - `evidence/security/api_key_exposure_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
