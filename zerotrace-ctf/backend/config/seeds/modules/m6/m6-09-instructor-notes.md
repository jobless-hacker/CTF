# M6-09 Instructor Notes

## Objective
- Train learners to identify a compromised internal host from layered L2 telemetry.
- Expected answer: `CTF{192.168.1.90}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5609`
   - scope: `192.168.1.0/24`
2. In `arp.log`, identify repeated forged gateway ARP replies and spoofing pattern.
3. In `mac_conflict_summary.csv`, locate high conflict-score outlier for one host.
4. In `dhcp_leases.log` and `l2_behavior.csv`, verify host/process behavior anomaly.
5. In `l2_alerts.jsonl` and `timeline_events.csv`, confirm compromised host IOC.
6. Submit compromised host IP.

## Key Indicators
- ARP pivot:
  - `src_ip=192.168.1.90 ... note=arp_spoof_suspected`
- MAC conflict pivot:
  - `192.168.1.90,2,de:ad:be:ef:90:aa|de:ad:be:ef:90:bb,...,suspected_compromise`
- Endpoint pivot:
  - `WS-190 ... dns_tunnel_agent.exe ... suspected_compromise`
- Alert pivot:
  - `"type":"infected_host_detected","compromised_host":"192.168.1.90"`
- SIEM pivot:
  - `compromised_host_confirmed ... 192.168.1.90`

## Suggested Commands / Tools
- `rg "192\\.168\\.1\\.90|arp_spoof_suspected|suspected_compromise|infected_host_detected|compromised_host_confirmed" evidence`
- Review:
  - `evidence/network/arp.log`
  - `evidence/network/mac_conflict_summary.csv`
  - `evidence/network/dhcp_leases.log`
  - `evidence/endpoint/l2_behavior.csv`
  - `evidence/security/l2_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
