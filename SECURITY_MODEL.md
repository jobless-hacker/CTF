# ZeroTrace CTF - SECURITY_MODEL (MVP)

## Scope

This document defines the security model for the ZeroTrace CTF MVP only.

In scope:

- Authentication
- Role-based access (`admin`, `player`)
- Dashboard
- Static challenge engine
- Flag submission system
- XP system
- Leaderboard
- Admin challenge management
- Admin logs

Out of scope for MVP security model (future phases):

- Docker lab isolation
- Cloud lab isolation
- External integrations
- Dynamic lab orchestration
- SOC ingestion pipelines

## Critical Behavioral Rules (Non-Negotiable)

- Flags must never be exposed in API responses.
- API must not reveal whether a challenge exists if the requester is unauthorized to access it.
- All privilege checks must happen server-side.
- XP allocation must be atomic.
- Leaderboard must derive from trusted XP data only.
- Incorrect flag attempts must not leak format hints.
- Admin privileges must not be assignable by regular users.

## 1. Security Philosophy

### Zero Trust Assumptions

- No client input is trusted.
- No frontend state is trusted for authentication or authorization decisions.
- Authenticated users are not trusted simply because they are authenticated.
- Admin users are treated as high-risk actors with elevated capability and audit requirements.
- Internal network context is not treated as trusted. MVP security controls must remain effective regardless of request origin.

### Least Privilege Principle

- `player` role receives only the minimum access needed to view published content, submit flags, and view own progression plus leaderboard.
- `admin` role receives content-management access only; admin privileges do not imply unrestricted access to secrets or raw submitted data unless explicitly required.
- Service components should access only the data needed for the operation being performed.
- Sensitive operations (role changes, challenge publish/unpublish, flag updates) require explicit privileged paths and audit logging.

### Explicit Trust Boundaries

Trust boundaries for MVP:

- `Unauthenticated Client` -> `Public API Endpoints`
- `Authenticated Client` -> `Protected API Endpoints`
- `Admin Client` -> `Admin API Endpoints`
- `API Layer` -> `Persistence Layer` (credentials, flags, attempts, XP, logs)
- `Admin Content Input` -> `Player Content Output` (challenge descriptions and attachments)

Security implication:

- Every boundary crossing requires validation, authorization checks, and output filtering.

## 2. Threat Model Overview

### Threat Actors

#### External Attacker (Unauthenticated)

Likely goals:

- Enumerate accounts
- Enumerate challenges or unpublished content
- Abuse authentication endpoints
- Discover admin routes or weak authorization
- Cause service degradation through request flooding

Key attack patterns:

- Credential stuffing
- Registration abuse
- Route enumeration
- Challenge ID/slug probing
- Rate-limit bypass attempts

#### Internal Attacker (Malicious User / Player)

Likely goals:

- Access unpublished challenges
- Extract flags
- Gain XP without valid solves
- Exploit race conditions for double XP
- Abuse submission endpoint for automation
- Escalate privileges to admin

Key attack patterns:

- Direct API calls bypassing UI controls
- Parallel submissions
- Parameter tampering
- Hidden challenge probing
- Attempt replay after successful solve

#### Malicious Admin Scenario

Assumption:

- Admin is privileged but not automatically trusted to avoid abuse or mistakes.

Likely risks:

- Publishing hidden content prematurely
- Modifying XP/difficulty in ways that affect platform fairness
- Improper role assignments
- Sensitive data exposure via logs or admin tooling misuse

Required response:

- Strong audit logging
- Redacted logging and admin views
- Explicit authorization checks even in admin flows

#### Automated Bot Attacks

Likely goals:

- Brute-force flag submissions
- Credential attacks
- High-volume endpoint probing
- Automated leaderboard scraping or API abuse

Key characteristics:

- High request rate
- Repeated patterns
- Multi-account usage
- Distributed sources (where possible)

#### Race Condition Exploitation

Likely goals:

- Double XP allocation
- Duplicate solve credit
- Inconsistent leaderboard state

Primary target:

- Correct flag submission and XP award path

#### Enumeration Attacks

Likely goals:

- Discover valid users
- Discover unpublished challenge identifiers
- Infer flag format/validation behavior
- Infer hidden platform state from error messages or timing differences

