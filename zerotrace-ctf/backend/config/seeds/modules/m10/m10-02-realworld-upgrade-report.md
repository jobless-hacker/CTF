# M10-02 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Archive triage and hidden/overlooked file discovery.
- Task target: identify hidden file inside recovered archive.

### Learning Outcome
- Correlate ZIP listing scans, content indexing, and hash telemetry.
- Detect overlooked entries in noisy archive triage pipelines.
- Confirm findings with SIEM normalized investigation events.

### Previous Artifact Weaknesses
- Small archive with obvious answer.
- No realistic forensic processing context.
- No large noisy supporting evidence.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Recovered-archive inventory exports from DFIR workflows.
2. ZIP listing and archive-content indexing logs.
3. Hash catalog outputs for per-entry verification.
4. SIEM timeline confirmations for final hidden-file attribution.

### Key Signals Adopted
- Target archive: `archive.zip`.
- Hidden entry consistently identified as `secret.txt`.
- SIEM confirms hidden file discovery event.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `archive.zip` enriched payload (70+ files) including target `secret.txt`.
- `recovered_archives_inventory.csv` (**6,802 lines**) inventory with target archive row.
- `zip_listing_scan.log` (**7,301 lines**) listing scan with hidden-entry event.
- `archive_contents_index.csv` (**5,602 lines**) indexed entries including target file.
- `hash_catalog.jsonl` (**5,201 lines**) hash records with critical target entry.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and hidden-file confirmation.
- `archive_manifest_preview.txt`, incident briefing, case notes, and intel snapshot.

Realism upgrades:
- High-volume archive-triage telemetry across multiple subsystems.
- Requires cross-source entry-name correlation before submission.
- Mirrors practical DFIR archive investigations.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-6002`).
2. Pivot on `archive.zip` in inventory/listing/index records.
3. Confirm hidden entry name via hash catalog and SIEM events.
4. Submit hidden filename.

Expected answer:
- `CTF{secret.txt}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m10/m10-02-hidden-archive.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `archive.zip`, `secret.txt`, `overlooked_entry`, `hidden_file_confirmed`.
- Validate with at least two forensic sources plus SIEM confirmation.
