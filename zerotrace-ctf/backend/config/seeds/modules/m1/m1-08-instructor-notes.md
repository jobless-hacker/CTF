# M1-08 Instructor Notes

## Objective
- Train learners to investigate unauthorized config drift and resulting redirect behavior.
- Expected answer: `CTF{integrity}`.

## Expected Investigation Path
1. Start from `incident_ticket.txt` and define time window + key file.
2. Compare:
   - `server.conf.baseline`
   - `server.conf.current`
   - `server_conf_diff.patch`
3. Validate behavioral impact:
   - `nginx_access.log` (`loc="https://portal-company-login.com/login"`)
   - `synthetic_http_checks.csv` (`location_header` drift in incident window)
4. Pivot into host telemetry:
   - `audit_config_watch.log` writes to `/etc/portal/server.conf`
   - suspicious editor context (`vim`, service account mismatch)
5. Check governance/control context:
   - `change_tickets.csv` has no approved change for the modified redirect setting
6. Cross-check severity summary in `normalized_events.csv`.
7. Classify CIA impact.

## Key Indicators
- File changed: `/etc/portal/server.conf`
- Config drift:
  - `redirect=false` -> `redirect=true`
  - `target=` -> `target=portal-company-login.com`
- Runtime impact: external redirect on `/login` and `/dashboard`
- Audit pivot: file write events around `2026-03-06T10:41:54Z`
- Governance pivot: only draft ticket (`CHG-9722`), no approval

## Suggested Commands / Tools
- `rg "portal-company-login.com|redirect=true|target=" evidence`
- `rg "server.conf|vim|portal_config_watch|108241|108242" evidence/audit/audit_config_watch.log`
- CSV filter by `ticket_id`, `status`, `config_scope` in `change_tickets.csv`
- Timeline sort across logs to prove change -> reload -> redirect behavior.
