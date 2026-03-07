# M8-04 Instructor Notes

## Objective
- Train learners to investigate overprivileged IAM role posture and identify the dangerous permission value.
- Expected answer: `CTF{*}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5804`
   - role: `migration-admin-role`
2. In `iam_role_inventory.log`, identify role posture violation and dangerous permission marker.
3. In `iam_policy_documents.jsonl` and `iam_policy.json`, confirm wildcard action/resource policy.
4. In `access_advisor.csv`, validate role behavior indicates over-privileged access profile.
5. In `iam_simulator.log`, confirm risky action allowed due to wildcard permission.
6. In `iam_risk_alerts.jsonl` and `timeline_events.csv`, extract normalized dangerous permission value.
7. Submit dangerous permission value.

## Key Indicators
- Inventory pivot:
  - `dangerous_permission=*`
- Policy pivot:
  - `"Action":"*"`
  - `"Resource":"*"`
- Simulator pivot:
  - `reason=wildcard_action`
  - `dangerous_permission=*`
- Alert/SIEM pivot:
  - `"dangerous_permission":"*"`
  - `dangerous_permission_identified ... *`

## Suggested Commands / Tools
- `rg "dangerous_permission|Action\\\":\\\"\\*\\\"|wildcard_action|decision=allowed|dangerous_permission_identified" evidence`
- Review:
  - `evidence/cloud/iam_role_inventory.log`
  - `evidence/cloud/iam_policy_documents.jsonl`
  - `evidence/cloud/iam_policy.json`
  - `evidence/cloud/access_advisor.csv`
  - `evidence/cloud/iam_simulator.log`
  - `evidence/security/iam_risk_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
