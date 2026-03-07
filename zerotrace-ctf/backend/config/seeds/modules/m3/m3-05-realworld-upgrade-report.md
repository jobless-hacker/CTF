# M3-05 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Public paste credential leak investigation with follow-on abuse detection.
- Task target: identify leaked VPN username.

### Learning Outcome
- Correlate external leak intelligence with authentication telemetry and identity context.
- Validate credential exposure via DLP and incident timeline.
- Extract exact leaked username from noisy evidence.

### Previous Artifact Weaknesses
- Single tiny paste text file with direct answer.
- No threat-intel, abuse, or policy context.
- Minimal SOC realism and no investigative chain.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK - Credentials in Files / Unsecured Credentials exposure patterns:  
   https://attack.mitre.org/techniques/T1552/001/
2. NIST SP 800-61 incident handling and analysis workflow:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. Threat-intel + IAM investigation approach (paste monitoring + auth abuse correlation + SOC timeline).

### Key Signals Adopted
- Paste capture contains `vpn_user: corpvpn`.
- OSINT feed raises high-confidence credential hit for same source.
- VPN gateway logs show immediate failed attempts using `corpvpn`.
- DLP and SIEM classify leak and abuse as high/critical events.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `paste_capture_20260307.txt` (**6,209 lines**) leak capture artifact.
- `osint_paste_feed.jsonl` (**6,801 lines**) external intel monitoring.
- `vpn_auth_attempts.csv` (**7,604 lines**) auth abuse telemetry.
- `dlp_leak_alerts.jsonl` (**4,102 lines**) leak-protection detections.
- `timeline_events.csv` (**5,004 lines**) SIEM sequence.
- `directory_accounts.csv` (**6 lines**) identity context.
- `credential_handling_policy.txt` (**4 lines**) policy baseline.
- Briefing files.

Realism upgrades:
- Multi-source intel + IAM + SOC evidence with high noise.
- Clear chain: leak discovery -> abuse attempt -> incident escalation.
- Practical analyst workflow rather than direct static lookup.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope and leak source.
2. Validate credential hit in paste capture and OSINT feed.
3. Correlate with VPN auth failures from external IP.
4. Confirm account context in identity directory.
5. Validate DLP/SIEM escalation and return leaked username.

Expected answer:
- `CTF{corpvpn}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m3/m3-05-pastebin-leak.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `corpvpn`, `vpn_user`, `paste-share.example`.
- CSV filtering in VPN auth attempts and timeline.
- `jq` filtering for high/critical leak alerts in JSONL feeds.
