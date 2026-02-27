# ZeroTrace CTF - TEST_PLAN (MVP)

## Scope

This document defines the pre-implementation test strategy for the ZeroTrace CTF MVP.

In scope:

- Authentication
- Role-based access
- Dashboard
- Track listing (Linux, Networking, Crypto only)
- Challenge engine (static challenges)
- Flag submission
- XP system
- Leaderboard
- Admin challenge management
- Admin logs

Out of scope for MVP test planning:

- Docker labs
- Advanced cloud deployment behavior
- SOC ingestion or SIEM integration testing
- Dynamic lab orchestration

## Test Plan Goals

- Define test coverage before implementation begins
- Lock critical security validations early
- Prevent ambiguous acceptance criteria
- Ensure deterministic, repeatable, audit-ready testing

## 1. Testing Philosophy

### Security-First Testing

- Security controls are treated as primary functionality, not secondary checks.
- Authentication, authorization, flag confidentiality, XP integrity, and audit logging are tested as release blockers.
- Negative-path and abuse-path testing are required for all protected endpoints.

### Fail-Safe Assumptions

- If a security-critical dependency fails (for example, attempt logging, admin audit logging, XP transaction integrity), the operation should fail safely rather than proceed partially.
- Tests will validate deny-by-default behavior when state is missing, invalid, or inconsistent.
- Ambiguous authorization outcomes are treated as failures.

### Deterministic Behavior

- Test results must not depend on execution order unless explicitly declared.
- All ranking, XP, and challenge-order assertions must be deterministic.
- Repeated runs with the same seed data must produce the same functional outcomes.

### No Hidden State Assumptions

- Tests must declare setup, preconditions, and expected initial data state.
- Tests must not assume data created by other test cases unless part of a controlled suite setup.
- Session state, XP state, and publication state are always explicitly asserted before action steps.

### Release Gating Principle (MVP)

- Critical security and integrity failures block release:
  - XP duplicate reward bug
  - admin route access bypass
  - hidden challenge exposure
  - flag leakage
  - missing incorrect-attempt logging

## 2. Test Categories

### 2.1 Unit Testing

#### Objective

- Validate isolated domain logic deterministically before integration.

#### Test Scenarios

- Validation rules for auth payloads, challenge payloads, and role-change requests
- Flag input normalization behavior
- XP reward calculation and tie-break timestamp logic
- RBAC permission evaluation logic
- Leaderboard sorting comparator logic
- Error mapping consistency (internal failure -> safe public error code/message)

#### Expected Outcome

- Pure business rules behave predictably across valid, invalid, and edge inputs.
- No security-critical rule depends on UI behavior or hidden state.

#### Failure Conditions

- Logic accepts invalid input or rejects valid input incorrectly.
- XP or leaderboard ordering rules behave non-deterministically.
- RBAC helper permits unauthorized action.

#### Risk Level

High

### 2.2 Integration Testing

#### Objective

- Validate multi-step workflows across API, persistence, and authorization boundaries.

#### Test Scenarios

- Registration -> login -> `GET /auth/me` -> dashboard data composition (`/tracks`, `/users/me/xp`)
- Challenge solve workflow: submission -> attempt log -> XP history -> user XP -> leaderboard
- Admin challenge creation/edit/publish workflow with audit log generation
- Role promotion workflow and authorization effect on next authenticated state
- Unpublish challenge and verify player access denial across list/detail/submit paths

#### Expected Outcome

- Cross-component flows succeed atomically and produce consistent state.
- Security checks remain enforced across workflow transitions.

#### Failure Conditions

- Partial writes occur (for example, XP history created without XP aggregate update).
- Admin action succeeds without audit log.
- Hidden/unpublished challenge remains reachable in player flows after unpublish.

#### Risk Level

High

### 2.3 API Contract Testing

#### Objective

- Enforce request/response contract stability and prevent schema drift from `API_CONTRACT.md`.

#### Test Scenarios

- Response envelope shape validation (`success`, `data`, `error`) for all endpoints
- Required error object fields (`code`, `message`) on error responses
- Required status codes for auth failures, forbidden admin access, not-found behavior
- Hidden challenge unauthorized access returns safe `404` behavior
- Leaderboard pagination contract and metadata fields
- No sensitive fields returned (hashed flags, password hashes, internal secrets)

#### Expected Outcome

- All endpoints match documented request/response and error contracts.
- No undocumented fields are relied on for core behaviors.

