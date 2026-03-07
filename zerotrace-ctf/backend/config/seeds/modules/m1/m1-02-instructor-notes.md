# M1-02 Instructor Notes

## Objective
- Train learners to identify in-transit credential exposure in realistic noisy telemetry.
- Expected answer: `CTF{confidentiality}`.

## Expected Investigation Path
1. Start with `incident_ticket.txt` and define analysis window.
2. Check `threat_intel_context.csv` to avoid over-trusting scanner indicators.
3. Pivot in `zeek_http.log` for `/auth/login` and suspicious POST requests.
4. Correlate candidate request UID with `zeek_conn.log`.
5. Validate Suricata signal in `suricata_eve.json`:
   - alert signature around cleartext basic auth
   - same flow context (`flow_id`)
6. Confirm packet-level evidence in `capture.pcap`:
   - HTTP login request
   - exposed credential material (`Authorization` / POST body)
7. Classify CIA impact.

## Key Indicators
- Host: `portal.intranet.local`
- Suspicious flow: `CCREDLEAK1` / `flow_id` `944001122334455`
- Source host: `10.50.23.19`
- Cleartext auth evidence over port `80/tcp`
- False-positive scanner source: `198.51.100.77`

## Suggested Commands / Tools
- `rg "CCREDLEAK1|/auth/login|clinicops|Pulse@2026" zeek_http.log zeek_conn.log`
- `jq -c 'select(.event_type=="alert" and .flow_id==944001122334455)' suricata_eve.json`
- Wireshark display filter: `http.request.method == "POST" && http.host == "portal.intranet.local"`
- tshark quick check:  
  `tshark -r capture.pcap -Y "http.request.method == POST" -T fields -e ip.src -e http.host -e http.request.uri`

