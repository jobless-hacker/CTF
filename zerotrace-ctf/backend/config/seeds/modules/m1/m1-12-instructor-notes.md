# M1-12 Instructor Notes

## Objective
- Train learners to investigate replay-like duplicate payment processing.
- Expected answer: `CTF{integrity}`.

## Expected Investigation Path
1. Start from `incident_ticket.txt` and lock pivots:
   - `ORD-2026-4401`
   - `transaction_id=99312`
   - `idempotency_key=pay-ord-2026-4401`
2. Validate duplicate successful API calls in `api_gateway_requests.log`.
3. Confirm duplicate approvals in `authorization_events.csv`.
4. Confirm duplicate posted financial entries in `transaction_ledger.csv`.
5. Correlate cache state and failover behavior:
   - `idempotency_cache_state.csv` (key eviction/miss)
   - `cache_failover.log` (failover and warmup gap)
6. Cross-check severity context in `normalized_findings.csv`.
7. Filter benign retries that were blocked.
8. Classify CIA impact.

## Key Indicators
- Repeated successful auth timestamps:
  - `2026-03-06T12:15:01Z`
  - `2026-03-06T12:15:03Z`
  - `2026-03-06T12:15:05Z`
- Duplicate posted ledger entries for `txn=99312`
- Idempotency key eviction just before replay window
- High-confidence fraud/siem replay findings

## Suggested Commands / Tools
- `rg "ORD-2026-4401|txn=99312|pay-ord-2026-4401" evidence`
- CSV filter by order/transaction across:
  - `authorization_events.csv`
  - `transaction_ledger.csv`
  - `idempotency_cache_state.csv`
- Time-align with `cache_failover.log` and `normalized_findings.csv`.
