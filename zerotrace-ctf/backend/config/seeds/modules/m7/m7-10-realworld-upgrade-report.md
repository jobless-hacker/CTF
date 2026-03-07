# M7-10 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Exposure of a sensitive backup archive through public web root access.
- Task target: identify the exposed backup file name.

### Learning Outcome
- Investigate backup exposure using web inventory, discovery, access, and config artifacts.
- Correlate noisy telemetry with one true exposed file indicator.
- Extract normalized backup filename from SOC detection outputs.

### Previous Artifact Weaknesses
- Single web-files list made answer trivial.
- No realistic multi-source incident workflow.
- Missing access/config/policy context expected in production investigations.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Web file inventory and directory snapshots exposing unexpected archive artifacts.
2. Discovery scans and access logs proving direct public reachability.
3. Configuration audit evidence showing missing deny rules.
4. Alert stream and SIEM timeline for normalized exposed backup filename.

### Key Signals Adopted
- File `/backup.zip` appears in inventory and autoindex outputs.
- Discovery scan and direct access both return HTTP `200` for `/backup.zip`.
- Security alerts and SIEM normalize exposed backup as `backup.zip`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `web_files_inventory.log` (**7,001 lines**) baseline public assets plus sensitive backup signal.
- `discovery_scan.csv` (**5,602 lines**) noisy scan data plus exposed archive path.
- `access.log` (**6,201 lines**) production access stream including direct backup download.
- `autoindex_snapshot.txt` directory listing style evidence with exposed backup.
- `web_config_audit.log` (**5,101 lines**) configuration baseline and deny-rule violation.
- `sensitive_backup_alerts.jsonl` (**4,301 lines**) noisy alerts with one critical exposure event.
- `timeline_events.csv` (**5,004 lines**) SIEM sequence confirming exposed backup filename.
- `backup_artifact_exposure_policy.txt` and `sensitive_backup_exposure_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-volume noisy logs requiring pivoting across multiple systems.
- Requires confirmation of both existence and public accessibility.
- Includes operational triage context used by SOC/AppSec teams.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5710`).
2. Pivot inventory and directory snapshot for suspicious backup artifact.
3. Confirm exposure via discovery scan and web access logs.
4. Validate config violation and alert/SIEM normalized backup filename.
5. Submit exposed backup file name.

Expected answer:
- `CTF{backup.zip}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m7/m7-10-sensitive-backup.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `/backup.zip`, `exposed_backup_file`, `exposed_backup_file_identified`, `status=violation`.
- Correlate inventory/scan/access/config/alert data to derive final answer.
