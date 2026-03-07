# M8-06 Instructor Notes

## Objective
- Train learners to investigate suspicious CloudTrail login activity and identify malicious source IP.
- Expected answer: `CTF{185.22.33.41}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5806`
2. In `cloudtrail_events.jsonl` and `cloudtrail.json`, locate suspicious `ConsoleLogin` source IP.
3. In `console_login_audit.log`, confirm anomalous successful login with risk indicator.
4. In `geoip_enrichment.csv`, validate external suspicious reputation for the same IP.
5. In `guardduty_findings.jsonl`, confirm threat finding references the same source IP.
6. In `mfa_policy_audit.log`, verify MFA policy violation tied to suspicious login.
7. In `timeline_events.csv`, extract normalized suspicious IP indicator.
8. Submit suspicious IP address.

## Key Indicators
- CloudTrail pivot:
  - `"eventName":"ConsoleLogin"`
  - `"sourceIPAddress":"185.22.33.41"`
- Login pivot:
  - `src_ip=185.22.33.41 mfa=No result=Success risk=critical`
- GeoIP pivot:
  - `185.22.33.41 ... reputation=high`
- Detection pivot:
  - `"source_ip":"185.22.33.41"`
- SIEM pivot:
  - `suspicious_ip_identified ... 185.22.33.41`

## Suggested Commands / Tools
- `rg "185.22.33.41|ConsoleLogin|mfa=No|source_ip|suspicious_ip_identified" evidence`
- Review:
  - `evidence/cloud/cloudtrail_events.jsonl`
  - `evidence/cloud/cloudtrail.json`
  - `evidence/cloud/console_login_audit.log`
  - `evidence/cloud/geoip_enrichment.csv`
  - `evidence/security/guardduty_findings.jsonl`
  - `evidence/cloud/mfa_policy_audit.log`
  - `evidence/siem/timeline_events.csv`
