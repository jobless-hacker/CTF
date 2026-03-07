# M6-10 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Internal lateral movement over SMB after initial compromise.
- Task target: identify attacked internal host IP.

### Learning Outcome
- Detect suspicious east-west SMB movement patterns in noisy enterprise telemetry.
- Correlate packet-level activity with flow, endpoint, Windows events, and SIEM.
- Determine lateral-movement target host from multi-source evidence.

### Previous Artifact Weaknesses
- Single compact SMB artifact made answer extraction straightforward.
- No realistic SOC correlation path across multiple telemetry sources.
- Missing policy/runbook/incident context for investigation realism.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. SMB auth/share failure bursts in packet exports.
2. East-west flow concentration from compromised source to one target.
3. Endpoint process-level SMB attempts and Windows security failures.
4. Alert and SIEM enrichment confirming attacked host.

### Key Signals Adopted
- Repeated SMB denied attempts from `192.168.1.90` to `192.168.1.12`.
- Cross-confirmation in flow, endpoint, Windows events, alerts, and SIEM.
- Final attacked-host IOC normalized as `192.168.1.12`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `smb_traffic.pcap` (**9,838 lines**) pseudo packet export with baseline SMB and suspicious burst.
- `east_west_flow.csv` (**6,237 lines**) flow-level source-target lateral movement pattern.
- `windows_security_events.log` (**5,601 lines**) endpoint auth/share event trail with suspicious failures.
- `smb_activity.csv` (**5,602 lines**) endpoint process SMB activity with anomaly row.
- `lateral_movement_alerts.jsonl` (**4,301 lines**) alert stream with critical detection event.
- `timeline_events.csv` (**5,004 lines**) SIEM timeline confirming attacked host.
- `internal_lateral_movement_detection_policy.txt` and `lateral_movement_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- High-volume noisy east-west traffic with one true-positive movement pattern.
- Multi-source correlation required to isolate the attacked host.
- Operational triage context included for SOC workflows.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5610`, source `192.168.1.90`).
2. Identify repeated denied SMB attempts in packet export.
3. Confirm source-target concentration in east-west flow + endpoint logs.
4. Validate target IOC using security alerts and SIEM host-identification event.
5. Submit attacked host IP.

Expected answer:
- `CTF{192.168.1.12}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m6/m6-10-lateral-movement.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `192.168.1.12`, `lateral_movement_detected`, `STATUS_LOGON_FAILURE`.
- Correlate SMB packet, flow, endpoint, and Windows security telemetry.
- Confirm target host from alert + SIEM enrichment.
