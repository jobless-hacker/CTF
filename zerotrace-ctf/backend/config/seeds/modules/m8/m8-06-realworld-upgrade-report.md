# M8-06 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Suspicious cloud console login from an external source observed in CloudTrail.
- Task target: identify suspicious source IP address.

### Learning Outcome
- Investigate cloud authentication anomalies across audit, enrichment, and detection pipelines.
- Correlate login telemetry with MFA policy and threat findings.
- Extract normalized suspicious source IP for incident handling.

### Previous Artifact Weaknesses
- Single CloudTrail JSON made answer immediate.
- No realistic cross-source SOC/CloudSec investigation path.
- Missing context for MFA, GeoIP, and detection correlation.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. High-volume CloudTrail login and control-plane event streams.
2. Console login audit records with MFA and risk markers.
3. GeoIP and GuardDuty findings for suspicious external source confirmation.
4. MFA policy audit and SIEM timeline normalization.

### Key Signals Adopted
- Successful console login from `185.22.33.41`.
- Same IP appears in CloudTrail, login audit, GeoIP enrichment, and GuardDuty.
- MFA policy violation and SIEM confirm suspicious source IP as `185.22.33.41`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `cloudtrail_events.jsonl` (**7,101 lines**) noisy baseline plus suspicious login event.
- `console_login_audit.log` (**5,601 lines**) login audit stream with critical anomalous login.
- `geoip_enrichment.csv` (**5,202 lines**) enrichment baseline and one suspicious external source.
- `guardduty_findings.jsonl` (**4,301 lines**) findings stream with active suspicious login detection.
- `mfa_policy_audit.log` (**5,101 lines**) MFA policy baseline and one violation.
- `timeline_events.csv` (**5,004 lines**) SIEM correlation and suspicious IP identification.
- `cloudtrail.json` direct event artifact.
- `cloud_console_access_monitoring_policy.txt` and `suspicious_cloudtrail_event_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-noise cloud telemetry requiring pivoted investigation.
- Multi-source correlation across auth, enrichment, and detection systems.
- Includes operational incident-response context.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5806`).
2. Identify suspicious source in CloudTrail and console login logs.
3. Validate external risk via GeoIP and GuardDuty findings.
4. Confirm MFA violation and SIEM normalized suspicious IP output.
5. Submit suspicious source IP.

Expected answer:
- `CTF{185.22.33.41}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m8/m8-06-suspicious-cloudtrail-event.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `185.22.33.41`, `ConsoleLogin`, `MFAUsed`, `source_ip`, `suspicious_ip_identified`.
- Correlate cloudtrail/login/geoip/guardduty/policy evidence prior to submission.