### Threat Priorities (MVP)

Highest-priority protections for MVP:

- Authentication abuse resistance
- Authorization correctness (especially admin and unpublished challenge protection)
- Flag confidentiality
- XP integrity and race-condition safety
- Submission abuse detection and throttling
- Auditability of privileged actions

## 3. Asset Identification

| Asset | Security Priority | Primary Risk | Security Objective |
|---|---|---|---|
| User credentials | High | Account takeover | Confidentiality and strong verification |
| Session/auth state | High | Unauthorized access | Integrity and expiration enforcement |
| Challenge flags | High | Solve bypass / platform integrity loss | Confidentiality |
| XP data (`user_xp`, `xp_history`) | High | Ranking manipulation | Integrity and non-repudiation |
| Admin privileges / role assignments | High | Platform compromise | Integrity and strict authorization |
| Challenge content (published + unpublished) | Medium/High | Premature disclosure | Access control and publication-state integrity |
| Leaderboard data | Medium/High | Ranking manipulation / trust loss | Integrity and deterministic ordering |
| Challenge attempts log | High | Abuse detection blind spots | Integrity, retention, confidentiality of sensitive submissions |
| Admin logs | High | Loss of audit trail | Integrity and append-only behavior |

## 4. Attack Surface Analysis

### Authentication Endpoints

Attack types:

- Credential stuffing
- Password guessing
- Account enumeration
- Registration abuse
- Session token replay
- Invalid token flooding

Security risks:

- Unauthorized access
- User enumeration
- Service degradation

Required mitigations:

- Rate limiting on registration and login
- Generic authentication failure messages
- Secure password hashing
- Session expiration enforcement
- Invalid token handling with safe logout/reauth behavior
- Failed login logging and anomaly review

### Flag Submission Endpoint

Attack types:

- Brute-force submissions
- Timing attacks against validation
- Replay after solve
- Concurrent double submit for XP duplication
- Hidden challenge probing through submission behavior

Security risks:

- Flag disclosure
- XP manipulation
- High-volume abuse

Required mitigations:

- Hash-based flag storage (no plaintext)
- Constant-time comparison behavior
- Rate limiting and cooldown
- Attempt logging (including blocked attempts)
- Duplicate solve / duplicate XP prevention
- Uniform error responses and no validation detail leakage
- Authorization and publication checks before validation

### Admin Endpoints

Attack types:

- Privilege escalation
- Direct endpoint access by players
- CSRF against admin actions (if cookie-based session continuation is used)
- Parameter tampering on role changes and challenge publish actions

Security risks:

- Content tampering
- Privilege abuse
- Audit gaps

Required mitigations:

- Backend-admin role checks on every admin endpoint
- Default-deny authorization
- Admin action audit logging
- Input validation on all admin mutations
- Session validity checks on every admin request
- CSRF protection where applicable

### Track Access and Challenge Access

Attack types:

- Direct URL access to locked/unpublished challenges
- Identifier enumeration (IDs/slugs)
- Access-state probing via response differences

Security risks:

- Premature content disclosure
- Hidden challenge discovery

Required mitigations:

- Publication-state checks server-side
- Track access checks server-side (if unlock rules enabled)
- Safe denial responses for unauthorized challenge access (prefer not-found behavior)
- No hidden content metadata in player responses

### Leaderboard Queries

Attack types:

- Ranking manipulation attempts via parameter abuse
- Data scraping and enumeration
- Exposure of sensitive fields through over-broad responses

Security risks:

- Integrity loss
- Privacy leaks

Required mitigations:

- Leaderboard data sourced only from trusted XP aggregate/history outputs
- Strict response field allowlist
- Pagination limits
- Auth checks (if leaderboard is protected in MVP)

## 5. Authentication Security Model

### Password Hashing Expectations

- Passwords must be stored as strong, slow, salted password hashes.
- Plaintext passwords must never be stored, logged, or returned.
- Password verification must happen server-side only.
- Hashing parameters should be set for meaningful offline attack resistance and reviewed over time.
- Optional secret pepper may be used as an additional defense, stored separately from database data.

### Account Enumeration Prevention

