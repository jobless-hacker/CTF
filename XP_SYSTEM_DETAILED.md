# ZeroTrace CTF - XP_SYSTEM_DETAILED (MVP)

## Scope

This document defines the XP (Experience Points) system for the ZeroTrace CTF MVP.

In scope:

- Static challenges only
- XP awarded per challenge
- Individual scoring only (no teams)
- Leaderboard sorted by total XP
- First-solve XP awards only
- XP auditability and integrity controls

Out of scope for MVP:

- Team scoring
- Bonus XP events
- Time-based XP decay
- Hint purchasing / XP spend
- Seasonal resets
- Dynamic scoring

## Critical Rules (Non-Negotiable)

- XP must be granted only once per challenge per user.
- XP must be transactionally safe.
- XP history must be append-only.
- Leaderboard must never trust client input.
- No recalculating XP from scratch on each request.
- XP logic must be entirely backend controlled.

## 1. XP System Philosophy

### XP Represents Verified Challenge Completion

- XP is a proof of completed work, not activity volume.
- XP is awarded only after a validated correct flag submission on an accessible challenge.
- Incorrect attempts, blocked attempts, and malformed submissions do not grant XP.

### XP Is Immutable Once Granted (MVP Rule)

- Standard XP awards are immutable after commit.
- No user-facing or admin-facing feature may edit or delete previously granted XP records.
- Corrections (if ever required operationally) must be additive, explicit, and auditable, not silent changes.

### XP Is Derived Only From Validated Flag Submissions

- The only MVP path that grants XP is successful flag validation.
- Client requests cannot set XP amounts.
- XP is derived from backend challenge configuration at the time of the award decision.

## 2. XP Data Model Overview

### Authoritative XP Tables (MVP)

#### `user_xp` (Aggregate Read Model)

Purpose:

- Stores current XP totals used by dashboard and leaderboard queries.
- Avoids recalculating totals from full history on every request.

Required fields (conceptual):

- `user_id`
- `total_xp`
- `solved_challenges_count`
- `tie_breaker_completed_at`
- timestamps (`created_at`, `updated_at`)

Rules:

- One row per user.
- Updated only by backend XP transaction flow.

#### `xp_history` (Immutable Ledger)

Purpose:

- Stores each XP event as an append-only record.
- Provides audit trail and reconciliation source for `user_xp`.

Required fields (conceptual):

- `id`
- `user_id`
- `event_type` (MVP primary event: `challenge_solve`)
- `xp_delta`
- `balance_after`
- `challenge_id`
- `challenge_attempt_id`
- `awarded_at`
- optional operator metadata for controlled corrections (not user-facing MVP feature)

Rules:

- Append-only in normal operations.
- One `challenge_solve` event per user/challenge.

### Challenge Completion Marker (Logical, MVP)

MVP does not require a separate `challenge_completions` table.

The logical completion marker is the first successful challenge submission recorded for a user/challenge pair, represented by:

- a successful `challenge_attempts` row (`is_correct = true`) for the user and challenge
- and the corresponding `xp_history` `challenge_solve` event (unique per user/challenge)

Operational implication:

- Completion state shown in challenge views is derived from trusted backend completion markers, not client cache.

## 3. XP Allocation Rules

### Award Trigger

- XP is awarded only on the first correct submission for a challenge by a user.
- Correctness must be determined by backend flag validation against stored hashed flags.

### XP Amount Source

- XP amount is determined by the challenge configuration (`xp_reward`) stored server-side.
- Client input cannot override or suggest XP values.
- XP amount is resolved during server-side submission processing.

### Atomic Award Requirement

XP award must be atomic with challenge completion recording. The backend must not produce partial success states.

At minimum, the following must commit together for a first correct solve:

- successful completion marker creation (successful attempt record)
- `xp_history` entry creation
- `user_xp` aggregate update
- leaderboard tie-break timestamp update (in `user_xp`)

### No Dynamic Recalculation for Normal Reads

- Dashboard and leaderboard reads must use `user_xp`.
- `xp_history` is used for audit/reconciliation, not as the primary per-request compute source.
- Reconciliation from history is allowed as a maintenance/audit process, not on every request.

