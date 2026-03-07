# M8-02 Instructor Notes

## Objective
- Train learners to investigate leaked cloud credentials across config, repo, and CI traces.
- Expected answer: `CTF{SecretKey987}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5802`
   - service: `billing-worker`
2. In `config_history.log`, find hardcoded `aws_secret_key` event and candidate value.
3. In `repo_commits.log`, validate leaked value in failed commit secret scan event.
4. In `pipeline_audit.log`, confirm leak propagated to deployment pipeline violation.
5. In `config.json`, verify explicit exposed secret key value.
6. In `secrets_scan_alerts.jsonl` and `timeline_events.csv`, use normalized leak field for final answer.
7. Submit exposed secret value.

## Key Indicators
- Config pivot:
  - `key=aws_secret_key value=SecretKey987`
- Repo pivot:
  - `secret_scan=failed ... leaked_value=SecretKey987`
- CI pivot:
  - `leaked_secret_value=SecretKey987`
- Scanner pivot:
  - `"exposed_secret":"SecretKey987"`
- SIEM pivot:
  - `exposed_secret_identified ... SecretKey987`

## Suggested Commands / Tools
- `rg "aws_secret_key|SecretKey987|secret_scan=failed|exposed_secret|exposed_secret_identified" evidence`
- Review:
  - `evidence/cloud/config_history.log`
  - `evidence/dev/repo_commits.log`
  - `evidence/ci/pipeline_audit.log`
  - `evidence/cloud/config.json`
  - `evidence/security/secrets_scan_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
