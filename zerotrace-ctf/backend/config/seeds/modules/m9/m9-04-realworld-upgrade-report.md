# M9-04 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Document metadata analysis and author attribution in OSINT/DFIR workflows.
- Task target: identify author of leaked target document.

### Learning Outcome
- Correlate metadata evidence across extraction, parsing, and SIEM normalization.
- Distinguish target document signals from high-volume processing noise.
- Confirm author attribution using at least two independent sources.

### Previous Artifact Weaknesses
- Single artifact disclosed author directly.
- No realistic enterprise document-processing noise.
- No validation path through operational telemetry.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Document inventory exports from content-index pipelines.
2. PDF metadata extraction logs from automated tools.
3. Parser-normalized JSON output for metadata fields.
4. DLP audit logs and SIEM timelines for attribution confirmation.

### Key Signals Adopted
- Target file: `report.pdf`.
- Metadata sources resolve author as `John Carter`.
- SIEM timeline confirms final author attribution event.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `document_inventory.csv` (**6,702 lines**) enterprise inventory noise with target entry.
- `pdf_metadata_extract.log` (**7,201 lines**) extraction noise plus target author line.
- `doc_parser_output.jsonl` (**5,401 lines**) parser output with high-risk target record.
- `dlp_audit.log` (**5,601 lines**) DLP telemetry with target author verification event.
- `timeline_events.csv` (**5,103 lines**) SIEM normalization and answer-ready event.
- `report.pdf` evidence file with embedded metadata clue.
- Incident briefing, case notes, and intel snapshot.

Realism upgrades:
- High-noise cross-source evidence similar to SOC document triage pipelines.
- Requires pivoting by file name and author field.
- Final confirmation path matches real analyst workflow.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-5904`) and target file (`report.pdf`).
2. Pivot on `report.pdf` across inventory, metadata extract, parser, and DLP logs.
3. Confirm author in SIEM timeline/intel notes.
4. Submit normalized answer format.

Expected answer:
- `CTF{John_Carter}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m9/m9-04-document-metadata.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `report.pdf`, `John Carter`, `document_author_confirmed`, `author=`.
- Validate author evidence in both parser/metadata logs and SIEM events.