#### Failure Conditions

- Contract mismatch in fields, types, status codes, or error codes
- Sensitive data appears in a response payload
- Unauthorized challenge access returns revealing error detail

#### Risk Level

High

### 2.4 Security Testing

#### Objective

- Validate resilience against common and MVP-relevant attack classes.

#### Test Scenarios

- Authentication abuse (credential guessing, enumeration resistance)
- JWT tampering and invalid token handling
- Injection attempts (SQL injection style payloads, XSS payloads in content fields)
- IDOR/direct object reference attempts on challenge and admin endpoints
- Mass assignment attempts on admin challenge update and role endpoints
- Timing-difference analysis for flag validation outcomes

#### Expected Outcome

- Malicious inputs are safely rejected without sensitive leakage.
- Authorization and integrity protections remain effective under hostile inputs.

#### Failure Conditions

- Privilege escalation, hidden content disclosure, or XP integrity compromise
- Validation errors leak internal details
- Timing behavior reveals useful signal for flag inference

#### Risk Level

High

### 2.5 Edge Case Testing

#### Objective

- Validate predictable system behavior under unusual but realistic inputs and state transitions.

#### Test Scenarios

- Empty/very long/special-character submissions
- Expired session during action
- Deleted/unpublished challenge referenced from stale UI state
- Network interruption during submission
- Simultaneous login from multiple devices

#### Expected Outcome

- System remains stable, secure, and deterministic with safe error responses.

#### Failure Conditions

- Inconsistent state, unhandled errors, or security checks bypassed by malformed edge inputs

#### Risk Level

Medium

### 2.6 Abuse Testing

#### Objective

- Validate detection and throttling under hostile high-frequency behavior.

#### Test Scenarios

- High-rate incorrect submissions
- Cooldown enforcement after repeated failures
- Concurrent submissions racing for same challenge
- Automated script behavior simulation across accounts/challenges

#### Expected Outcome

- Abuse is rate-limited, logged, and detectable without breaking normal use.

#### Failure Conditions

- No throttling under abuse
- No attempt logs for blocked/incorrect submissions
- Duplicate XP under concurrent abuse conditions

#### Risk Level

High

### 2.7 Regression Testing

#### Objective

- Prevent previously fixed defects or protected behaviors from reappearing.

#### Test Scenarios

- Re-run critical auth/RBAC/flag/XP/leaderboard/admin log suites after any related change
- Dashboard composition regression (`/auth/me`, `/tracks`, `/users/me/xp`) after auth or XP changes
- Unpublished challenge access denial regression after challenge/admin changes
- Duplicate XP prevention regression after submission or XP logic changes

#### Expected Outcome

- Critical behaviors remain stable across iterative development.

#### Failure Conditions

- Previously passing critical behavior fails after unrelated or related changes.

#### Risk Level

High

## 3. Authentication Test Cases

### Objective

- Validate secure and deterministic account lifecycle behavior (register, login, logout, session invalidation, disabled-account handling).

### Test Scenarios

- `AUTH-01` Register valid user
- `AUTH-02` Register duplicate email (existing normalized email)
- `AUTH-03` Register invalid email format
- `AUTH-04` Register weak password rejection
- `AUTH-05` Login valid credentials
- `AUTH-06` Login invalid password
- `AUTH-07` JWT/session expiration handling on protected endpoint access
- `AUTH-08` Invalid token access attempt on protected endpoint
- `AUTH-09` Disabled/inactive account login behavior
- `AUTH-10` Logout valid session
- `AUTH-11` Logout expired/invalid session (idempotent client outcome)
- `AUTH-12` `GET /auth/me` returns correct user + roles for valid session

### Expected Outcome

- Valid registration/login/logout flows succeed.
- Invalid auth inputs fail safely with generic errors.
- Expired or invalid sessions cannot access protected endpoints.
- Inactive accounts cannot authenticate.
- No credential secrets are exposed in logs or responses.

### Failure Conditions

- Duplicate accounts created for same email/username.
- Login succeeds with invalid password.
- Protected endpoint accepts expired/invalid token.
- Inactive account receives active session.
- Detailed auth error leaks user existence or internal verification details.

### Risk Level

High

## 4. Authorization Test Cases

### Objective

- Verify strict server-side enforcement of player/admin permissions and challenge visibility rules.

### Test Scenarios

