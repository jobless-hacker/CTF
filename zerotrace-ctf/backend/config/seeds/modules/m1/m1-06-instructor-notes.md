# M1-06 Instructor Notes

## Objective
- Train learners to investigate a leaked-credential incident spanning repository and cloud telemetry.
- Expected answer: `CTF{confidentiality}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` to frame the incident window.
2. Confirm credential material in `git_show_leak_commit.patch`.
3. Correlate Git/GitHub evidence:
   - `push_activity_events.csv` for bypass + push timing
   - `github_audit_log.jsonl` for `secret_scanning.push_protection_bypass`
   - `secret_scanning_alerts.jsonl` for critical active alert and location
4. Eliminate noise:
   - fixture/test false positives in `secret_scanning_alerts.jsonl`
   - low-severity SIEM entries in `normalized_findings.csv`
5. Confirm impact amplification:
   - `cloudtrail_events.jsonl` showing same access key from external IP after exposure
6. Classify CIA impact with evidence-backed reasoning.

## Key Indicators
- Commit: `48df8c1a92f08d5f213b8c7f5e6b0aa4c431d901`
- File location: `config/.env.production:4-5`
- Bypass action: `secret_scanning.push_protection_bypass`
- Exposed key ID: `AKIAXJ4Q8K7M2N6P4R1S`
- External usage IP: `45.83.22.91`
- Cloud event pivot: `GetObject` on sensitive export path

## Suggested Commands / Tools
- `rg "48df8c1a|AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|push_protection_bypass" evidence`
- `rg "12417|12418|critical|config/.env.production" evidence/security/secret_scanning_alerts.jsonl`
- `rg "AKIAXJ4Q8K7M2N6P4R1S|45.83.22.91|GetObject" evidence/cloud/cloudtrail_events.jsonl`
- `jq` for JSONL filtering and timestamp-based correlation.
