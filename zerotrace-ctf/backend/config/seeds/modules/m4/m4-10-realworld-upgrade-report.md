# M4-10 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Ransomware incident impact assessment mapped to CIA triad.
- Task target: identify primary impact category.

### Learning Outcome
- Correlate endpoint, storage, backup, and service telemetry during ransomware events.
- Distinguish impact evidence from attack indicators.
- Derive correct primary-impact classification from incident data.

### Previous Artifact Weaknesses
- Minimal artifact with direct answer visibility.
- No realistic IR evidence chain across multiple systems.
- Limited noise and insufficient operational context.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. NIST SP 800-61 incident handling/correlation guidance:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
2. Ransomware incident response patterns (encryption evidence + access disruption).
3. SOC/IR workflow: endpoint + file access + backup recovery + SIEM classification.
4. CIA mapping practice for business-impact assessment during outages.

### Key Signals Adopted
- Endpoint logs show encryption burst and ransom note drop.
- File access and service checks confirm users cannot access data.
- Backup restore attempts fail due to encrypted payload.
- Alert/SIEM/policy classify primary impact as `availability`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `endpoint_security.log` (**9,303 lines**) endpoint telemetry with ransomware pivots.
- `file_access_failures.csv` (**8,803 lines**) encrypted-file access failures.
- `backup_restore.log` (**6,202 lines**) recovery/restore operational evidence.
- `service_availability_checks.csv` (**6,803 lines**) downstream service impact.
- `ransom_note.txt` (**6 lines**) extortion note artifact.
- `edr_alerts.jsonl` (**4,301 lines**) EDR alerts with primary-impact field.
- `timeline_events.csv` (**5,005 lines**) SIEM progression and impact classification.
- `ransomware_response_policy.txt` (**5 lines**) CIA impact policy guidance.
- `ransomware_outage_runbook.txt` (**5 lines**) response playbook context.
- Briefing files.

Realism upgrades:
- Full ransomware outage workflow from compromise to business impact.
- High-noise data sources with concrete investigative pivots.
- Practical IR-oriented path to CIA impact decision.

## Step 4 - Flag Engineering

Expected investigation path:
1. Confirm ransomware evidence (ransom note + encryption activity).
2. Validate business impact through file/service inaccessibility.
3. Correlate failed backup recovery attempts.
4. Confirm alert/SIEM/policy impact classification.
5. Submit primary impact category.

Expected answer:
- `CTF{availability}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m4/m4-10-ransomware-lockdown.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `file_encrypted`, `primary_impact`, `users cannot access`, `availability`.
- CSV analysis for access failures and service-health impact windows.
- JSONL filtering for critical ransomware alerts.
