# M3-07 Instructor Notes

## Objective
- Train learners to investigate cloud credential leakage from repository artifacts and confirm credential abuse in cloud logs.
- Expected answer: `CTF{XyZSecretKey987}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - suspect commit: `91be7f0c12aa`
   - leak target: `config/cloud/config.json`
   - incident window around `2026-03-07 14:01-14:06 UTC`
2. In `repo_file_index.csv`, confirm confidential config file path exists in tracked repository scope.
3. In `commit_history.log` and `commit_diff.patchlog`, pivot to `91be7f0c12aa` and inspect introduced secret-bearing config content.
4. In `secret_scanner_alerts.csv`, find the critical open scanner hit for `aws_secret_key`.
5. In `cloudtrail_usage.jsonl`, verify suspicious external API calls from `185.199.110.42` using leaked access identity.
6. In `timeline_events.csv`, validate sequence: exposure -> suspicious usage -> incident opened.
7. Extract the exposed AWS secret key value and submit in `CTF{...}` format.

## Key Indicators
- Commit pivot: `91be7f0c12aa`
- Leak field: `aws_secret_key`
- Exposed value: `XyZSecretKey987`
- Suspicious external cloud source IP: `185.199.110.42`
- SIEM progression: `secret_exposed_in_repo` then `suspicious_cloud_api_usage`

## Suggested Commands / Tools
- `rg "91be7f0c12aa|aws_secret_key|XyZSecretKey987|185.199.110.42" evidence`
- CSV analysis in:
  - `secret_scanner_alerts.csv`
  - `timeline_events.csv`
  - `repo_file_index.csv`
- `jq` parsing for `cloudtrail_usage.jsonl` where `sourceIPAddress` is external.
