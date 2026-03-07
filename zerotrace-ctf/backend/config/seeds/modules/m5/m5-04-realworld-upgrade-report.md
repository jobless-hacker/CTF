# M5-04 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Linux cron-based persistence and malicious scheduled task investigation.
- Task target: identify suspicious external domain used by recurring cron command.

### Learning Outcome
- Analyze persistence artifacts beyond a single crontab line.
- Correlate scheduled-task evidence with network telemetry and SOC alerts.
- Build an investigator workflow to extract actionable IOC (domain).

### Previous Artifact Weaknesses
- Single small artifact with direct answer visibility.
- No realistic SOC correlation across host and network evidence.
- Minimal noise and no operational context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Linux persistence triage for cron modifications and recurring execution.
2. SOC detection model linking cron changes to DNS/proxy egress.
3. SIEM timeline-based incident progression for persistence events.
4. Incident-runbook style validation for external script fetch behavior.

### Key Signals Adopted
- Unauthorized cron entry with `curl ... | bash` behavior.
- DNS lookup and proxy egress to same external domain at execution time.
- Critical persistence alert carrying domain IOC.
- SIEM correlation and incident open events.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `cron_job_inventory.csv` (**7,202 lines**) large scheduler inventory with suspicious cron job.
- `deploy_crontab_snapshot.txt` (**6,203 lines**) noisy crontab snapshot with malicious recurring command.
- `dns_query.log` (**6,502 lines**) resolver telemetry including suspicious domain lookups.
- `proxy_egress.log` (**6,101 lines**) outbound web requests confirming script fetch.
- `persistence_alerts.jsonl` (**4,201 lines**) alert stream with critical suspicious-domain event.
- `timeline_events.csv` (**5,204 lines**) SIEM event chain and incident handling milestones.
- `scheduled_task_security_policy.txt` and `cron_persistence_triage_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source persistence investigation path with operational noise.
- Time-correlated host and network signals.
- SOC-grade evidence for IOC extraction rather than immediate-answer artifact.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5504`, host `lin-app-03`).
2. Find suspicious cron command in snapshot/inventory artifacts.
3. Corroborate domain via DNS and proxy logs.
4. Validate same IOC in persistence alert JSON and SIEM timeline.
5. Submit suspicious domain.

Expected answer:
- `CTF{malicious-site.ru}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m5/m5-04-cron-persistence.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `malicious-site.ru`, `curl`, `cron`, `suspicious_domain`.
- CSV inspection for cron inventory and SIEM timeline.
- JSONL filter for critical persistence alerts.
