# M9-03 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- OSINT domain attribution and registrar identification.
- Task target: identify registrar for suspicious domain.

### Learning Outcome
- Correlate WHOIS, RDAP, and operational telemetry for registrar attribution.
- Validate one domain fact across multiple noisy datasets.
- Use SIEM normalized events as final confirmation instead of single-source trust.

### Previous Artifact Weaknesses
- One simple WHOIS artifact disclosed answer immediately.
- No noise, no enrichment pipeline context, no cross-source validation.
- Not representative of real SOC OSINT workflows.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Domain inventory snapshots from enrichment jobs.
2. WHOIS batch lookup logs with many non-target domains.
3. RDAP JSON responses for registrar-normalized attribution.
4. SIEM event timeline used to confirm final registrar.

### Key Signals Adopted
- Target domain: `suspicious-site.com`.
- WHOIS and RDAP both resolve registrar to `NameCheap`.
- SIEM confirms final registrar attribution event.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `domain_inventory.csv` (**6,802 lines**) broad inventory noise with one target row.
- `whois_batch.log` (**7,201 lines**) lookup noise plus priority target resolution.
- `rdap_responses.jsonl` (**5,301 lines**) normalized registrar response with target record.
- `passive_dns.jsonl` (**5,601 lines**) contextual DNS evidence for domain triage.
- `timeline_events.csv` (**5,102 lines**) SIEM timeline including registrar confirmation.
- `whois.txt` direct low-fidelity source.
- Incident briefing, case notes, and intel snapshot.

Realism upgrades:
- Multi-source noisy attribution workflow.
- Clear pivot path from domain to normalized registrar.
- Mirrors practical OSINT and threat-intel triage.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-5903`) and target domain.
2. Pivot on `suspicious-site.com` across WHOIS and RDAP datasets.
3. Confirm normalized registrar value in SIEM timeline/intel notes.
4. Submit registrar value.

Expected answer:
- `CTF{NameCheap}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m9/m9-03-domain-investigation.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `suspicious-site.com`, `NameCheap`, `registrar_confirmed`, `registrarName`.
- Require at least two independent sources before answer submission.
