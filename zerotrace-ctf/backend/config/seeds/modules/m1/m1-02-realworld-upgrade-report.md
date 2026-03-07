# M1-02 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Credentials exposed in transit over cleartext HTTP.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate packet evidence with SOC logs.
- Distinguish true credential exposure from noisy detections.
- Classify impact using CIA triad reasoning.

### Previous Artifact Weaknesses
- Very small case size (single small pcap + minimal notes).
- No volume pressure (not SOC-like).
- Limited false-positive context.
- Minimal multi-tool workflow requirement.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. Wireshark sample capture references (real packet-investigation workflow patterns):  
   https://wiki.wireshark.org/SampleCaptures
2. Zeek log data model and fielded network telemetry (`conn.log`, protocol logs):  
   https://docs.zeek.org/en/current/logs/index.html
3. Suricata EVE JSON event schema (`flow`, `alert`, `http` events):  
   https://docs.suricata.io/en/latest/output/eve/eve-json-output.html
4. HTTP Basic authentication transmits `user:password` credentials (base64, not encryption):  
   https://www.rfc-editor.org/rfc/rfc7617
5. CICIDS2017 (realistic high-volume network dataset style for SOC training):  
   https://www.unb.ca/cic/datasets/ids-2017.html

### Key Signals Adopted
- HTTP `POST /auth/login` with credential material.
- Correlated IDs across Zeek and Suricata (`uid`/`flow_id` style pivoting).
- Large noisy network logs and benign traffic baselines.
- Scanner-generated false positives in same time window.

## Step 3 - Artifact Design Upgrade

Upgraded artifact pack now includes:
- `capture.pcap` with mixed benign traffic + scanner probes + credential leak exchange.
- `zeek_conn.log` (**5,211 lines**) high-volume connection telemetry.
- `zeek_http.log` (**2,611 lines**) protocol-level HTTP transaction evidence.
- `suricata_eve.json` (**703 lines**) flow + alert + HTTP event mix.
- `proxy_access.log` (**12,002 lines**) noisy enterprise proxy timeline.
- `asset_inventory.csv`, `threat_intel_context.csv`, incident ticket, and analyst handoff.

Realism upgrades:
- Multiple users and source IPs.
- Mixed internal/external traffic.
- Noise and false positives.
- Time-windowed investigative pivot.

## Step 4 - Flag Engineering

Expected investigation path:
1. Identify suspicious auth-related HTTP activity.
2. Confirm cleartext credential evidence in PCAP / protocol logs.
3. Correlate with Suricata alert and flow details.
4. Validate scanner traffic is mostly false-positive noise.
5. Classify primary CIA impact.

Expected flag:
- `CTF{confidentiality}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-02-sniffed-credentials.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- Wireshark / tshark for packet inspection.
- `rg` / `grep` for rapid IOC and credential pivots.
- `jq` for Suricata EVE JSON filtering.
- Optional SIEM import (Zeek + EVE) for correlation drills.

