# M4-05 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Availability outage caused by database connection exhaustion.
- Task target: identify underlying root problem.

### Learning Outcome
- Correlate DB engine logs, pool pressure, and app failures.
- Differentiate query latency issues from hard connection exhaustion.
- Identify root classification from multi-source telemetry.

### Previous Artifact Weaknesses
- Small direct artifact with immediate answer visibility.
- No realistic database + application + SIEM correlation.
- Limited noise and weak investigation depth.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NIST SP 800-61 incident analysis methodology:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
2. PostgreSQL operational patterns for client exhaustion (`too many clients already`).
3. SRE/DBA outage triage workflow: max_connections + pool waiters + reject rates.
4. SOC correlation across DB logs, app error logs, and SIEM alerts.

### Key Signals Adopted
- PostgreSQL fatal log: `too many clients already`.
- Connection timeseries pinned at `max_connections = 300` with rejects.
- Pool metrics show waiting client surge and timeout ceiling.
- Alert/SIEM classification states `connection_limit`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `postgres.log` (**9,203 lines**) database engine connection and fatal events.
- `db_connection_timeseries.csv` (**8,803 lines**) total/active/idle/reject metrics.
- `pool_stats.csv` (**7,003 lines**) application pool saturation metrics.
- `app_db_error.log` (**5,402 lines**) application-side DB error telemetry.
- `slow_query_summary.csv` (**6,202 lines**) query profile context/noise.
- `db_alerts.jsonl` (**4,301 lines**) alert stream with critical root_problem field.
- `timeline_events.csv` (**5,005 lines**) SIEM progression and root classification.
- `postgresql.conf` (**6 lines**) max connection configuration context.
- `db_outage_runbook.txt` (**5 lines**) operational decision guidance.
- Briefing files.

Realism upgrades:
- End-to-end outage chain across DB, app, and SOC tooling.
- High-noise evidence with clear pivots for root cause.
- Practical investigation path matching DBA/SRE workflows.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident brief for host/time context.
2. Confirm fatal DB connection exhaustion in postgres logs.
3. Validate metrics hitting max connections with rejects.
4. Correlate pool waiters and app connection failures.
5. Confirm alert/SIEM root-problem classification and submit.

Expected answer:
- `CTF{connection_limit}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m4/m4-05-database-overload.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `too many clients already`, `connection limit exceeded`, `connection_limit`, `max_connections = 300`.
- CSV analysis for connection saturation and pool waiting clients.
- JSONL filtering for critical DB exhaustion alerts.
