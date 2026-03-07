# M9-09 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Subdomain enumeration and development endpoint identification.
- Task target: identify development subdomain from DNS intelligence.

### Learning Outcome
- Correlate subdomain discovery across brute-force, passive DNS, and certificate data.
- Isolate development-domain evidence from high-volume DNS noise.
- Confirm final finding with SIEM normalized timeline events.

### Previous Artifact Weaknesses
- Single DNS list provided direct answer.
- No realistic DNS telemetry scale or noise.
- Missing multi-source validation process.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Subdomain inventory exports from recurring discovery pipelines.
2. DNS brute-force logs and resolver-query traces.
3. Passive DNS + certificate SAN correlation.
4. SIEM timeline confirmation for final subdomain attribution.

### Key Signals Adopted
- Development subdomain repeatedly appears as `dev.company.com`.
- Evidence present across inventory, brute-force, passive DNS, cert SAN, and resolver logs.
- SIEM confirms development subdomain identification.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `subdomain_inventory.csv` (**6,802 lines**) inventory noise with target subdomain row.
- `dns_bruteforce.log` (**7,301 lines**) brute-force discovery noise with target detection.
- `passive_dns.jsonl` (**5,601 lines**) passive DNS stream containing target domain.
- `certificate_san_extract.csv` (**5,002 lines**) certificate SAN records with target in SAN set.
- `resolver_query.log` (**5,401 lines**) resolver traces with explicit target answer.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat plus confirmation event.
- `dns_records.txt` direct low-fidelity clue.
- Incident briefing, case notes, and intel snapshot.

Realism upgrades:
- High-noise DNS intelligence pack resembling OSINT recon pipelines.
- Requires cross-source corroboration before submission.
- Mirrors real infrastructure-mapping investigations.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5909`).
2. Identify candidate dev subdomain in inventory and brute-force logs.
3. Confirm in passive DNS, cert SAN, and resolver query traces.
4. Validate with SIEM timeline and intel notes.
5. Submit development subdomain.

Expected answer:
- `CTF{dev.company.com}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m9/m9-09-subdomain-discovery.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `dev.company.com`, `interesting_subdomain`, `development_subdomain_confirmed`.
- Confirm target appears in at least three independent evidence sources.
