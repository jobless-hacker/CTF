# M9-05 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- OSINT website archive investigation for legacy infrastructure discovery.
- Task target: identify old portal domain.

### Learning Outcome
- Correlate web archive, crawler, DNS, and certificate telemetry for historical domain pivots.
- Validate legacy domain evidence across multiple noisy sources.
- Use SIEM normalization for final attribution confidence.

### Previous Artifact Weaknesses
- Single short artifact directly disclosed the domain.
- No realistic archive intelligence pipeline context.
- No noisy historical dataset requiring analyst pivots.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Wayback/archive index exports with mixed redirects and noise.
2. Archive crawler logs from historical web snapshots.
3. Passive DNS historical records for infrastructure pivots.
4. Certificate transparency logs and SIEM events for final confirmation.

### Key Signals Adopted
- Target legacy domain: `oldportal.company.net`.
- Wayback/crawler/DNS/CT records all include the same domain.
- SIEM timeline confirms legacy portal domain identification.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `wayback_index.csv` (**6,902 lines**) archive index noise plus target URL row.
- `archive_crawler.log` (**7,301 lines**) crawler telemetry plus legacy portal detection event.
- `historical_dns.jsonl` (**5,601 lines**) passive DNS history with target domain row.
- `ct_log_extract.csv` (**4,802 lines**) CT records with target certificate entry.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat + legacy portal confirmation.
- `archive.txt` direct low-fidelity clue.
- Incident briefing, case notes, and intel snapshot.

Realism upgrades:
- High-noise historical intelligence data requiring correlation.
- Multiple corroborating sources before final answer.
- Mimics practical OSINT infrastructure mapping workflows.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-5905`).
2. Pivot on candidate legacy domains in archive and crawler datasets.
3. Confirm in passive DNS and CT logs.
4. Validate final domain in SIEM timeline/intel notes.
5. Submit old portal domain.

Expected answer:
- `CTF{oldportal.company.net}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m9/m9-05-website-archive.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `oldportal.company.net`, `legacy_portal_detected`, `legacy_portal_confirmed`.
- Confirm domain presence in at least three independent sources before submission.
