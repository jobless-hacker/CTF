# M2-07 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Investigation of suspicious web download activity and malicious domain identification.
- Task target: identify the malicious domain used in the request chain.

### Learning Outcome
- Correlate web proxy traffic, DNS resolution, endpoint download telemetry, firewall egress, and EDR detections.
- Use threat intelligence and policy context to support domain-level conclusion.
- Handle noisy SOC telemetry and pivot from host/user/time to final IOC.

### Previous Artifact Weaknesses
- Single small proxy file with low realism.
- No cross-source validation (DNS, endpoint, EDR, firewall, intel, SIEM).
- Minimal noise and no realistic investigation path.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Drive-by Compromise and Command/Control over Web protocols:  
   https://attack.mitre.org/techniques/T1189/  
   https://attack.mitre.org/techniques/T1071/001/
2. MITRE ATT&CK - Ingress Tool Transfer (downloaded tooling):  
   https://attack.mitre.org/techniques/T1105/
3. NIST SP 800-61 incident analysis and evidence correlation workflow:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final

### Key Signals Adopted
- Proxy: direct HTTP downloads from `malicious-site.ru` including `payload.exe` and `loader.ps1`.
- DNS: repeated resolution of `malicious-site.ru` to `185.225.19.77`.
- Endpoint/EDR: executable/script download and malware-stager alert tied to same domain.
- Threat intel: very low reputation with malware-delivery classification.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `proxy.log` (**11,503 lines**) web request telemetry.
- `dns_queries.csv` (**8,704 lines**) DNS evidence.
- `download_history.csv` (**6,403 lines**) endpoint browser download history.
- `firewall_egress.csv` (**5,904 lines**) outbound connection context.
- `edr_web_alerts.jsonl` (**4,102 lines**) endpoint security alerts.
- `domain_reputation.csv` (**3,202 lines**) threat-intel context.
- `timeline_events.csv` (**5,005 lines**) SIEM event sequence.
- `web_access_policy.txt` (**4 lines**) policy controls.
- Briefing files.

Realism upgrades:
- Multi-source artifact correlation with realistic timestamped sequence.
- High baseline noise plus false positives.
- IOC extraction requires pivoting across logs, not single-line lookup.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident ticket to identify host/user/time.
2. Pivot proxy requests to suspicious executable/script downloads.
3. Correlate domain via DNS and firewall destination IP.
4. Confirm domain in endpoint downloads and EDR detections.
5. Validate malicious reputation and policy violation context.
6. Return malicious domain.

Expected answer:
- `CTF{malicious-site.ru}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m2/m2-07-unusual-web-request.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `malicious-site.ru`, `payload.exe`, `185.225.19.77`.
- CSV filtering by host/user/time for DNS/firewall/download datasets.
- `jq` extraction for high/critical events in `edr_web_alerts.jsonl`.