- `AUTHZ-01` Player accesses admin route (`/admin/*`) with valid player token
- `AUTHZ-02` Admin accesses player routes (allowed behavior) and receives valid responses
- `AUTHZ-03` Player attempts direct access to unpublished challenge detail
- `AUTHZ-04` Player attempts submission to unpublished challenge endpoint
- `AUTHZ-05` Player accesses deleted/missing challenge
- `AUTHZ-06` Role promotion: player -> admin, verify new access on next auth refresh/login
- `AUTHZ-07` Role demotion/removal of admin role, verify admin access revoked on next auth refresh/login
- `AUTHZ-08` Admin route access with missing role assignment (deny by default)

### Expected Outcome

- Admin-only endpoints reject player tokens.
- Hidden/unpublished challenges are not accessible to players and do not reveal existence.
- Deleted/missing challenges return safe not-found behavior.
- Role changes alter access only after expected re-auth/refresh boundary.

### Failure Conditions

- Player successfully executes admin action.
- Unpublished challenge is exposed or confirmed to unauthorized player.
- Authorization decisions rely only on UI state and can be bypassed.
- Demoted admin retains privileged API access unexpectedly.

### Risk Level

High

## 5. Challenge Engine Test Cases

### Objective

- Validate challenge retrieval and submission behavior for static challenges, including correctness, normalization handling, and abuse-sensitive flows.

### Test Scenarios

- `CHAL-01` View published challenge detail
- `CHAL-02` Submit correct flag
- `CHAL-03` Submit incorrect flag
- `CHAL-04` Submit malformed flag (empty/invalid shape)
- `CHAL-05` Double submission test (same client double-click / rapid repeat)
- `CHAL-06` Rapid repeated submissions to same challenge
- `CHAL-07` Case sensitivity handling (correct case vs incorrect case)
- `CHAL-08` Whitespace trimming behavior (leading/trailing whitespace)
- `CHAL-09` Challenge becomes unpublished between page load and submit
- `CHAL-10` Deleted challenge submission attempt from stale page

### Expected Outcome

- Published challenge content loads correctly with safe metadata only.
- Correct submission triggers success path.
- Incorrect and malformed submissions are rejected and logged.
- Case sensitivity and normalization follow defined platform policy consistently.
- Unpublished/deleted challenge transitions are enforced at submit time.

### Failure Conditions

- Challenge response exposes hidden/admin-only metadata (including flags).
- Incorrect submission produces XP or completion state.
- Normalization behavior is inconsistent across attempts/storage/validation.
- Stale client state bypasses current publication/access checks.

### Risk Level

High

## 6. XP System Tests

### Objective

- Validate XP allocation integrity, history creation, duplicate-prevention, and leaderboard propagation.

### Test Scenarios

- `XP-01` XP added correctly on first valid solve (matches challenge XP reward)
- `XP-02` XP not added twice for same challenge/user
- `XP-03` XP history entry created for successful solve
- `XP-04` Race condition double-submit prevention (parallel correct submissions)
- `XP-05` XP integrity after service restart (persisted totals/history remain consistent)
- `XP-06` Leaderboard update visible after successful submission
- `XP-07` XP not awarded on incorrect submission
- `XP-08` XP not awarded when challenge is already solved (`already completed` path)
- `XP-09` XP transaction rollback behavior on induced write failure (no partial state)

### Expected Outcome

- XP is awarded exactly once per user/challenge.
- XP history and XP totals remain consistent and auditable.
- Concurrent submissions do not create duplicate XP.
- Leaderboard reflects trusted, committed XP state after reward completion.

### Failure Conditions

- Duplicate XP awarded for same challenge.
- XP history and aggregate totals diverge.
- Race condition creates two reward events.
- Restart causes XP totals/history mismatch or data loss.

### Risk Level

High

## 7. Leaderboard Tests

### Objective

- Validate ranking correctness, deterministic tie-break behavior, pagination consistency, and visibility policy.

### Test Scenarios

- `LB-01` Correct ranking order by total XP descending
- `LB-02` Tie-breaker behavior (earliest completion timestamp ranks higher)
- `LB-03` Pagination (page boundaries, consistent ordering, no duplicate rows across pages in stable dataset)
- `LB-04` Hidden/inactive users exclusion (if MVP policy excludes inactive users)
- `LB-05` Leaderboard refresh after XP update
- `LB-06` Page beyond available range returns safe empty/valid response

### Expected Outcome

