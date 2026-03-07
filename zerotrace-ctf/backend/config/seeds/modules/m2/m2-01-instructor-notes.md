# M2-01 Instructor Notes

## Objective
- Train learners to perform SOC-style after-hours access triage across multiple evidence sources.
- Expected answer: `CTF{45.83.22.91}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - host: `prod-app-01`
   - user: `admin`
   - window: around `2026-03-06T02:12Z`
2. In `sshd_auth.log`, find successful off-hours logins for `admin`.
3. Pivot source IP into `bastion_sessions.csv`:
   - same source appears with `mfa=not_configured`
4. Pivot source IP into `vpn_sessions.csv`:
   - repeated `connection_denied` for same source
5. Validate external context in `geoip_context.csv`.
6. Confirm detection sequence in `timeline_events.csv`.
7. Validate against `prod_ssh_access_policy.txt` and conclude suspicious IP.

## Key Indicators
- SSH success source: `45.83.22.91`
- Bastion control anomaly: no MFA configured
- VPN mismatch: denied on corp VPN path
- Enrichment: `unexpected-external` classification

## Suggested Commands / Tools
- `rg "45.83.22.91|ssh_login_after_hours|connection_denied|not_configured" evidence`
- CSV filtering in:
  - `bastion_sessions.csv`
  - `vpn_sessions.csv`
  - `timeline_events.csv`
- Manual policy check in `prod_ssh_access_policy.txt`.
