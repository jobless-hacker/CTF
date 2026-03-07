# M6-03 Instructor Notes

## Objective
- Train learners to identify leaked username from plaintext HTTP credential exposure.
- Expected answer: `CTF{john}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5603`
   - source host: `192.168.1.60`
2. In `http_capture.pcap`, locate POST `/login` packet with cleartext credentials.
3. In `http_session_summary.csv`, confirm anomaly on same login flow.
4. In `proxy_http.log`, validate cleartext form submission evidence.
5. In `workstation_process_net.csv`, map request to local process context.
6. In `http_credential_alerts.jsonl` and `timeline_events.csv`, confirm leaked username attribution.
7. Submit leaked username.

## Key Indicators
- Packet pivot:
  - `http_body:username=john&password=secret123`
- Session pivot:
  - `/login,POST,...,plaintext_credentials_observed`
- Proxy pivot:
  - `content_hint=cleartext_form`
- Alert pivot:
  - `"leaked_username":"john"`
- SIEM pivot:
  - `plaintext_login_payload ... username=john`

## Suggested Commands / Tools
- `rg "username=john|/login|leaked_username|cleartext_form" evidence`
- Review:
  - `evidence/network/http_capture.pcap`
  - `evidence/network/http_session_summary.csv`
  - `evidence/network/proxy_http.log`
  - `evidence/security/http_credential_alerts.jsonl`