- Login failures should use generic responses that do not reveal whether the username/email exists.
- Registration responses should avoid disclosing unnecessary identity-state detail.
- Timing and response differences between "user not found" and "wrong password" paths should be minimized.
- Rate-limit and monitor repeated login attempts against many usernames/emails.

### Rate Limiting

- Apply rate limits to registration and login endpoints.
- Rate limiting should consider source-based signals and repeated failures.
- Repeated authentication failures must be logged for detection and review.
- Rate limiting must fail closed enough to preserve safety during abuse spikes.

### Session Expiration

- Session/auth state must have enforced expiration.
- Expired sessions must not access protected endpoints.
- Expired session behavior must be consistent across player and admin flows.
- Expiration handling must redirect or require re-authentication without returning protected data.

### Invalid Token Handling

- Invalid tokens must be treated as authentication failure.
- API responses must not disclose token parsing/verification internals.
- Client auth state should be cleared on invalid/expired token outcomes.
- Repeated invalid token attempts may be logged as suspicious behavior.

## 6. Authorization Model

### Role-Based Access Checks

- Authorization is based on server-side role evaluation (`player`, `admin`).
- All privileged actions require explicit server-side authorization.
- Default behavior for missing/invalid role context is deny access.
- Role changes only take effect after server-recognized session/token refresh or re-authentication.

### Backend Validation Only (Never Trust Frontend)

- Frontend route guards and hidden buttons are UX controls only.
- Backend must independently validate:
  - Authentication
  - Role authorization
  - Resource visibility (published/unpublished)
  - Resource ownership/context where applicable

### Hidden Challenge Protection

- Unpublished challenges must not appear in player listings.
- Players must not access unpublished challenges by direct URL or API probing.
- Unauthorized challenge requests should not confirm existence of hidden challenges.
- Submission endpoint must re-check challenge visibility and access before validation.

### Admin Route Enforcement

- All admin endpoints require server-side `admin` authorization.
- Regular users must not be able to assign roles, publish challenges, or edit content.
- Admin privilege assignment/removal must be restricted to authorized admins only.
- Admin authorization failures must not reveal privileged resource details.

## 7. Flag Security Model

### Flag Storage Rules

- Valid challenge flags must never be stored in plaintext.
- Only hashed representations of normalized flags may be stored.
- Multiple valid flags per challenge may be supported, but all must follow the same storage rule.
- Flag hashes and related metadata are sensitive and must not be exposed to players.

### Flag Validation Rules

- Submitted flags are normalized according to a defined policy before validation.
- Normalization must be consistent and documented (for example, explicit handling of surrounding whitespace).
- Validation must compare against stored hashed flags using constant-time comparison behavior.
- Validation outcomes must not reveal matching internals, partial matches, or expected format hints beyond generic input validity rules.

### Timing Attack Resistance

- Avoid response behavior that materially differs between:
  - challenge access denied
  - incorrect flag
  - already solved
  - hidden challenge
- Validation path should minimize attacker-observable timing differences that could help infer valid flags or hidden resources.
- No per-character or partial match feedback.

### Response and Logging Rules

- API responses must never return flags or flag hashes.
- Incorrect flag responses must be generic.
- Submitted flag values are sensitive and must not be emitted in application logs or admin activity summaries.
- If attempt records retain submitted values for audit, access must be tightly restricted.

## 8. XP Integrity Protection

### Core Integrity Requirements

- XP is server-authoritative.
- XP can only be awarded after a validated correct flag submission on an accessible challenge.
- A user must not receive XP more than once for the same challenge.
- Leaderboard must read from trusted XP data only.

### Prevent Double Reward

- Duplicate solve prevention must exist at both:
  - application logic layer
  - data integrity layer
- If a challenge is already solved by a user, further correct submissions must return "already completed" with no XP award.
- Retry or replay of prior successful submissions must not create additional XP events.

### Prevent Race Condition Double Submit

- Simultaneous correct submissions for the same user/challenge must not result in multiple XP awards.
- Reward path must be race-safe using transactional guarantees and uniqueness constraints.
- One request may win; all others must resolve to a no-additional-reward outcome.

### Atomic Transaction Requirements

- The following must succeed or fail as one unit:
  - successful solve recognition
  - XP history insert
  - XP aggregate update
  - leaderboard-relevant tie-break update
