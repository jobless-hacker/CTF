# M5-06 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Hidden-file persistence detection on Linux endpoints.
- Task target: identify suspicious hidden filename associated with executable behavior.

### Learning Outcome
- Analyze hidden-file activity with file-inventory, metadata, and runtime signals.
- Correlate creation/permission/execution evidence from multiple telemetry sources.
- Produce a precise IOC answer from noisy DFIR data.

### Previous Artifact Weaknesses
- Single small listing made answer trivial.
- No realistic filesystem monitoring context.
- Missing SIEM/alert and runtime correlation.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Linux endpoint detection workflows for hidden persistence artifacts.
2. File-integrity monitoring pipelines (inventory + hash + event streams).
3. inotify-style runtime signal correlation for hidden file execution.
4. SIEM incident progression from detection to case opening.

### Key Signals Adopted
- Hidden file creation in user home path.
- Immediate permission hardening and executable launch.
- Hash catalog classification indicating suspicious ELF binary.
- Alert and SIEM markers naming suspicious hidden filename.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `home_inventory.csv` (**7,402 lines**) large home-directory file telemetry with hidden-file metadata.
- `recursive_ls_hidden_scan.txt` (**41,407 lines**) noisy recursive listing evidence.
- `file_hash_catalog.csv` (**6,102 lines**) file hash enrichment including suspicious ELF entry.
- `inotify_events.log` (**5,603 lines**) file operation telemetry with create/attrib/exec pivots.
- `hidden_file_alerts.jsonl` (**4,301 lines**) alert stream including critical suspicious hidden executable event.
- `timeline_events.csv` (**5,004 lines**) SIEM event chain and incident opening.
- `home_directory_monitoring_policy.txt` and `hidden_file_triage_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- High-noise, multi-source investigation path similar to SOC/DFIR workflows.
- Combines static file evidence with runtime execution telemetry.
- Clear pivot strategy without direct one-line answer leakage.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5506`, node `lin-hunt-02`).
2. Identify suspicious hidden entry in home inventory and recursive listing.
3. Correlate hash classification and inotify execution events.
4. Confirm alert/siem attribution to same hidden filename.
5. Submit suspicious hidden file name.

Expected answer:
- `CTF{.hidden_backdoor}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m5/m5-06-hidden-file.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `.hidden_backdoor`, `IN_EXEC`, `suspicious_file`.
- CSV and text inspection for inventory and listing scans.
- JSONL filtering for critical hidden-file alerts.
