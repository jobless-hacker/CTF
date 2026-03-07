# M8-07 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Internet-exposed sensitive management port due to insecure security group rules.
- Task target: identify the sensitive open port value.

### Learning Outcome
- Investigate network exposure through cloud posture, config, flow, and control-plane evidence.
- Correlate SG rule changes with observed network behavior and detections.
- Extract normalized exposed port indicator from SIEM/security tooling.

### Previous Artifact Weaknesses
- Single security group text file gave answer immediately.
- No realistic cloud-network investigation flow.
- Missing CloudTrail/config/flow/detection context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Security group inventory and rule-export snapshots.
2. VPC flow logs confirming actual inbound traffic on exposed port.
3. CloudTrail ingress authorization event for public CIDR exposure.
4. Config audit + security alerts + SIEM timeline normalization.

### Key Signals Adopted
- SG rule export shows `22/tcp` open to `0.0.0.0/0`.
- CloudTrail ingress event authorizes port `22` publicly.
- VPC flow logs include external traffic to destination port `22`.
- Alerts/SIEM normalize sensitive open port as `22`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `security_group_inventory.log` (**7,101 lines**) posture baseline with one violation.
- `security_group_rules.csv` (**5,602 lines**) SG rules baseline and critical public sensitive port row.
- `vpc_flow.log` (**6,201 lines**) traffic baseline plus external access on port `22`.
- `cloudtrail_events.jsonl` (**5,401 lines**) baseline control-plane events + ingress authorization event.
- `sg_config_audit.log` (**5,101 lines**) policy baseline with one exposure violation.
- `open_sg_alerts.jsonl` (**4,301 lines**) noisy alert stream plus critical exposed-port alert.
- `timeline_events.csv` (**5,004 lines**) SIEM correlation and final open-port identification.
- `security_group.txt` direct simple artifact.
- `security_group_exposure_policy.txt` and `open_security_group_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-noise cloud + network evidence requiring cross-source pivots.
- Ties rule changes to observed traffic and security detections.
- Includes operational SOC/CloudSec process context.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5807`) and SG under review.
2. Identify candidate sensitive port in SG inventory/rules artifacts.
3. Confirm exposure via CloudTrail ingress events and VPC flow logs.
4. Validate config-audit and alert/SIEM normalized open-port indicators.
5. Submit sensitive open port value.

Expected answer:
- `CTF{22}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m8/m8-07-open-security-group.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `0.0.0.0/0`, `port=22`, `fromPort`, `exposed_port`, `sensitive_open_port_identified`.
- Correlate SG rules/cloudtrail/flow/audit evidence before submission.
