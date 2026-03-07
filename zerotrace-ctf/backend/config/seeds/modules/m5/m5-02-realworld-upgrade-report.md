# M5-02 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- SSH intrusion investigation focused on identifying the malicious external source IP.
- Task target: isolate attacker IP behind suspicious successful root authentication.

### Learning Outcome
- Correlate Linux `auth.log` activity with SIEM and identity alerts.
- Distinguish normal internal SSH usage from suspicious external root access.
- Use supporting sources (VPN mapping and GeoIP context) to validate attacker origin.

### Previous Artifact Weaknesses
- Minimal artifact with direct answer visibility.
- No realistic multi-source correlation path.
- Insufficient noise compared to actual SOC authentication investigations.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Linux SSH triage workflow (`auth.log` + failed/success correlation).
2. SOC incident handling model (alert -> timeline -> source validation).
3. VPN correlation checks to separate approved remote access from direct internet access.
4. NIST-style incident evidence correlation process for attribution.

### Key Signals Adopted
- Cluster of failed root attempts followed by successful root login from one external IP.
- Critical alert object with suspicious source IP field.
- SIEM event sequence showing escalation from failures to compromise suspicion.
- VPN correlation showing no approved tunnel mapping for attacker IP.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `auth.log` (**8,941 lines**) high-noise SSH telemetry with suspicious pivot events.
- `ssh_attempt_summary.csv` (**6,602 lines**) aggregated source/account behavior.
- `vpn_gateway.log` (**5,301 lines**) approved VPN session telemetry + no-mapping alert.
- `geoip_reference.csv` (**4,202 lines**) enrichment context for source attribution.
- `identity_alerts.jsonl` (**4,301 lines**) alert stream with one critical `external_root_login`.
- `timeline_events.csv` (**5,104 lines**) SIEM chronology including incident opening.
- `remote_access_policy.txt` and `ssh_intrusion_triage_runbook.txt` for operational context.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source SOC evidence chain with large noisy datasets.
- Realistic authentication attack progression (failed attempts -> successful access).
- Actionable pivots consistent with production Linux incident investigations.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5502`, host `lin-app-02`).
2. Pivot in `auth.log` to locate suspicious successful external root login.
3. Confirm same IP in critical `identity_alerts.jsonl`.
4. Validate SIEM escalation events in `timeline_events.csv`.
5. Use VPN mapping evidence to confirm direct external origin.
6. Submit attacker source IP.

Expected answer:
- `CTF{203.0.113.7}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m5/m5-02-ssh-login-trail.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `Accepted password for root`, `203.0.113.7`, `external_root_login`.
- CSV review for `ssh_attempt_summary.csv` and `timeline_events.csv`.
- JSONL filtering for critical identity alerts and suspicious IP field.