- Leaderboard ordering is deterministic and consistent with trusted XP data.
- Ties are resolved using defined tie-break logic.
- Pagination metadata and page contents are correct.
- Hidden/inactive user policy is applied consistently.

### Failure Conditions

- Ranking derived from stale or untrusted XP data.
- Tie-break ordering is inconsistent between requests.
- Pagination duplicates or omits rows in stable conditions.
- Inactive users appear unexpectedly when policy excludes them.

### Risk Level

Medium

## 8. Admin Panel Tests

### Objective

- Validate all privileged challenge-management and role-management workflows, including audit logging and non-admin rejection.

### Test Scenarios

- `ADMIN-01` Create challenge (valid draft)
- `ADMIN-02` Edit challenge metadata (title/description/difficulty/xp/order)
- `ADMIN-03` Publish challenge (with valid active flag and valid metadata)
- `ADMIN-04` Unpublish challenge (visibility removed from player flows)
- `ADMIN-05` Change user role (promote player to admin)
- `ADMIN-06` Admin log creation for challenge create/edit/publish/unpublish
- `ADMIN-07` Admin log creation for role change
- `ADMIN-08` Prevent non-admin access to all admin endpoints
- `ADMIN-09` Publish blocked when publish preconditions fail (missing flag/invalid metadata)
- `ADMIN-10` Concurrent admin edits (deterministic outcome and audit logging)

### Expected Outcome

- Admin workflows succeed only with valid admin authorization and valid input.
- All privileged actions create audit logs.
- Player access reflects publish/unpublish state immediately after commit.
- Non-admin tokens are rejected from admin endpoints.

### Failure Conditions

- Admin action succeeds without audit log.
- Non-admin can access or mutate admin resources.
- Publish succeeds without required preconditions.
- Challenge visibility state and admin action result diverge.

### Risk Level

High

## 9. Security Testing

### Objective

- Validate resistance to common attack techniques against MVP endpoints and data paths.

### Test Scenarios

- `SEC-01` Brute force flag attempts (single user/challenge)
- `SEC-02` SQL injection attempts in auth, challenge, and admin inputs
- `SEC-03` XSS payload in challenge description (admin input -> player output path)
- `SEC-04` JWT tampering (modified signature/claims)
- `SEC-05` Direct object reference attempt (challenge IDs, admin resource IDs)
- `SEC-06` Mass assignment test on admin challenge and role endpoints
- `SEC-07` Enumeration attack test (account existence and unpublished challenge existence inference)
- `SEC-08` Timing leakage analysis for flag validation (correct vs incorrect vs hidden access)
- `SEC-09` Sensitive response field audit (no hashes/secrets/passwords/tokens beyond intended auth token field)

### Expected Outcome

- Malicious payloads are rejected safely.
- XSS content is stored/handled without executing in player-facing contexts.
- Tampered JWTs are rejected generically.
- IDOR and mass assignment attempts fail.
- Enumeration and timing signals do not provide useful attack advantage.

### Failure Conditions

- Any privilege escalation, hidden challenge disclosure, or XP integrity compromise.
- Injection payload is executed or alters unauthorized data.
- Token tampering grants access.
- Timing behavior materially distinguishes valid/invalid flag paths.

### Risk Level

High

## 10. Abuse Testing

### Objective

- Validate platform behavior under hostile automated usage and high-frequency submission patterns.

### Test Scenarios

- `ABUSE-01` High-frequency submission attempts from one user to one challenge
- `ABUSE-02` Concurrent submission race on correct flag (multiple parallel requests)
- `ABUSE-03` Attempt flooding detection (many incorrect attempts across challenges)
- `ABUSE-04` Automated script simulation (repeated auth + challenge enumeration + submissions)
- `ABUSE-05` Cooldown enforcement after repeated failures (if enabled)
- `ABUSE-06` Blocked attempt logging validation

### Expected Outcome

- Submission endpoint enforces rate limiting and/or cooldown policy.
- Abuse attempts are detectable via logs.
- Concurrent abuse does not break XP integrity.
- System degrades safely (throttle/deny) rather than failing open.

### Failure Conditions

- No throttle/cooldown under obvious abuse.
- Duplicate XP awarded during abuse race.
- Blocked/incorrect attempts are not logged.
- Service returns unstable or revealing errors under abuse.

### Risk Level

High

## 11. Edge Case Testing

### Objective

- Validate secure and predictable behavior for unusual inputs, transport issues, and concurrent user/session conditions.

