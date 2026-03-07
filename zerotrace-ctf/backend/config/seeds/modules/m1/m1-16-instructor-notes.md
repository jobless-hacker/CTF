# M1-16 Instructor Notes

## Objective
- Train learners to investigate API response overexposure in a realistic production telemetry set.
- Expected answer: `CTF{confidentiality}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - endpoint: `/v1/profile/summary`
   - key window: around `2026-03-06T08:42Z`
2. Find suspicious requests in `gateway_access.log`:
   - `req-778411`, `req-778412`, `req-778413`
3. Pivot to `service_response_samples.jsonl` and confirm public endpoint payload contains restricted fields:
   - `password_hash`
   - `mfa_recovery_codes`
   - `ssn_last4`
4. Validate auth context in `token_introspection.jsonl`:
   - token `tk_442188`
   - scope `profile:read`
   - role `customer`
5. Check policy behavior in `authorization_decisions.csv`:
   - `allow` due legacy serializer compatibility path
6. Confirm privacy detection in `privacy_dlp_findings.csv` (critical/open).
7. Correlate `release_change_log.csv`:
   - temporary compatibility flag enabling debug serializer
   - rollback after alert
8. Use schema files to separate expected internal sensitive route from public route.
9. Classify CIA impact.

## Key Indicators
- Request IDs: `req-778411`, `req-778412`, `req-778413`
- Leaked fields: `password_hash`, `ssn_last4`
- Scope mismatch: public route + `profile:read` token
- Release signal: `PROFILE_SERIALIZER_COMPAT=1` enabled before incident

## Suggested Commands / Tools
- `rg "req-778411|req-778412|req-778413|password_hash|ssn_last4" evidence`
- Filter CSV by request ID and time in:
  - `authorization_decisions.csv`
  - `privacy_dlp_findings.csv`
  - `release_change_log.csv`
- `jq` for:
  - `service_response_samples.jsonl`
  - `token_introspection.jsonl`
  - `waf_alerts.jsonl`
