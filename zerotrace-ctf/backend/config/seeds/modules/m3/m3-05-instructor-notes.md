# M3-05 Instructor Notes

## Objective
- Train learners to investigate a public credential leak and map it to real authentication abuse.
- Expected answer: `CTF{corpvpn}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - leak source: `paste-share.example/raw/984421`
   - window: around `2026-03-07 12:08-12:10 UTC`
2. In `paste_capture_20260307.txt`, locate leaked credential pair and identify VPN username.
3. In `osint_paste_feed.jsonl`, confirm high-confidence credential mention for same leak source.
4. In `vpn_auth_attempts.csv`, confirm attempted abuse of leaked username from external IP.
5. In `directory_accounts.csv`, verify account context and ownership.
6. In `dlp_leak_alerts.jsonl`, confirm high/critical leak + abuse detection.
7. In `timeline_events.csv`, confirm escalation sequence and incident opening.
8. Return leaked VPN username.

## Key Indicators
- Username in leak: `corpvpn`
- Source: `paste-share.example/raw/984421`
- Abuse signal: failed VPN attempts using leaked username
- SOC confirmation: critical timeline event `vpn_bruteforce_attempt`

## Suggested Commands / Tools
- `rg "corpvpn|vpn_user|paste-share.example|vpn_bruteforce_attempt" evidence`
- CSV filtering in:
  - `vpn_auth_attempts.csv`
  - `timeline_events.csv`
- `jq` filtering for high/critical in:
  - `osint_paste_feed.jsonl`
  - `dlp_leak_alerts.jsonl`