### Test Scenarios

- `EDGE-01` Empty submission to flag endpoint
- `EDGE-02` Very long flag submission (length limit enforcement)
- `EDGE-03` Special character injection in flag and auth fields
- `EDGE-04` Network interruption during submit (client timeout / retry behavior)
- `EDGE-05` Simultaneous login from two devices for same user
- `EDGE-06` Expired session during challenge submission
- `EDGE-07` Invalid challenge ID format
- `EDGE-08` Stale challenge page after unpublish/delete
- `EDGE-09` Duplicate admin action request retry (publish/unpublish/role change)

### Expected Outcome

- Inputs outside policy are rejected safely.
- Retries do not corrupt XP or challenge state.
- Multi-device sessions behave within defined auth/session policy.
- Invalid IDs and stale resources return safe non-revealing responses.

### Failure Conditions

- Retry causes duplicate reward or duplicate admin mutation.
- Invalid IDs leak existence or internal parsing detail.
- Network interruption leaves inconsistent visible state without recoverable re-fetch behavior.

### Risk Level

Medium

## 12. Logging & Monitoring Validation

### Objective

- Verify that security-relevant and privileged actions generate required logs and support manual abuse detection in MVP.

### Test Scenarios

- `LOG-01` Failed login logged
- `LOG-02` Failed flag attempt logged
- `LOG-03` Blocked/rate-limited/cooldown submission logged
- `LOG-04` Admin action logged (create/edit/publish/unpublish challenge)
- `LOG-05` Admin role change logged
- `LOG-06` Suspicious activity detection test (pattern review using generated log events)
- `LOG-07` Sensitive data redaction validation (no plaintext flags/passwords/tokens in logs)
- `LOG-08` Audit-critical failure behavior (admin action or submission fails if required log write fails, per policy)

### Expected Outcome

- Required logs are created with correct actor/action/outcome/time context.
- Suspicious activity patterns are detectable from generated logs.
- Sensitive values are not present in operational or admin logs.

### Failure Conditions

- Missing logs for failed logins, failed submissions, or admin actions.
- Logs contain secrets or sensitive raw payloads.
- Audit-critical operation succeeds without required log entry.

### Risk Level

High

## 13. Performance Testing (Basic MVP Level)

### Objective

- Establish minimum performance and stability expectations under MVP traffic patterns, including burst submission behavior.

### Test Scenarios

- `PERF-01` Response time under normal load (mixed read traffic: auth/me, tracks, challenge detail, leaderboard)
- `PERF-02` Response time under burst flag submissions (including rate-limited responses)
- `PERF-03` Leaderboard query performance with paginated access and realistic user counts
- `PERF-04` Post-solve path latency (submission -> XP commit -> immediate leaderboard fetch)
- `PERF-05` Admin log query performance with filters and pagination (basic admin review use case)

### Expected Outcome

- Normal user-facing endpoints respond within defined MVP latency targets.
- Burst submission traffic is throttled safely without widespread errors.
- Leaderboard queries remain performant with pagination and deterministic ordering.
- Performance degradation under abuse remains controlled (prefer `429` / safe denial over internal failures).

### Failure Conditions

- Submission bursts cause repeated internal errors or bypass throttling.
- Leaderboard latency becomes unstable under moderate load.
- Post-solve path latency prevents practical immediate leaderboard refresh behavior.

### Risk Level

Medium

### MVP Baseline Targets (Planning Targets)

- Normal authenticated read endpoints (`/auth/me`, `/tracks`, `/challenges/{id}`, `/users/me/xp`, `/leaderboard`):
  - p95 response time: <= 500 ms under baseline MVP load
- Flag submission endpoint (`/challenges/{id}/submit`):
  - p95 response time: <= 800 ms for non-abusive valid/invalid requests
  - Under burst abuse, endpoint should prioritize throttled responses over internal errors
- Admin list endpoints (`/admin/logs` basic filters):
  - p95 response time: <= 800 ms under expected MVP admin usage

Note:

- These are initial planning targets and may be tightened once real workload measurements exist.

## 14. Test Data Strategy

### Objective

- Define deterministic, isolated, and security-relevant test data for all MVP test categories.

### Test Scenarios

