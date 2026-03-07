# M1-14 Instructor Notes

## Objective
- Train learners to investigate Docker/network drift that made a staging database externally reachable.
- Expected answer: `CTF{confidentiality}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` to capture scope:
   - host: `staging-db.company.local` (`198.51.100.40`)
   - service: `3306/tcp`
2. Compare compose files and diff:
   - `docker-compose.baseline.yml`
   - `docker-compose.current.yml`
   - `compose_diff.patch`
3. Validate runtime behavior in `docker_events.log`:
   - DB service published as `0.0.0.0:3306->3306/tcp`
4. Validate host socket state in `ss_listening_timeseries.csv`:
   - unexpected `LISTEN` on `0.0.0.0:3306`
5. Confirm internet reachability in `external_scan_results.csv`.
6. Correlate external attempts in `flow_telemetry.csv`.
7. Verify controls/change context:
   - `governance_findings.csv` critical open finding
   - `change_log.csv` only draft/no approved DB exposure change
8. Classify CIA impact.

## Key Indicators
- Compose drift: `127.0.0.1:3306:3306` -> `3306:3306`
- Runtime publish: `0.0.0.0:3306->3306/tcp`
- External scan classification: `unexpected-exposure`
- Governance finding severity: `93`
- Change ticket `CHG-10777` status: `draft`

## Suggested Commands / Tools
- `rg "3306|0.0.0.0|publish|unexpected-exposure|CHG-10777" evidence`
- Diff inspection for compose baseline/current files.
- CSV filtering by incident window (`2026-03-06T09:42Z`) across:
  - `ss_listening_timeseries.csv`
  - `external_scan_results.csv`
  - `flow_telemetry.csv`
  - `governance_findings.csv`
