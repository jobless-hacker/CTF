# M7-04 Instructor Notes

## Objective
- Train learners to classify authentication failure caused by unsafe credential hygiene.
- Expected answer: `CTF{weak_password}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5704`
   - endpoint: `/login`
2. In `auth.log`, identify suspicious admin auth sequence from source IP with multiple failures then success.
3. In `login_debug.log`, confirm weak credential acceptance evidence.
4. In `password_policy_audit.txt`, verify weak legacy admin policy controls.
5. In `bruteforce_summary.csv`, `auth_alerts.jsonl`, and `timeline_events.csv`, confirm weakness classification.
6. Submit authentication weakness class.

## Key Indicators
- Auth pivot:
  - `user=admin ... result=login_success ... policy=legacy-admin`
- Debug pivot:
  - `username=admin password=admin validation=accepted`
- Policy pivot:
  - legacy admin policy disables complexity/dictionary checks
- Alert pivot:
  - `"type":"authentication_weakness_detected","weakness":"weak_password"`
- SIEM pivot:
  - `weakness_classified ... weak_password`

## Suggested Commands / Tools
- `rg "user=admin|password=admin|legacy-admin|weak_password|weakness_classified" evidence`
- Review:
  - `evidence/auth/auth.log`
  - `evidence/auth/login_debug.log`
  - `evidence/auth/password_policy_audit.txt`
  - `evidence/security/bruteforce_summary.csv`
  - `evidence/security/auth_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
