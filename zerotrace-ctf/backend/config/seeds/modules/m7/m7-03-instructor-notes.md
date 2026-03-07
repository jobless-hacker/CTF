# M7-03 Instructor Notes

## Objective
- Train learners to classify file-path abuse in a download workflow.
- Expected answer: `CTF{path_traversal}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5703`
   - endpoint: `/download`
2. In `web_request.log` and `access.log`, locate traversal payload in file parameter.
3. In `download_handler.log`, confirm path normalization failure.
4. In `file_access_audit.log`, verify denied attempt to access sensitive system file.
5. In `waf.log`, `web_attack_alerts.jsonl`, and `timeline_events.csv`, confirm attack classification.
6. Submit vulnerability class.

## Key Indicators
- Request/access pivot:
  - `/download?file=../../etc/passwd`
- App pivot:
  - `normalization=failed ... directory_traversal_attempt`
- File-audit pivot:
  - `path="/etc/passwd" status=denied`
- Alert pivot:
  - `"type":"file_path_attack_detected","attack_type":"path_traversal"`
- SIEM pivot:
  - `vulnerability_classified ... path_traversal`

## Suggested Commands / Tools
- `rg "\\.\\./\\.\\./etc/passwd|normalization=failed|path_traversal|file_path_attack_detected|vulnerability_classified" evidence`
- Review:
  - `evidence/network/web_request.log`
  - `evidence/network/access.log`
  - `evidence/application/download_handler.log`
  - `evidence/system/file_access_audit.log`
  - `evidence/network/waf.log`
  - `evidence/security/web_attack_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
