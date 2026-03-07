# M6-10 Instructor Notes

## Objective
- Train learners to identify the attacked internal target during SMB lateral movement.
- Expected answer: `CTF{192.168.1.12}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5610`
   - suspected source: `192.168.1.90`
2. In `smb_traffic.pcap`, locate repeated denied SMB auth/share attempts from source to one internal target.
3. In `east_west_flow.csv`, confirm concentrated SMB flows from source to same target.
4. In `windows_security_events.log` and `smb_activity.csv`, validate host/process level movement evidence.
5. In `lateral_movement_alerts.jsonl` and `timeline_events.csv`, confirm attacked-host IOC.
6. Submit attacked internal host IP.

## Key Indicators
- Packet pivot:
  - `192.168.1.90,192.168.1.12,...,STATUS_LOGON_FAILURE/STATUS_ACCESS_DENIED`
- Flow pivot:
  - `...,192.168.1.90,192.168.1.12,...,lateral-movement-suspected,...`
- Endpoint pivot:
  - `WS-190 ... target_ip=192.168.1.12 ... suspected_lateral_movement`
- Alert pivot:
  - `"type":"lateral_movement_detected","attacked_host":"192.168.1.12"`
- SIEM pivot:
  - `attacked_host_identified ... 192.168.1.12`

## Suggested Commands / Tools
- `rg "192\\.168\\.1\\.12|STATUS_LOGON_FAILURE|lateral_movement_detected|attacked_host_identified|suspected_lateral_movement" evidence`
- Review:
  - `evidence/network/smb_traffic.pcap`
  - `evidence/network/east_west_flow.csv`
  - `evidence/network/windows_security_events.log`
  - `evidence/endpoint/smb_activity.csv`
  - `evidence/security/lateral_movement_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
