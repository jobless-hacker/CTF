# M2-10 Instructor Notes

## Objective
- Train learners to identify malicious script delivery commands from shell-forensics and correlated host/network telemetry.
- Expected answer: `CTF{wget}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - host: `app-srv-03`
   - user in context: `john`
   - window: around `2026-03-07 22:14 UTC`
2. In `bash_history.log`, find suspicious download-and-execute sequence.
3. In `process_exec_audit.log`, confirm exact executable and arguments used for download.
4. In `egress_connections.csv`, confirm corresponding outbound request to malicious domain.
5. In `file_mod_timeline.csv`, confirm script creation, chmod, and execution from `/tmp`.
6. In `edr_command_alerts.jsonl`, confirm high/critical detection chain.
7. In `timeline_events.csv`, validate end-to-end incident flow.
8. Return the command used to download the malicious script.

## Key Indicators
- Command: `wget`
- URL: `http://evil.com/backdoor.sh`
- Chain: download -> chmod -> execution
- Correlated detection: `external_script_download` and `downloaded_script_execution`

## Suggested Commands / Tools
- `rg "wget|backdoor.sh|evil.com|script_download|downloaded_script_execution" evidence`
- CSV/log timeline checks in:
  - `bash_history.log`
  - `process_exec_audit.log`
  - `egress_connections.csv`
  - `file_mod_timeline.csv`
  - `timeline_events.csv`
- `jq` for high/critical events in `edr_command_alerts.jsonl`.
