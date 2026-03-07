# M9-08 Instructor Notes

## Objective
- Train learners to identify email sending infrastructure from realistic header and mail telemetry.
- Expected answer: `CTF{203.0.113.88}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5908`
   - goal: identify sending IP
2. In `mail_gateway.log`, identify suspicious message/IP candidate.
3. In `smtp_trace.log`, confirm same source IP and linked queue/message.
4. In `header_parse.jsonl`, validate received-chain source IP.
5. In `auth_audit.log`, confirm auth anomaly associated with same source IP.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final sending IP.
7. Submit source IP.

## Key Indicators
- IP pivot:
  - `203.0.113.88`
- Message pivot:
  - `MSG99998888`
- SIEM pivot:
  - `sending_ip_confirmed`

## Suggested Commands / Tools
- `rg "203.0.113.88|MSG99998888|sending_ip_confirmed" evidence`
- Review:
  - `evidence/email_header.txt`
  - `evidence/mail/mail_gateway.log`
  - `evidence/mail/smtp_trace.log`
  - `evidence/mail/header_parse.jsonl`
  - `evidence/mail/auth_audit.log`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
