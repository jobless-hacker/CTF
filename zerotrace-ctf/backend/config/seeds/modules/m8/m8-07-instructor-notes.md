# M8-07 Instructor Notes

## Objective
- Train learners to investigate exposed cloud security group rules and identify sensitive open port.
- Expected answer: `CTF{22}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5807`
   - security group: `sg-prod-web`
2. In `security_group_inventory.log` and `security_group.txt`, identify candidate sensitive open port.
3. In `security_group_rules.csv`, confirm internet exposure via `0.0.0.0/0`.
4. In `cloudtrail_events.jsonl`, validate ingress authorization event for sensitive port.
5. In `vpc_flow.log`, confirm external traffic reaches that exposed port.
6. In `sg_config_audit.log`, confirm policy violation details.
7. In `open_sg_alerts.jsonl` and `timeline_events.csv`, extract normalized exposed port value.
8. Submit sensitive open port value.

## Key Indicators
- Rule pivot:
  - `22/tcp open to 0.0.0.0/0`
  - `port=22, cidr=0.0.0.0/0`
- CloudTrail pivot:
  - `"eventName":"AuthorizeSecurityGroupIngress"`
  - `"fromPort":22`
- Flow pivot:
  - `dstport=22 action=ACCEPT`
- Audit/alert pivot:
  - `exposed_port=22`
- SIEM pivot:
  - `sensitive_open_port_identified ... 22`

## Suggested Commands / Tools
- `rg "0.0.0.0/0|port=22|fromPort|exposed_port|sensitive_open_port_identified" evidence`
- Review:
  - `evidence/cloud/security_group_inventory.log`
  - `evidence/cloud/security_group_rules.csv`
  - `evidence/cloud/security_group.txt`
  - `evidence/cloud/cloudtrail_events.jsonl`
  - `evidence/cloud/vpc_flow.log`
  - `evidence/cloud/sg_config_audit.log`
  - `evidence/security/open_sg_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
