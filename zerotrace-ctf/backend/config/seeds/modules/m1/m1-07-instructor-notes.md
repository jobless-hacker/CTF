# M1-07 Instructor Notes

## Objective
- Train learners to investigate accidental outbound email data exposure.
- Expected answer: `CTF{confidentiality}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and identify investigation pivots:
   - `Message-ID`: `<20260306.100817.4421@company.local>`
   - `Queue ID`: `7B9D1A4C2E`
2. Validate message metadata and recipients in `message.eml`.
3. Correlate gateway delivery in `mail_gateway_log.txt` using queue/message identifiers.
4. Confirm DLP detection and policy behavior in `dlp_alerts.jsonl`:
   - sensitive classifiers matched
   - policy mode `audit_only`
   - final action `delivered_notify`
5. Confirm recipient-level status in `message_trace_results.csv`.
6. Cross-check sender operation in `mailbox_audit_events.csv`.
7. Verify recipient domain classification via `approved_recipient_domains.csv`.
8. Use `normalized_events.csv` to confirm security-severity context and conclude CIA impact.

## Key Indicators
- External recipient: `records.review@customerdocs.co`
- Internal look-alike expectation: `*@company.local` review aliases
- Sensitive file: `march_review.xlsx`
- Delivery state: successfully delivered externally despite DLP alert
- SIEM pivot: `external_delivery_after_dlp_audit_only`

## Suggested Commands / Tools
- `rg "20260306.100817.4421|7B9D1A4C2E|records.review@customerdocs.co" evidence`
- `rg "policy_mode|final_action|matched_classifiers|DLP-20260306-8431" evidence/security/dlp_alerts.jsonl`
- CSV filtering by `message_id`, `recipient`, `external_recipient_count`
- Timeline sort to align SMTP -> DLP -> trace -> SIEM flow.
