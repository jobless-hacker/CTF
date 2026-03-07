# M6-02 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- DNS beaconing detection via repeated high-frequency query behavior.
- Task target: identify suspicious beaconing domain.

### Learning Outcome
- Analyze repetitive timing patterns in DNS telemetry.
- Correlate DNS behavior with firewall and host-process context.
- Extract domain IOC from SOC-style detection and SIEM evidence.

### Previous Artifact Weaknesses
- Minimal single artifact with answer too visible.
- No cross-source correlation path.
- Limited realism for operational DNS investigations.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. DNS beaconing hunt workflows using interval-based pattern analysis.
2. Correlation between DNS resolver logs and firewall DNS egress.
3. Host-process attribution for suspicious DNS generation.
4. SIEM escalation patterns for repetitive-domain behavior.

### Key Signals Adopted
- Repeated ~1s interval queries from `192.168.1.45`.
- DNS summary scoring indicates high beacon score.
- Firewall notes tag high-frequency domain activity.
- Alerts and SIEM timeline normalize suspicious domain IOC.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `dns_query.log` (**9,305 lines**) high-noise query stream with beacon burst pivots.
- `dns_query_summary.csv` (**7,102 lines**) analytics summary with beacon score.
- `firewall_dns_egress.log` (**6,502 lines**) DNS egress logs and high-frequency notes.
- `process_dns_activity.csv` (**5,802 lines**) host-process correlation for suspicious domain.
- `dns_beacon_alerts.jsonl` (**4,301 lines**) alert stream with `suspicious_domain`.
- `timeline_events.csv` (**5,003 lines**) SIEM progression and incident opening.
- `dns_beaconing_detection_policy.txt` and `dns_beaconing_triage_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source DNS investigation path aligned with SOC practice.
- Significant baseline noise requiring focused pivots.
- IOC extraction requires correlation, not one-line lookup.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5602`, source `192.168.1.45`).
2. Find repeated domain in DNS query burst data.
3. Confirm domain in summary analytics and firewall notes.
4. Attribute querying process on host and validate alert/SIEM records.
5. Submit suspicious domain IOC.

Expected answer:
- `CTF{update-check.company.com}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m6/m6-02-dns-beaconing.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `update-check.company.com`, `beacon_score`, `suspicious_domain`.
- CSV/log review for DNS summary and host-process attribution.
- JSONL/SIEM filtering for critical beaconing events.
