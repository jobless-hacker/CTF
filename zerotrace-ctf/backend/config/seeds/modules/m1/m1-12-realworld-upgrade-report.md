# M1-12 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Replay-like duplicate transaction processing in payment authorization flow.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate duplicate request traces across gateway, authorization, and ledger systems.
- Validate idempotency-control behavior using cache telemetry.
- Distinguish benign retries (blocked) from integrity-breaking duplicates (approved/posted).

### Previous Artifact Weaknesses
- Minimal logs and direct answer path.
- Limited operational noise and weak system-to-system correlation.
- Insufficient realism for payment-incident triage workflows.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. HTTP method semantics and idempotency context (RFC 9110):  
   https://www.rfc-editor.org/rfc/rfc9110
2. Idempotency-Key HTTP header draft (duplicate-request handling model):  
   https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header
3. NIST SP 800-63B replay resistance concept (security model for replay concerns):  
   https://pages.nist.gov/800-63-3/sp800-63b.html
4. Stripe idempotent request handling (industry API implementation reference):  
   https://docs.stripe.com/api/idempotent_requests
5. NIST SP 800-61 incident handling lifecycle (analysis/correlation workflow):  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final

### Key Signals Adopted
- Same `order_ref`, `transaction_id`, and `idempotency_key` repeated with successful status.
- Ledger contains multiple posted debit reservations for one transaction.
- Cache failover/eviction evidence aligns with replay window.
- Benign duplicate attempts exist but are blocked (`409`/`duplicate_rejected`) as false positives.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `api_gateway_requests.log` (**16,203 lines**) gateway request stream.
- `authorization_events.csv` (**9,204 lines**) payment-processor outcomes.
- `transaction_ledger.csv` (**7,604 lines**) financial posting records.
- `idempotency_cache_state.csv` (**6,103 lines**) dedupe key state timeline.
- `cache_failover.log` (**2,403 lines**) cache-cluster operational events.
- `normalized_findings.csv` (**6,904 lines**) fraud/SIEM findings.
- Incident context: ticket, analyst handoff, idempotency control note, fraud summary.

Realism upgrades:
- Multi-source evidence requiring correlation.
- High-volume traffic with false positives.
- Plausible infrastructure cause (cache failover) tied to logic failure.
- Clear path from replay event to transaction-integrity impact.

## Step 4 - Flag Engineering

Expected investigation path:
1. Identify repeated successful auths for same transaction in gateway/auth logs.
2. Confirm duplicate posted ledger entries for that transaction.
3. Correlate idempotency key eviction/miss around same window.
4. Filter out benign duplicate attempts that were correctly blocked.
5. Classify primary CIA impact.

Expected flag:
- `CTF{integrity}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-12-packet-replay-attack.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for order/transaction/idempotency pivots.
- CSV filtering across auth/ledger/cache datasets.
- Timeline correlation with cache failover events.
