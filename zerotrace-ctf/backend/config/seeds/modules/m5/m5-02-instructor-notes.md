# M5-02 Instructor Notes

## Objective
- Train learners to investigate suspicious SSH activity and identify the attacker source IP.
- Expected answer: `CTF{203.0.113.7}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5502`
   - host: `lin-app-02`
2. In `auth.log`, locate repeated root failures and successful root login from external source.
3. In `identity_alerts.jsonl`, confirm critical alert with `suspicious_ip`.
4. In `timeline_events.csv`, confirm `external_root_login_success` event details.
5. In `vpn_gateway.log`, validate no approved VPN mapping for the same source.
6. Submit the external attacker IP.

## Key Indicators
- Failed/success sequence:
  - `Failed password for root from 203.0.113.7`
  - `Accepted password for root from 203.0.113.7`
- Alert pivot:
  - `"type":"external_root_login"`
  - `"suspicious_ip":"203.0.113.7"`
- SIEM pivot:
  - `external_root_login_success ... 203.0.113.7`
- VPN pivot:
  - `alert=no_vpn_mapping src_ip=203.0.113.7`

## Suggested Commands / Tools
- `rg "Accepted password for root|Failed password for root|203.0.113.7" evidence`
- `rg "external_root_login|suspicious_ip" evidence/security/identity_alerts.jsonl`
- Review:
  - `evidence/auth/ssh_attempt_summary.csv`
  - `evidence/siem/timeline_events.csv`