- No partial state is acceptable (for example, XP history written without aggregate update).

### Immutable XP History

- XP history is append-only in normal operations.
- XP corrections (if allowed later) must be explicit events, not silent edits of prior records.
- XP integrity investigations must be possible using history + aggregate reconciliation.

## 9. Brute Force & Abuse Mitigation

### Rate Limiting Flag Submissions

- Apply endpoint rate limits to submission requests.
- Rate limits should consider at least:
  - user identity
  - source signals
  - challenge-specific repetition
- Rate-limited requests should return generic throttling responses.

### Cooldown Mechanism After Repeated Failures

- MVP may enable a cooldown after X failed attempts within a defined time window.
- Cooldown should apply consistently, including to repeated attempts that may later be correct.
- Cooldown decisions should be logged to support abuse investigations.

### Attempt Logging

- All incorrect submissions must be logged.
- Blocked/rate-limited/cooldown submissions should also be logged.
- Attempt logs should capture enough metadata for correlation and review without exposing secrets broadly.
- Attempt logging failure should fail the validation request safely (no silent bypass).

### Detection Strategy for Automated Abuse

- Detect repeated high-frequency failures per user/challenge/source.
- Detect repeated identical incorrect submissions.
- Detect distributed patterns (multiple accounts with similar failure behavior) where visible.
- Track suspicious login + submission sequences (credential attacks followed by high-rate submissions).
- Support manual review in MVP using logs; automated enforcement can remain limited.

## 10. Data Integrity Controls

### Foreign Key Constraints

- Enforce relational integrity between users, roles, challenges, attempts, XP events, and admin logs.
- Orphan records for core entities must be prevented.
- Authorization and audit data must reference valid actors/targets where applicable.

### No Cascading Deletes for Historical Data

- Do not use cascading deletes that remove historical records such as:
  - challenge attempts
  - XP history
  - admin logs
- Prefer deactivation or unpublish state changes for users/challenges/tracks.
- Historical data must remain available for incident review and dispute resolution.

### Admin Change Logging

- Privileged changes must generate admin logs with actor, action, target, timestamp, and outcome.
- Admin logs must be append-only in normal operations.
- Sensitive secrets (flags, password hashes, tokens) must never appear in admin logs.

### Soft Delete Considerations

- MVP does not require generic soft deletes for all tables.
- State flags (active/published) are preferred to preserve history and simplify access control.
- If physical delete is performed for test/setup cleanup, it must not break historical integrity in protected environments.

## 11. Input Validation Strategy

### General Rules

- Validate all inputs server-side at trust boundaries.
- Apply explicit allowlists and constraints rather than permissive parsing.
- Reject malformed input safely without exposing validation internals that help attackers.

### Length Limits

Define and enforce maximum lengths for:

- email / username
- password input (upper bound to prevent abuse payloads)
- challenge slugs
- titles and descriptions
- flag submissions
- log/search/filter query parameters
- pagination inputs

Security purpose:

- Prevent resource abuse
- Reduce injection/XSS risk surface
- Preserve predictable processing behavior

### Whitespace Normalization

- Define a single normalization policy for flag input and apply it consistently.
- Be explicit about whether leading/trailing whitespace is trimmed before validation.
- Never use inconsistent normalization between flag storage and validation.
- Preserve raw submission data only if required for security auditing, with restricted access.

### Special Character Handling

- Treat all user-provided text as untrusted.
- Encode/escape output in user-visible contexts.
- Do not execute or render raw active content from challenge descriptions or user input.
- Validate route/query parameters and identifiers to expected formats.
- Reject control characters or unexpected binary input where not needed.

### File Upload Validation (If Any)

MVP context:

- Player uploads are not required.
- Admin may attach static challenge files.

Security requirements for admin challenge attachments:

- Validate file type and extension against an allowlist.
- Enforce file size limits.
- Normalize/sanitize stored filenames and metadata.
- Prevent path traversal or filesystem-style path injection in file names.
- Do not execute uploaded files as part of platform behavior.
- Scan or review attachments before publication if operationally feasible.

## 12. Logging & Monitoring

### Logging Principles

