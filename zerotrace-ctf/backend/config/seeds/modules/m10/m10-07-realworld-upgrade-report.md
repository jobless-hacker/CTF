# M10-07 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Filesystem deletion-trace investigation and sensitive-file attribution.
- Task target: identify the deleted sensitive filename from incident cleanup telemetry.

### Learning Outcome
- Correlate deletion journal, audit logs, recovery records, and SIEM evidence.
- Isolate high-signal deleted artifact from large noisy filesystem events.
- Validate final answer via multi-source consistency.

### Previous Artifact Weaknesses
- Minimal two-line clue path with obvious answer.
- No realistic filesystem telemetry context.
- No noise, false positives, or cross-source verification.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Deletion journal exports from filesystem monitoring pipelines.
2. Filesystem unlink audit logs from host telemetry.
3. Recovery-catalog records from DFIR recovery tooling.
4. SIEM timeline confirmation for high-confidence deleted artifact verdicts.

### Key Signals Adopted
- Target deleted file: `credentials.txt`.
- Cross-source pivots: filesystem log, fs audit normalized field, recovery candidate, and SIEM confirmation.
- Final event pivot: `sensitive_deleted_file_confirmed`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `filesystem.log` baseline deleted-file trace.
- `deletion_journal.csv` (**6,802 lines**) high-volume deletion events with target row.
- `fs_audit.log` (**7,301 lines**) unlink telemetry with normalized deleted-file field.
- `recovery_catalog.jsonl` (**5,601 lines**) recovery evidence and confidence records.
- `index_correlation.csv` (**5,202 lines**) correlation telemetry linking deleted artifact.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and final sensitive-file confirmation.
- Incident briefing, analyst handoff, deleted-files preview, case notes, and intel snapshot.

Realism upgrades:
- Large noisy datasets reflecting production filesystem telemetry.
- Requires multi-source validation before submission.
- Mirrors practical DFIR deleted-artifact investigation.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-6007`) and baseline filesystem trace.
2. Pivot on deleted-file candidates across journal/audit/recovery/correlation datasets.
3. Confirm final sensitive deleted file using SIEM `sensitive_deleted_file_confirmed`.
4. Submit normalized filename.

Expected answer:
- `CTF{credentials.txt}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m10/m10-07-deleted-file-trace.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `credentials.txt`, `normalized_deleted_file`, `sensitive_deleted_file_confirmed`, `ctf_answer_ready`.
- Validate with at least two forensic sources plus SIEM confirmation.
