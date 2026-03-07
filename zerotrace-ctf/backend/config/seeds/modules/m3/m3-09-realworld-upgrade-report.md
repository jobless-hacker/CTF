# M3-09 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Leaked archive triage for restricted strategic document exposure.
- Task target: identify the strategic document filename inside breach evidence.

### Learning Outcome
- Investigate archive leak incidents using forensic extraction, DLP, registry, and SIEM telemetry.
- Correlate leaked object contents with document classification and external access.
- Extract high-value exposed filename from noisy datasets.

### Previous Artifact Weaknesses
- Small static artifact with immediate answer visibility.
- No realistic breach triage chain or external access evidence.
- Missing noise, false positives, and multi-source correlation.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Data from Information Repositories / Exfiltration over Web Service:  
   https://attack.mitre.org/techniques/T1213/  
   https://attack.mitre.org/techniques/T1567/
2. NIST SP 800-61 incident evidence-correlation workflow:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. DFIR archive triage model: recovered archive -> extraction validation -> classification checks -> DLP/SIEM escalation.
4. DLP operational patterns for restricted-file leakage detection.

### Key Signals Adopted
- Recovered archive: `breach_archive.zip`.
- Nested archive contains `company_strategy.docx`.
- DLP critical alert references restricted strategic file.
- SIEM timeline confirms external download and incident opening.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `document_registry.csv` (**8,602 lines**) classification and ownership data.
- `breach_archive_manifest.txt` (**7,405 lines**) noisy archive manifest with strategic doc entry.
- `archive_extraction.log` (**6,104 lines**) forensic extraction telemetry.
- `public_download_logs.csv` (**5,602 lines**) storage access logs with external retrieval.
- `dlp_archive_alerts.jsonl` (**4,301 lines**) DLP alerts with critical signal.
- `timeline_events.csv` (**5,004 lines**) SIEM progression.
- `document_classification_policy.txt` (**5 lines**) governance baseline.
- `triage_notes.txt` (**8 lines**) analyst triage context.
- Nested `breach_archive.zip` containing:
  - `customer_list.xlsx`
  - `contracts.pdf`
  - `company_strategy.docx`

Realism upgrades:
- End-to-end breach triage workflow from recovered archive to confirmed restricted exposure.
- Multi-source SOC/DFIR evidence with timeline and policy context.
- Large noisy datasets requiring targeted pivots.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and recovered artifact details.
2. Confirm extracted files in forensic logs and nested archive.
3. Correlate document classification and DLP critical alert.
4. Validate external download + SIEM incident progression.
5. Extract strategic filename and submit.

Expected answer:
- `CTF{company_strategy.docx}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m3/m3-09-archive-leak.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `company_strategy.docx`, `breach_archive.zip`, `restricted_doc_identified`, `INC-2026-5237`.
- CSV filtering for registry/download/SIEM.
- JSONL filtering for DLP critical events.