- Log security-relevant events needed for detection and audit.
- Do not log secrets (passwords, tokens, plaintext flags, flag hashes in user-facing logs).
- Keep logs structured enough for correlation and incident review.
- Distinguish operational errors from security events.

### Failed Login Logging

Required:

- Timestamp
- Normalized identifier context (redacted as needed)
- Outcome (failed)
- Source metadata (privacy-preserving as needed)
- Repeated failure pattern visibility

Purpose:

- Detect credential attacks and abuse spikes

### Failed Flag Attempt Logging

Required:

- User reference
- Challenge reference (if access authorized)
- Outcome (`incorrect`, `rate_limited`, `cooldown`, `access_denied`)
- Timestamp
- Source correlation metadata

Rules:

- Do not log plaintext submitted flags in application logs
- If stored in attempt records for audit, restrict access and avoid broad exposure

Purpose:

- Detect brute-force attacks
- Support dispute review
- Support abuse investigations

### Admin Action Logging

Required for:

- Challenge create/edit/publish/unpublish
- Role changes (including admin promotion)

Log requirements:

- Actor
- Action
- Target
- Success/failure
- Timestamp
- Redacted change summary

Security purpose:

- Accountability
- Incident reconstruction
- Insider threat detection

### Suspicious Pattern Detection

MVP detection goals:

- Repeated failed logins across many accounts
- High-rate flag failures for a single challenge
- Repeated blocked submissions (cooldown/rate-limit evasion attempts)
- Unpublished challenge probing attempts
- Privileged action anomalies (unusual volume of publish/unpublish or role changes)

MVP response expectation:

- Logging and manual review are sufficient baseline controls
- Automated blocking can remain limited and conservative

## 13. Secure Development Assumptions

### No Secrets in Source Control

- Secrets must not be committed to source control.
- Example secret classes:
  - credential secrets
  - token signing secrets
  - flag hashing secrets
  - environment-specific admin bootstrap secrets

### Environment Variable Handling

- Secrets and environment-specific values are provided via deployment/runtime configuration, not source files.
- Secret access should be limited to the components that require them.
- Secret values must not be exposed in logs or error output.

### Separation of Dev and Prod Config

- Development and production configurations must be separate.
- Production must not use development secrets, debug settings, or weak defaults.
- Test fixtures must not contain production secrets or valid production flags.

### Secure Defaults

- Default deny for privileged actions
- Safe error responses (no stack traces or internal details in user-facing responses)
- Strong authentication and authorization enforcement enabled by default
- Logging enabled for security-relevant failures and admin actions
- Unpublished content hidden by default

## 14. Future Security Considerations (Post-MVP)

These are not MVP requirements, but they will become necessary as the platform expands.

### Docker Isolation for Labs

- Per-lab isolation boundaries
- Image provenance and integrity controls
- Privilege restrictions for lab workloads
- Lifecycle cleanup and escape-impact reduction

### Network Sandboxing

- Isolation between learner environments and platform control plane
- Egress controls
- East-west traffic controls for multi-tenant lab environments
- Monitoring for sandbox breakout attempts

### Web Application Firewall (WAF)

- Additional request filtering for public endpoints
- Abuse signature blocking
- Bot mitigation reinforcement
- Operational tuning to avoid breaking legitimate submissions

### Audit Trail Expansion

- Broader security event coverage
- Retention policy formalization
- Tamper-evident audit storage
- More granular admin and content-change traces

### SOC Integration

- Export of security events to centralized monitoring
- Alerting workflows for authentication abuse and submission abuse
- Incident response playbooks for platform-specific threats
- Correlation with infrastructure telemetry

## Residual Risk Summary (MVP)

Accepted MVP residual risks (to be monitored):

- Manual review dependence for some abuse patterns
- Limited insider-threat controls beyond admin audit logging
- Basic bot resistance may not stop distributed low-rate abuse
- Attachment review may be operationally weak without automated scanning

Mitigation posture for MVP:

- Strong server-side authorization
- Flag confidentiality controls
- Atomic XP integrity controls
- Attempt logging and abuse detectability
- Admin action auditability

## Audit Readiness Notes

- This document is normative for MVP security behavior.
- Changes to authentication, authorization, flag handling, XP allocation, admin actions, or logging requirements must update this document before implementation changes are considered complete.