### Backend-Only Control

- XP decisions are made entirely server-side.
- Frontend can display XP returned by the API, but cannot influence:
  - award eligibility
  - award amount
  - completion state
  - leaderboard rank

## 4. Duplicate Prevention Rules

### Already Completed Challenge -> No XP

- If the user has already completed the challenge, the system must not award XP again.
- Subsequent correct submissions return a deterministic no-reward outcome (`already completed` behavior).
- Attempts may still be logged for abuse analytics (policy-dependent), but no new completion marker or XP event is created.

### Concurrent Submission Race Handling

Threat:

- A user submits the same correct flag multiple times in parallel (double-click, multi-tab, automation).

Required behavior:

- At most one request may create the completion marker and XP award.
- All competing requests must resolve without duplicate XP.
- Non-winning requests return a no-additional-reward outcome.

### Transactional Locking Requirement

XP award processing must serialize conflicting writes for the same user/challenge and user aggregate update.

Minimum integrity requirements:

- enforce uniqueness for successful solve marker per user/challenge
- enforce uniqueness for `challenge_solve` XP history event per user/challenge (and per source attempt)
- serialize updates to the user’s aggregate XP row during balance computation/update

Locking/uniqueness must be enforced by the persistence layer, not only application memory.

### Idempotency Guarantee (MVP)

MVP does not require client-supplied idempotency keys.

The system must still provide effective idempotent outcome semantics for repeated solve attempts:

- first valid solve -> one XP award
- repeated same solve (including retries after timeout) -> no additional XP

This guarantee is provided by transactional uniqueness and duplicate-prevention rules.

## 5. XP Transaction Model

### Transaction Scope

For a first correct solve, the XP transaction is a single atomic unit.

### Transaction Steps (Authoritative Sequence)

1. Validate user authentication and challenge access (published, authorized, visible).
2. Validate submitted flag as correct (using secure flag validation flow).
3. Start XP award transaction.
4. Re-check duplicate completion/XP invariants inside the transaction.
5. Create completion marker (successful attempt record or equivalent trusted solve marker, depending on final implementation model).
6. Create `xp_history` `challenge_solve` entry with:
   - `xp_delta`
   - `balance_after`
   - `challenge_id`
   - `challenge_attempt_id`
   - `awarded_at`
7. Update `user_xp` aggregate:
   - increment `total_xp`
   - increment `solved_challenges_count`
   - set `tie_breaker_completed_at` to the award timestamp (or equivalent deterministic completion timestamp)
8. Commit transaction.
9. Return success response with awarded XP and updated totals.

### Rollback Behavior on Failure

If any step in the XP transaction fails:

- the entire transaction must roll back
- no partial XP state may remain
- no partial completion marker may remain
- no partial leaderboard-visible XP update may remain

Expected caller outcome:

- operation returns safe failure or duplicate/no-reward result depending on failure type
- system remains internally consistent

## 6. XP Integrity Protection

### No Manual Editing of `user_xp`

- `user_xp` is a derived aggregate maintained by the XP transaction flow.
- Manual edits to `user_xp.total_xp` or `solved_challenges_count` are prohibited in normal operations.
- Direct aggregate edits break auditability and are treated as integrity violations.

### All Adjustments Must Create `xp_history` Entry

- Any XP change outside standard solve flow (if ever performed) must create an explicit `xp_history` event.
- `xp_history` remains the canonical audit ledger of all XP changes.
- Aggregate changes without a matching ledger event are invalid.

### Admin Adjustment Rules (If Allowed)

MVP policy:

- No normal product feature allows admins to manually adjust user XP.
- Admin XP adjustment UI is out of scope for MVP.

Emergency operational correction policy (exception-only):

- Allowed only through documented incident/change process
- Must create explicit `xp_history` correction event
- Must update `user_xp` in the same transaction
- Must be audit-logged separately as an administrative/security event
- Must preserve non-negative total XP

### Prevent Negative XP (MVP)

- `user_xp.total_xp` must never be negative.
- `xp_history.balance_after` must never be negative.
- Standard MVP `challenge_solve` events are positive XP only.
- If emergency correction events are allowed, they must be rejected if they would reduce total XP below zero.

