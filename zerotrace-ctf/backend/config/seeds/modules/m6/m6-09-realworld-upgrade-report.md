# M6-09 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Infected host identification from ARP/L2 anomaly signals.
- Task target: identify compromised device IP.

### Learning Outcome
- Detect compromise indicators in noisy ARP and MAC behavior telemetry.
- Correlate L2 sensor output with DHCP, endpoint, alerts, and SIEM data.
- Derive a single compromised-host IOC from multi-source evidence.

### Previous Artifact Weaknesses
- Single ARP log made answer extraction too direct.
- No realistic multi-source SOC triage path.
- Missing incident process artifacts and false-positive context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. ARP spoofing traces with forged gateway claims.
2. MAC conflict analytics for one IP mapped to multiple MAC addresses.
3. Endpoint process-level L2 anomaly behavior.
4. Alert pipeline + SIEM confirmation of compromised host identity.

### Key Signals Adopted
- Repeated forged ARP replies from `192.168.1.90`.
- Dual-MAC conflict pattern for same host.
- Critical alert and SIEM event confirm compromised host IP.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `arp.log` (**9,430 lines**) baseline ARP activity plus spoofing sequence.
- `mac_conflict_summary.csv` (**6,402 lines**) L2 analytics with conflict score outlier.
- `dhcp_leases.log` (**5,201 lines**) lease activity with suspicious renewal behavior.
- `l2_behavior.csv` (**5,602 lines**) endpoint L2 process behavior telemetry.
- `l2_alerts.jsonl` (**4,301 lines**) security alert stream with one critical host-compromise event.
- `timeline_events.csv` (**5,004 lines**) SIEM timeline confirming compromised host.
- `layer2_compromise_detection_policy.txt` and `infected_host_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Large noisy L2 dataset with operational false-positive style events.
- Multi-artifact pivot path needed to isolate true compromised host.
- SOC process context embedded through policy/runbook/incident files.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5609`, subnet `192.168.1.0/24`).
2. Identify spoofing behavior and forged gateway replies in ARP log.
3. Confirm MAC conflict outlier and endpoint anomaly row.
4. Validate compromised host in security alert and SIEM confirmation event.
5. Submit compromised host IP.

Expected answer:
- `CTF{192.168.1.90}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m6/m6-09-infected-host.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `192.168.1.90`, `arp_spoof_suspected`, `infected_host_detected`.
- Correlate ARP/MAC/DHCP/endpoint evidence before IOC submission.
- Use JSONL/SIEM pivots for final confirmation.
