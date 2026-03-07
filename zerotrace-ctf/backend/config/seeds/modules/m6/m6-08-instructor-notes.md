# M6-08 Instructor Notes

## Objective
- Train learners to investigate high-volume outbound transfer and identify exfiltration destination.
- Expected answer: `CTF{203.0.113.200}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5608`
   - source host: `192.168.1.45` / `WS-145`
2. In `netflow.log`, locate large-byte outlier flow tied to external destination.
3. In `egress_firewall.log` and `proxy_transfer.log`, confirm same destination and transfer volume.
4. In `transfer_summary.csv`, verify endpoint process/user attribution.
5. In `dlp_alerts.jsonl` and `timeline_events.csv`, confirm final IOC destination.
6. Submit exfiltration destination IP.

## Key Indicators
- NetFlow pivot:
  - `...,192.168.1.45,203.0.113.200,...,80000000,...,suspected_exfiltration,...`
- Firewall pivot:
  - `action=ALLOW_ALERT ... dst=203.0.113.200 ... bytes=80000000 ... unusual_outbound_volume`
- Proxy pivot:
  - `url=https://203.0.113.200/upload/archive_20260308.tar ... bytes_out=80000000`
- Alert pivot:
  - `"type":"data_exfiltration_detected","exfil_destination":"203.0.113.200"`
- SIEM pivot:
  - `destination_confirmed ... 203.0.113.200`

## Suggested Commands / Tools
- `rg "203\\.0\\.113\\.200|80000000|suspected_exfiltration|data_exfiltration_detected|destination_confirmed" evidence`
- Review:
  - `evidence/network/netflow.log`
  - `evidence/network/egress_firewall.log`
  - `evidence/network/proxy_transfer.log`
  - `evidence/endpoint/transfer_summary.csv`
  - `evidence/security/dlp_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