### Prevent XP Overflow

- XP writes must validate that the new total does not exceed the supported storage maximum.
- Overflow checks must occur before committing the aggregate update.
- Overflow must fail the transaction safely (no partial write).
- The platform must define and enforce a maximum valid XP total for MVP based on chosen storage limits.

## 7. Leaderboard Integration

### Leaderboard Source of Truth

- Leaderboard ranking derives from `user_xp` aggregate data only.
- Leaderboard must never accept or trust client-supplied XP values.
- `xp_history` is used for audit/reconciliation, not direct per-request ranking calculation.

### Tie-Breaker Logic (MVP)

Tie-breaker field:

- `user_xp.tie_breaker_completed_at`

MVP rule:

- On equal `total_xp`, the user with the earlier `tie_breaker_completed_at` ranks higher.

Clarification:

- In MVP (no XP decay, no bonus events), `tie_breaker_completed_at` represents the timestamp of the user’s most recent XP-awarding completion that produced the current total XP.
- Earlier timestamp means the user reached that XP total sooner.

### Sorting Rules

Leaderboard sort order must be deterministic:

1. `total_xp` descending
2. `tie_breaker_completed_at` ascending
3. deterministic final tie-break (internal, stable; for example user identifier) to avoid inconsistent ordering

### Pagination Behavior

- Leaderboard returns paginated results.
- Pagination must preserve sort order determinism.
- Page boundaries must not duplicate or skip rows in a stable dataset.
- Rapid concurrent XP changes may legitimately change page contents between requests; this is acceptable if sorting rules remain consistent.

## 8. Edge Case Handling

### Simultaneous Double-Click Submission

Risk:

- Two near-identical requests from one client session.

Required handling:

- One request may win and award XP.
- Other request(s) must return no-reward (`already completed`) outcome.
- No duplicate XP or duplicate completion marker.

### Server Restart During Transaction

Risk:

- Process interruption during XP award path.

Required handling:

- Transaction must either fully commit or fully roll back.
- After restart, persisted state must remain consistent:
  - no orphan XP history
  - no aggregate without ledger
  - no duplicate completion marker
- Retry after restart must still obey duplicate-prevention rules.

### User Account Deactivation

Rules:

- Historical XP remains intact and auditable after deactivation.
- Deactivation does not delete or rewrite `xp_history`.
- Deactivated users cannot earn new XP because they cannot authenticate and submit valid requests.
- Leaderboard display policy may exclude inactive users, but XP data remains preserved.

### Challenge Unpublish After Completion

Rules:

- Previously awarded XP remains valid and is not removed.
- Historical solve and XP records remain unchanged.
- User may lose view access to the challenge content after unpublish, but prior XP persists.

### Challenge XP Modification After Users Solved

Rules:

- Prior awarded XP is not retroactively changed in MVP.
- Existing `xp_history` and `user_xp` totals remain unchanged.
- See Section 9 for modification policy (MVP disallow rule).

## 9. XP Modification Policy

### Core Policy (MVP)

- Challenge `xp_reward` must be treated as immutable after publish for MVP fairness and auditability.

### Allowed Changes

- Challenge XP may be changed before first publish.
- Challenge XP may be changed while unpublished if no user has received XP from that challenge.

### Disallowed Changes (MVP)

- Changing `xp_reward` for a challenge after any user has received XP for it
- Retroactive recalculation of existing user XP totals due to challenge XP changes
- Bulk re-scoring operations

### If XP Value Is Changed in Violation of Policy (Operational Error)

Required response:

- Treat as an incident
- Stop further inconsistent changes
- Review affected `xp_history` and `user_xp`
- Apply documented correction procedure only if explicitly approved

MVP default retroactive behavior:

- No automatic retroactive adjustment
- Preserve existing ledger and totals unless an approved correction process is executed

## 10. Anti-Abuse Controls

### Rate Limit Submission Endpoint

- The challenge submission endpoint must enforce rate limiting.
- Rate limiting applies regardless of whether the submitted flag is correct or incorrect.
- Rate-limited attempts should be detectable and logged.

### Track Excessive Incorrect Attempts

