# M7-06 Instructor Notes

## Objective
- Train learners to investigate file upload abuse and identify the malicious uploaded file.
- Expected answer: `CTF{shell.php}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5706`
2. In `upload.log`, locate suspicious upload from external source.
3. In `request_capture.txt`, validate suspicious uploaded filename.
4. In `access.log`, confirm post-upload execution request to uploaded file path.
5. In `waf.log`, `av_scan.log`, and `upload_inventory.csv`, confirm malicious classification.
6. In `upload_alerts.jsonl` and `timeline_events.csv`, extract normalized malicious file indicator.
7. Submit malicious uploaded file name.

## Key Indicators
- Upload pivot:
  - `file_name=shell.php` from `185.191.171.99`
- Runtime pivot:
  - `GET /uploads/shell.php?cmd=id`
- WAF pivot:
  - `PHP script upload attempt detected`
- AV pivot:
  - `result=malicious signature=PHP.WebShell.Generic`
- Alert pivot:
  - `"type":"malicious_upload_detected","malicious_file":"shell.php"`
- SIEM pivot:
  - `malicious_file_identified ... shell.php`

## Suggested Commands / Tools
- `rg "shell.php|malicious_file|PHP.WebShell.Generic|webshell_upload_confirmed|/uploads/shell.php" evidence`
- Review:
  - `evidence/upload/upload.log`
  - `evidence/upload/request_capture.txt`
  - `evidence/network/access.log`
  - `evidence/network/waf.log`
  - `evidence/upload/upload_inventory.csv`
  - `evidence/security/av_scan.log`
  - `evidence/security/upload_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
