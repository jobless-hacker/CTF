# M1-10 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Backup integrity failure causing unsuccessful recovery after primary storage loss.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate backup metadata, checksum validation, storage logs, and restore workflow output.
- Distinguish noisy backup warnings from fatal corruption in the required recovery archive.
- Connect failed restore to direct service unavailability impact.

### Previous Artifact Weaknesses
- Minimal evidence and short answer path.
- Limited operational background noise.
- Weak linkage between corruption evidence and service-level impact.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. PostgreSQL backup verification utility (`pg_verifybackup`):  
   https://www.postgresql.org/docs/current/app-pgverifybackup.html
2. Borg repository consistency checks (`borg check`):  
   https://borgbackup.readthedocs.io/en/stable/usage/check.html
3. Restic repository integrity checking (`check` workflow):  
   https://restic.readthedocs.io/en/stable/045_working_with_repos.html
4. GNU tar archive behavior and extraction context:  
   https://www.gnu.org/software/tar/manual/
5. GNU Coreutils checksum utilities (SHA-2 digest validation):  
   https://www.gnu.org/software/coreutils/manual/html_node/sha2-utilities.html
6. AWS Backup restore testing best practices (recovery assurance):  
   https://docs.aws.amazon.com/aws-backup/latest/devguide/restore-testing.html

### Key Signals Adopted
- Manifest expected checksum vs observed restore checksum mismatch.
- Restore controller fatal extraction error (`Unexpected EOF in archive`).
- Object-storage upload anomaly around incident backup object.
- Service probes and status logs showing prolonged unavailability after restore failure.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `backup_catalog.csv` (**5,403 lines**) noisy historical backup metadata.
- `backup_manifest_records.jsonl` (**4,201 lines**) archive manifest records.
- `object_storage_audit.csv` (**6,205 lines**) storage write/completion telemetry.
- `restore_controller.log` (**9,806 lines**) restore workflow and fatal incident sequence.
- `checksum_validation.csv` (**7,602 lines**) high-volume integrity results.
- `service_recovery_status.csv` (**2,601 lines**) recovery state transitions.
- `uptime_probes.csv` (**3,401 lines**) external impact telemetry.
- `normalized_events.csv` (**6,404 lines**) SIEM stream with noise + critical failures.
- Incident ticket, analyst handoff, and DR runbook excerpt.

Realism upgrades:
- Multi-source backup + storage + service evidence.
- High-volume logs with benign false-positive warnings.
- Clear but non-trivial path from corruption -> failed restore -> downtime.
- Practical recovery investigation flow for SOC/SRE/DR teams.

## Step 4 - Flag Engineering

Expected investigation path:
1. Identify the incident backup (`BK-126004`) and expected digest.
2. Confirm mismatch + extraction failure in checksum and restore logs.
3. Correlate object-storage anomaly for the same archive.
4. Confirm service recovery failed and uptime checks degraded/time out.
5. Classify primary CIA impact.

Expected flag:
- `CTF{availability}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-10-backup-corruption.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for backup ID and checksum pivots.
- CSV filtering for validation/status/probe timeline correlation.
- `jq` for manifest JSONL inspection.
- Timeline stitching from storage event -> restore failure -> service outage.