- `DATA-01` Seed users: baseline player accounts, inactive user, and edge-case usernames/emails
- `DATA-02` Seed challenges: published/unpublished/deleted-equivalent test states across Linux/Networking/Crypto
- `DATA-03` Seed valid flags (hashed at rest in runtime state) and known test flags for correct/incorrect cases
- `DATA-04` Seed XP states: zero XP users, tied XP users, users with solved history
- `DATA-05` Seed admin accounts and role-change targets
- `DATA-06` Seed admin logs and attempt logs for pagination/filter validation
- `DATA-07` Isolated test environment assumptions (clean reset between suites, deterministic timestamps where needed)
- `DATA-08` Corrupted/inconsistent fixture simulation for fail-safe behavior tests (missing role, unpublished challenge with no valid flag, etc.)

### Expected Outcome

- Test suites run against known, reproducible data states.
- Data supports positive, negative, edge, abuse, and regression testing without cross-test contamination.
- Ranking, XP, and visibility assertions are reproducible.

### Failure Conditions

- Tests depend on uncontrolled or shared mutable state.
- Seed data leaks hidden assumptions into later suites.
- Data setup cannot reproduce race/abuse/security scenarios reliably.

### Risk Level

High

### Seed Data Minimum Set (MVP)

- Users:
  - `player_active_01`
  - `player_active_02`
  - `player_inactive_01`
  - `admin_active_01`
  - `admin_active_02` (for concurrent admin action tests)
- Tracks:
  - `Linux`
  - `Networking`
  - `Crypto`
- Challenges:
  - Published and unpublished examples in each track
  - At least one challenge per difficulty (`easy`, `medium`, `hard`)
  - At least one challenge with attachment metadata
  - At least one challenge already solved by a seeded user
- XP states:
  - Zero XP user
  - Users tied on XP with different tie-break timestamps
  - User with multiple XP history entries
- Logs:
  - Admin actions across create/edit/publish/unpublish/role change
  - Failed login and failed flag attempts for detection tests

## 15. Critical Rules Validation Matrix

This section maps MVP non-negotiable rules to mandatory test coverage.

| Critical Rule | Primary Test Sections | Minimum Test IDs |
|---|---|---|
| XP cannot be granted twice | XP System Tests, Abuse Testing, Edge Case Testing | `XP-02`, `XP-04`, `ABUSE-02`, `EDGE-04` |
| Flag hash comparison must not leak timing information | Security Testing, Challenge Engine Test Cases | `SEC-08`, `CHAL-02`, `CHAL-03` |
| Admin-only endpoints must reject player tokens | Authorization, Admin Panel Tests | `AUTHZ-01`, `ADMIN-08` |
| Invalid challenge ID must not leak existence | Authorization, Edge Case Testing, API Contract Testing | `AUTHZ-05`, `EDGE-07` |
| Submission endpoint must enforce rate limiting | Challenge Engine, Abuse Testing, Security Testing | `CHAL-06`, `ABUSE-01`, `ABUSE-05`, `SEC-01` |
| Leaderboard must reflect trusted XP only | XP System Tests, Leaderboard Tests, API Contract Testing | `XP-06`, `LB-01`, `LB-02` |

## 16. Test Execution Strategy (Pre-Implementation Planning)

### Test Layers by Development Stage

- During feature development:
  - Unit tests for domain logic and validation
  - API contract tests for new/changed endpoints
- During integration milestones:
  - Integration tests for auth, submissions, XP, leaderboard, admin workflows
- Before MVP release candidate:
  - Full regression suite
  - Security test pass
  - Abuse test pass
  - Performance baseline pass

### Entry Criteria for MVP System Testing

- API contract finalized (`API_CONTRACT.md`)
- Feature scope finalized (`FEATURES.md`)
- Security rules finalized (`SECURITY_MODEL.md`)
- Seed data strategy implemented for isolated environments

### Exit Criteria for MVP Release Readiness (QA)

- No open High-risk test failures in:
  - Authentication
  - Authorization
  - Flag submission
  - XP integrity
  - Admin access control
  - Admin logs
- Critical rules validation matrix fully passing
- Performance baseline meets MVP targets or has documented accepted deviations with sign-off
- Regression suite green on final release candidate build

## 17. Non-MVP Test Exclusions (Explicit)

Not planned for MVP:

- Docker lab runtime isolation tests
- VM/sandbox breakout tests
- Cloud tenancy isolation tests
- SOC ingestion and alert pipeline tests
- Payment, subscription, or licensing tests
- Mobile application tests
- Team/multiplayer synchronization tests
