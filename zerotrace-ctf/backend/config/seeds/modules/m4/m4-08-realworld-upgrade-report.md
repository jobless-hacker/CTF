# M4-08 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- DNS availability incident caused by resolver service failure.
- Task target: identify failed DNS service name.

### Learning Outcome
- Correlate resolver logs, service manager state, and probe outcomes.
- Distinguish transient DNS errors from complete service outage.
- Derive failed-service identity from multi-source operational telemetry.

### Previous Artifact Weaknesses
- Minimal artifact with direct answer visibility.
- Missing realistic resolver, probe, and SIEM context.
- Limited noise and weak investigation depth.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NIST SP 800-61 incident correlation workflow:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
2. DNS outage troubleshooting patterns (named logs + dig probes + service status).
3. SRE/NOC triage model for resolver failures and SERVFAIL spikes.
4. SOC evidence fusion from alerts, packet summaries, and SIEM.

### Key Signals Adopted
- Named logs include `service bind9 stopped`.
- Systemctl shows `bind9.service -> Active: failed`.
- Dig probes show widespread `SERVFAIL` and zero response latency.
- Alerts/SIEM identify failed service as `bind9`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `named.log` (**9,603 lines**) resolver daemon log stream with outage pivot.
- `resolver_timeseries.csv` (**8,603 lines**) DNS result/latency distribution.
- `systemctl_snapshot.log` (**6,803 lines**) service-state snapshots.
- `dig_probe_results.csv` (**6,403 lines**) resolver probe outcomes.
- `dns_packet_summary.csv` (**7,003 lines**) DNS traffic/rcode telemetry.
- `dns_alerts.jsonl` (**4,301 lines**) alert feed with failed service marker.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression.
- `named.conf` (**6 lines**) resolver config context.
- `dns_outage_runbook.txt` (**5 lines**) operational triage guidance.
- Briefing files.

Realism upgrades:
- End-to-end outage path from resolver daemon failure to ecosystem impact.
- Multi-source noisy telemetry requiring deliberate pivots.
- Operationally realistic DNS diagnostics and incident chronology.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and resolver host/window.
2. Confirm daemon/service failure in named and systemctl logs.
3. Validate SERVFAIL surge in probes/traffic summaries.
4. Correlate alerts and SIEM service-failed classification.
5. Submit exact DNS service name.

Expected answer:
- `CTF{bind9}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m4/m4-08-dns-outage.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `bind9`, `service bind9 stopped`, `Active: failed`, `SERVFAIL`.
- CSV analysis for resolver/probe/packet anomaly windows.
- JSONL filtering for critical DNS service-down alert.
