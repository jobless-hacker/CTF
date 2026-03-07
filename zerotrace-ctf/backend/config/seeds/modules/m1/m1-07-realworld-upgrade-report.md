# M1-07 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Accidental data disclosure via mis-addressed outbound email.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Trace one email across message headers, gateway logs, DLP events, and message trace exports.
- Separate normal outbound mail traffic from true data-exposure incidents.
- Validate recipient trust/allowlist context before concluding impact.

### Previous Artifact Weaknesses
- Small evidence set with direct answer path.
- Limited background noise and minimal recipient context.
- Weak simulation of enterprise messaging + DLP triage workflow.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. RFC 5322 Internet Message Format (mail header/body structure):  
   https://www.rfc-editor.org/rfc/rfc5322
2. RFC 5321 SMTP protocol and delivery semantics (`Received`, relay behavior):  
   https://www.rfc-editor.org/rfc/rfc5321
3. Exchange Online message trace workflow (sender/recipient/status analysis):  
   https://learn.microsoft.com/en-us/exchange/monitoring/trace-an-email-message/message-trace-modern-eac
4. Microsoft Purview DLP policy tuning and test mode (`audit`-style behavior):  
   https://learn.microsoft.com/en-us/purview/dlp-policy-tips
5. Google Workspace Email Log Search (delivery forensics fields and pivots):  
   https://support.google.com/a/answer/2618874

### Key Signals Adopted
- One specific `Message-ID` and `queue_id` linked across all evidence.
- DLP detection in audit-only mode (alerted but still delivered).
- External recipient domain visually similar to internal alias.
- High-volume normal mail flow and low-confidence DLP false positives.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `mail_gateway_log.txt` (**14,107 lines**) postfix-style SMTP telemetry.
- `dlp_alerts.jsonl` (**5,201 lines**) noisy low/medium DLP alerts plus critical incident.
- `message_trace_results.csv` (**9,103 lines**) large trace export with recipient-level rows.
- `mailbox_audit_events.csv` (**4,302 lines**) send-operation audit stream.
- `normalized_events.csv` (**6,503 lines**) SIEM-normalized detections.
- `message.eml` with realistic multi-hop headers and MIME structure.
- Supporting context: attachment manifest, recipient allowlist, incident ticket, analyst handoff.

Realism upgrades:
- Multi-source correlation required.
- False positives included (test-data DLP hits and normal outbound partner mail).
- Realistic timestamps, mailbox/user/client IP context, and delivery statuses.
- Investigation requires validating trust boundaries, not just seeing “external”.

## Step 4 - Flag Engineering

Expected investigation path:
1. Pivot on message identifiers in `message.eml`.
2. Confirm external delivery in gateway + message trace.
3. Confirm sensitive attachment classification in DLP evidence.
4. Validate recipient domain is not allowlisted.
5. Determine primary CIA impact.

Expected flag:
- `CTF{confidentiality}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-07-mis-sent-email.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for message-id and queue-id pivots.
- CSV filtering for trace/audit correlation.
- `jq` for JSONL DLP analysis.
- Timeline alignment across SMTP, DLP, and SIEM events.
