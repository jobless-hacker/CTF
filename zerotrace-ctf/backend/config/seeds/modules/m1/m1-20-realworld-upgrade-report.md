# M1-20 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- DNS amplification-driven traffic surge degrading resolver service reliability.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate DNS query patterns with network-flow amplification signals.
- Validate operational impact via resolver SLI/SLO and external probe failures.
- Distinguish attack-driven degradation from planned changes or routine spikes.

### Previous Artifact Weaknesses
- Minimal logs with low investigative depth.
- Limited traffic noise and weak causality chain.
- Insufficient evidence linking surge to service unavailability.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. CISA guidance on DDoS and volumetric attack response:  
   https://www.cisa.gov/resources-tools/services/ddos-guidance
2. RFC 5358 (Preventing use of DNS for amplification attacks):  
   https://www.rfc-editor.org/rfc/rfc5358
3. BIND DNS operational logging references:  
   https://bind9.readthedocs.io/
4. NetFlow/IPFIX flow telemetry concepts for incident triage:  
   https://www.rfc-editor.org/rfc/rfc7011
5. NIST SP 800-61 incident handling lifecycle:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final

### Key Signals Adopted
- `ANY` query bursts with high response payload sizes.
- Amplification-classified inbound UDP/53 netflows.
- Critical firewall alert `DNS_AMP_FLOOD_DETECTED`.
- Resolver health collapse: high QPS, SERVFAIL/timeouts, packet drops.
- External probe failures (timeouts) aligned to surge window.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `resolver_query.log` (**12,223 lines**) high-volume DNS query events with attack burst.
- `dns_netflow.csv` (**9,581 lines**) flow telemetry including amplification-class flows.
- `firewall_alerts.jsonl` (**4,301 lines**) noisy edge alerts plus critical detection.
- `resolver_health_timeseries.csv` (**5,605 lines**) service-level degradation metrics.
- `service_probes.csv` (**5,105 lines**) user-facing availability checks.
- `change_records.csv` (**1,902 lines**) operational-change context.
- Briefing files for incident workflow.

Realism upgrades:
- Multi-source DNS, network, and service health evidence.
- Baseline noise and false positives before incident onset.
- Clear timeline from traffic anomaly to resolver outage.
- Change control context to avoid false attribution.

## Step 4 - Flag Engineering

Expected investigation path:
1. Start from incident ticket and lock incident window (`09:44Z`).
2. Confirm amplification query pattern (`qtype=ANY`, large responses).
3. Correlate with netflow amplification-class inbound UDP/53 bursts.
4. Validate firewall critical alert for amplification flood.
5. Confirm resolver/probe availability degradation during same window.
6. Check change records for absence of approved disruptive changes.
7. Classify primary CIA impact.

Expected flag:
- `CTF{availability}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-20-dns-amplification-attack.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for `ANY`, amplification, and source-IP pivots.
- CSV filtering for QPS, SERVFAIL, probe failures, and flow classes.
- `jq` for firewall JSONL triage.
- Single timeline reconstruction around `2026-03-06T09:44Z`.
