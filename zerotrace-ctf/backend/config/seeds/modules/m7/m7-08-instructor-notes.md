# M7-08 Instructor Notes

## Objective
- Train learners to investigate command injection and identify the injected command token.
- Expected answer: `CTF{cat}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5708`
   - request id: `req-9918123`
2. In `gateway_access.log`, identify suspicious request path and source.
3. In `app_request_params.log`, confirm raw query includes metacharacter and command token.
4. In `request_capture.txt`, verify exact injected request structure.
5. In `waf.log`, confirm command injection detection token.
6. In `exec_audit.log`, confirm parsed command token at host execution layer.
7. In `command_injection_alerts.jsonl` and `timeline_events.csv`, extract normalized command indicator.
8. Submit injected command token.

## Key Indicators
- Request pivot:
  - `request_id=req-9918123`
- Query pivot:
  - `host=8.8.8.8;cat /etc/passwd`
- App pivot:
  - `injected_command=cat`
- WAF pivot:
  - `token=";cat"`
- Host pivot:
  - `parsed_injected_command=cat`
- Alert/SIEM pivot:
  - `"injected_command":"cat"`
  - `injected_command_identified ... cat`

## Suggested Commands / Tools
- `rg "req-9918123|;cat|injected_command|parsed_injected_command|injected_command_identified" evidence`
- Review:
  - `evidence/web/gateway_access.log`
  - `evidence/web/app_request_params.log`
  - `evidence/web/request_capture.txt`
  - `evidence/web/waf.log`
  - `evidence/host/exec_audit.log`
  - `evidence/security/command_injection_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