- Incorrect submissions must be logged with user/challenge/time context.
- Repeated failures for the same user/challenge must be detectable.
- Repeated failures across multiple challenges should also be reviewable.

### Detect Suspicious Rapid Solves

MVP detection goals:

- unusually high solve velocity by a single account
- rapid sequence of correct solves inconsistent with normal progression
- repeated solve attempts across many challenges in short intervals

MVP action model:

- detection and logging are mandatory
- automated account suspension is not required for MVP
- manual admin review path is sufficient

### Admin Review Mechanism

- Suspicious XP patterns must be reviewable using:
  - challenge attempts
  - XP history
  - admin logs (if administrative actions are involved)
- Review outcome and any emergency correction must be documented.

## 11. Auditability

### Every XP Event Logged

- Every XP award must create an `xp_history` event.
- No hidden XP changes are allowed.
- `xp_history` entries must reference the causal context (challenge and source attempt) for challenge solves.

### Immutable XP Ledger

- `xp_history` is append-only in normal operations.
- Corrections (if ever needed) are new events, not edits to prior events.
- Deleting XP history rows in production is prohibited except disaster recovery procedures.

### Ability to Reconstruct Total From History

Required audit capability:

- Recompute each user’s expected total XP from `xp_history`
- Compare computed total against `user_xp.total_xp`
- Compare number of solve events against `user_xp.solved_challenges_count`
- Validate tie-break timestamp against latest award event that produced current total

This reconstruction is an audit/reconciliation procedure, not a runtime request path.

### Integrity Validation Method (MVP)

Define a repeatable reconciliation procedure that:

1. Scans `xp_history` by user in award order.
2. Recomputes cumulative balance.
3. Verifies each `balance_after` matches recomputed cumulative balance.
4. Verifies one `challenge_solve` event per user/challenge.
5. Verifies `user_xp` aggregate matches reconstructed totals/counts/tie-break timestamp.
6. Flags mismatches for manual investigation and incident handling.

## 12. Testing Requirements for XP System

### Objective

- Validate XP correctness, atomicity, duplicate prevention, leaderboard propagation, and auditability before MVP release.

### Required Test Scenarios

- Single solve XP test:
  - First correct solve grants exactly configured XP.
- Duplicate submission test:
  - Repeated correct submission returns no additional XP.
- Concurrent submission test:
  - Parallel correct submissions result in one XP award only.
- Transaction rollback test:
  - Simulated failure during XP transaction leaves no partial XP/completion state.
- Leaderboard update validation:
  - Leaderboard reflects updated total XP after successful award commit.
- XP history creation test:
  - XP award creates one immutable ledger entry with correct references.
- Reconciliation test:
  - Aggregate `user_xp` matches recomputed totals from `xp_history`.

### Expected Outcome

- All critical rules are enforced under normal, duplicate, and race conditions.
- XP and leaderboard state remain consistent across failures and retries.
- Audit reconciliation succeeds with no mismatches in clean test runs.

### Failure Conditions

- Duplicate XP awarded
- XP history missing for awarded XP
- Partial transaction state visible after failure
- Leaderboard rank derived from stale/untrusted data
- Reconciliation mismatch between `user_xp` and `xp_history`

## 13. Future Expansion (Post-MVP)

These items are explicitly out of MVP scope but should not be blocked by the MVP XP model.

### Dynamic XP Scaling

- Challenge XP values that vary based on difficulty solves or solve counts
- Requires new scoring policy versioning and historical scoring snapshots

### Team XP

- Shared team completion markers
- Team aggregate and member attribution rules
- Team leaderboard integration

### Seasonal Reset

- Season-scoped XP totals and archived historical leaderboards
- Reset policy without destroying historical XP audit data

### Achievement-Based Bonus XP

- Non-challenge XP events
- Bonus event categories and anti-abuse rules
- Expanded tie-break semantics

### Time-Based Scoring

- Time-weighted scoring or decay
- Additional timestamp and policy complexity
- Reconciliation rules for non-monotonic totals

## Implementation Governance Rule

- Any change to XP award semantics, duplicate prevention behavior, tie-break logic, or correction policy must update this document before the change is considered complete.
