# M9-08 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Email header investigation and source IP attribution.
- Task target: identify sending IP from mail telemetry.

### Learning Outcome
- Correlate gateway, SMTP, header parsing, and auth-control evidence.
- Distinguish target email trace from large background mail noise.
- Confirm attribution with SIEM normalized incident events.

### Previous Artifact Weaknesses
- Single email header file exposed the answer directly.
- No realistic mail-infrastructure dataset or correlation steps.
- Missing authentication/audit context common in SOC investigations.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Mail-gateway telemetry with message IDs and source infrastructure.
2. SMTP trace logs showing queue and source transitions.
3. Parsed header chains and SPF/DKIM/DMARC audit records.
4. SIEM timeline for final source-IP confirmation.

### Key Signals Adopted
- Target source IP appears as `203.0.113.88` across gateway, SMTP, parsed headers, and auth audit.
- SIEM timeline includes `sending_ip_confirmed` event for same IP.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `mail_gateway.log` (**6,901 lines**) gateway telemetry with one target event.
- `smtp_trace.log` (**7,301 lines**) SMTP trace noise plus target queue row.
- `header_parse.jsonl` (**5,601 lines**) parsed header chain with target message.
- `auth_audit.log` (**5,201 lines**) SPF/DKIM/DMARC control results including target anomaly.
- `timeline_events.csv` (**5,103 lines**) SIEM heartbeat and sending-IP confirmation.
- `email_header.txt` direct low-fidelity clue.
- Incident briefing, case notes, and intel snapshot.

Realism upgrades:
- High-volume cross-system mail telemetry.
- Requires message/IP pivoting across multiple evidence sources.
- Mirrors practical SOC email investigations.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-5908`).
2. Identify suspicious message context and source IP in gateway/smtp logs.
3. Confirm source IP in header parse and auth audit.
4. Validate via SIEM timeline/intel notes.
5. Submit sending IP.

Expected answer:
- `CTF{203.0.113.88}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m9/m9-08-email-exposure.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `203.0.113.88`, `MSG99998888`, `sending_ip_confirmed`.
- Validate source IP appears consistently across at least three evidence sources.
