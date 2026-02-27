# ZeroTrace CTF - FEATURES (MVP)

## Purpose

This document defines the approved MVP features for ZeroTrace CTF, their boundaries, acceptance criteria, dependencies, and explicit exclusions.

This is a scope-control document. Features not listed here are not part of MVP unless formally approved.

## MVP Scope Lock (Approved Features Only)

MVP includes only:

1. Authentication System
2. Role-Based Access Control (Admin, Player)
3. Dashboard
4. Track Listing (Linux, Networking, Crypto only)
5. Challenge Engine (Static challenges only)
6. Flag Submission & Validation
7. XP System
8. Leaderboard
9. Admin Challenge Management Panel
10. Admin Logs

## Global Non-MVP (Explicitly Out of Scope)

The following are not part of MVP:

- Docker labs
- Virtualization or sandbox orchestration
- SOC incident simulations
- Cloud / IoT / OT / ICS tracks or labs
- Mobile app
- Teams / clans
- Real-time multiplayer or attack/defense modes
- Payment system
- Hint marketplace
- In-platform AI assistant
- Gamified animations and non-essential visual effects
- Certificates / badges / resume exports
- Advanced analytics and behavioral intelligence features

## Global System Rules (MVP)

- A user cannot receive XP twice for the same challenge.
- Flags are never stored in plain text.
- Unpublished challenges cannot be accessed by players.
- Admin-only endpoints must be protected by role check.
- All incorrect flag attempts must be logged.
- Brute-force submission attempts must be detectable.
- Leaderboard updates must reflect committed XP changes immediately after a correct solve.
- Hidden/unpublished challenges must not appear in player listings or player-accessible views.

## Feature Dependency Summary

- `Authentication System` -> foundation for all protected features
- `Role-Based Access Control` -> depends on Authentication; gates admin/player behavior
- `Dashboard` -> depends on Authentication, RBAC, XP System, Track Listing
- `Track Listing` -> depends on Authentication, RBAC, Challenge Engine publication state
- `Challenge Engine` -> depends on Authentication, RBAC, Track Listing, Admin Challenge Management
- `Flag Submission & Validation` -> depends on Authentication, RBAC, Challenge Engine
- `XP System` -> depends on Flag Submission & Validation, Challenge Engine
- `Leaderboard` -> depends on XP System, Authentication
- `Admin Challenge Management Panel` -> depends on Authentication, RBAC, Admin Logs
- `Admin Logs` -> depends on Authentication, RBAC; receives events from admin actions

## 1. Authentication System

### Feature Name

Authentication System

### Description

Provides account registration, login, logout, secure credential handling, and session expiration handling for player and admin access.

### User Type (Player/Admin)

- Player
- Admin

### Purpose

- Establish authenticated identity for protected platform access
- Prevent unauthorized access to user and admin functionality
- Provide predictable login/logout lifecycle behavior

### Functional Requirements

- Support user registration with required identity fields and password submission
- Support user login with credential verification
- Support user logout
- Store passwords as hashes only (never plaintext)
- Handle session expiration and invalid session/token states
- Deny authentication for inactive accounts
- Return consistent authentication failure responses

### Non-Functional Requirements

- Security-first credential handling and storage
- Deterministic auth failure behavior (expired vs invalid session handled safely)
- No sensitive credential data in logs
- Reliable session lifecycle under repeat actions (idempotent logout behavior)

### Acceptance Criteria

- A new user can register successfully and then login
- Duplicate registration attempts (same email/username) are rejected safely
- Invalid credentials do not authenticate the user
- Inactive users cannot login
- Logout removes access to protected routes until re-authentication
- Expired/invalid session state redirects user to login on protected actions
- Password values are never stored or returned in plaintext

### Dependencies

- None (foundational feature)

### Edge Cases

- Simultaneous registration attempts for same identity
- Repeated login attempts with invalid credentials
- Logout with already-expired session
- Stale session present during login page load
- Session expires during protected action

### Out of Scope (for this feature)

- Password reset / forgot password flow
- Email verification
- Multi-factor authentication
- Social login / SSO
- Account lockout workflows beyond basic rate limiting
- Device/session management UI

## 2. Role-Based Access Control (RBAC)

### Feature Name

Role-Based Access Control (RBAC)

### Description

Defines and enforces permission boundaries between `player` and `admin` roles for routes, actions, and UI visibility.

### User Type (Player/Admin)

- Player
- Admin

### Purpose

- Prevent unauthorized access to administrative features
- Ensure player-facing views expose only permitted content
- Maintain consistent role-driven behavior across the platform

### Functional Requirements

- Support two roles only in MVP: `player`, `admin`
- Enforce admin vs player permissions on protected endpoints
- Protect admin routes from non-admin access
- Apply UI visibility control so users only see actions allowed by role
- Ensure backend authorization is authoritative (UI visibility is not sufficient)
- Support role changes (admin-promoted users gain admin access on subsequent authenticated state refresh/login)

### Non-Functional Requirements

- Default-deny behavior for admin permissions
- Consistent authorization outcomes across all endpoints
- No sensitive admin data leakage through unauthorized responses
- Auditable role changes via Admin Logs feature

### Acceptance Criteria

- Player users cannot access admin panel routes or admin endpoints
- Admin users can access admin challenge management and role change actions
- Player UI does not display admin-only actions
- Direct URL access to admin pages by player is denied
- Authorization remains enforced even if frontend state is manipulated

### Dependencies

- Authentication System
- Admin Logs (for role change audit records)

### Edge Cases

- User role changes while user is currently logged in
- Invalid/expired session on admin route
- Missing role assignment for a user (must deny privileged access safely)
- Duplicate role assignment attempts

### Out of Scope (for this feature)

- Fine-grained permission matrix beyond `player`/`admin`
- Organization/team-based permissions
- Delegated admin scopes
- Attribute-based access control

## 3. Dashboard

### Feature Name

Dashboard

### Description

Authenticated landing view showing user progression summary, including XP, unlocked tracks, and recent activity.

### User Type (Player/Admin)

- Player
- Admin (shared base dashboard; admin panel remains separate feature)

### Purpose

- Provide immediate status after login
- Show progression summary and next actions
- Surface recent user activity without deep analytics

### Functional Requirements

- Display current total XP
- Display unlocked/available tracks (within MVP track set)
- Display recent activity summary (for example: recent solves / recent attempts / recent XP events)
- Show challenge completion/progress summary at a basic level
- Provide navigation entry points to tracks, leaderboard, and (if admin) admin panel
- Reflect latest committed XP and completion state

### Non-Functional Requirements

- Fast retrieval of summary data at MVP scale
- No exposure of hidden/unpublished challenge content in player dashboard data
- Predictable behavior for first-time users with no activity
- Clear failure handling for expired sessions

### Acceptance Criteria

- Authenticated user can load dashboard after login
- Dashboard displays current XP and recent activity summary
- Dashboard shows only the three MVP tracks and their availability state
- First-time users see zero-state dashboard without errors
- Dashboard redirects to login when session is expired/invalid

### Dependencies

- Authentication System
- RBAC
- XP System
- Track Listing
- Challenge Engine (completion state source)

### Edge Cases

- User has zero XP and no attempts
- Session expires during dashboard fetch
- Challenge becomes unpublished after prior completion (history still counted; hidden content not shown)
- Concurrent solve in another tab updates XP before dashboard refresh

### Out of Scope (for this feature)

- Advanced analytics
- Performance graphs / trend charts
- Personalized recommendations
- Gamified animations / celebratory effects
- Social feed or team activity

## 4. Track Listing

### Feature Name

Track Listing

### Description

Displays the available training tracks in MVP and their access state, ordered deterministically.

### User Type (Player/Admin)

- Player
- Admin (read access to player-facing list; admin uses separate management panel for challenge administration)

### Purpose

- Provide structured navigation into challenge domains
- Enforce MVP track boundary
- Communicate locked/unlocked state consistently

### Functional Requirements

- Show exactly three MVP tracks only:
  - Linux
  - Networking
  - Crypto
- Display locked/unlocked (or available/locked) state per track
- Apply deterministic ordering via admin-defined/order-controlled sequence
- Show basic progress summary per track (for example: solved/total published challenges)
- Hide inactive tracks from player listing
- If unlock gating is disabled, still display all active tracks as available

### Non-Functional Requirements

- No unpublished challenge details exposed in player track list
- Stable ordering across requests
- Consistent access-state evaluation using server-side rules
- Graceful empty states when a track has no published challenges

### Acceptance Criteria

- Player sees only Linux, Networking, and Crypto tracks
- Track ordering is consistent with configured order
- Locked/unlocked state displays correctly for the user
- Inactive track records do not appear to players
- Unpublished challenge counts/details are not exposed to players

### Dependencies

- Authentication System
- RBAC
- Challenge Engine (publication state and challenge counts)
- XP System (if unlock state depends on progression)

### Edge Cases

- Track has zero published challenges
- Track is deactivated while a user is viewing the list
- Unlock state changes immediately after a correct submission
- User tries to access a locked track directly

### Out of Scope (for this feature)

- Additional tracks beyond Linux, Networking, Crypto
- User-created/custom tracks
- Dynamic track recommendation logic
- Track-specific analytics dashboards

## 5. Challenge Engine (Static Challenges)

### Feature Name

Challenge Engine (Static Challenges)

### Description

Delivers published challenge content to players, including metadata and static attachments, without live labs or virtualization.

### User Type (Player/Admin)

- Player (consume published challenges)
- Admin (preview/manage through admin feature)

### Purpose

- Provide the core training content experience for MVP
- Present challenge metadata and downloadable artifacts needed for static challenges
- Maintain strict separation between published and unpublished content

### Functional Requirements

- Display challenge description/content
- Display challenge metadata:
  - Difficulty label
  - XP reward
  - Track association
  - Completion state for current user
- Support file attachments for challenges (static downloadable artifacts only)
- Restrict player access to published challenges only
- Support deterministic ordering within track (via `order_index` behavior)
- Return not-found/safe denial for unpublished or deleted/missing challenges in player flows

### Non-Functional Requirements

- No hidden/internal challenge data exposed in player payloads
- Predictable response for deleted/missing challenge references
- Consistent publication-state enforcement on every access
- Static-content delivery only (no runtime execution dependencies)

### Acceptance Criteria

- Player can open a published challenge and see description, difficulty, and XP reward
- Challenge attachments are accessible when attached to the challenge
- Unpublished challenges are not visible or accessible to players
- Deleted/missing challenge references return safe failure behavior
- Challenge ordering within track is consistent

### Dependencies

- Authentication System
- RBAC
- Track Listing
- Admin Challenge Management Panel (source of challenge content, publication state, attachments)

### Edge Cases

- Challenge unpublished after player opened track list but before challenge open
- Challenge deleted/missing due admin action or test data cleanup
- Attachment missing/unavailable while challenge metadata loads
- User accesses challenge from stale bookmark

### Out of Scope (for this feature)

- Docker labs
- Interactive terminals or shells
- Virtual machines / sandbox instances
- Dynamic challenge provisioning
- Real-time multiplayer challenge states
- Hint marketplace or hint purchase flows

## 6. Flag Submission & Validation

### Feature Name

Flag Submission & Validation

### Description

Handles player flag submissions, validates them securely against stored flag hashes, logs attempts, and routes successful solves into the XP system.

### User Type (Player/Admin)

- Player (submit flags)
- Admin (indirectly impacts challenge testing and monitoring only)

### Purpose

- Validate challenge completion attempts
- Protect challenge flags from disclosure
- Detect and control abusive submission behavior

### Functional Requirements

- Accept flag submissions for accessible published challenges
- Validate flags using hash comparison against stored hashed valid flags
- Never store valid flags in plaintext
- Log all attempts, including incorrect attempts
- Prevent duplicate completion reward paths for already-solved challenges
- Support rate limiting logic for submission endpoint
- Support brute-force detection through attempt patterns
- Optionally apply cooldown after X failed attempts (configurable MVP behavior)
- Return clear but non-revealing outcomes:
  - Correct
  - Incorrect
  - Already completed
  - Temporarily blocked/rate-limited

### Non-Functional Requirements

- Constant-time style comparison behavior (no timing-leak-prone matching feedback)
- No secret leakage in error responses or logs
- High integrity of attempt records (attempt logging failure should fail request safely)
- Deterministic validation behavior for normalized inputs

### Acceptance Criteria

- Correct flag submission is recognized and routed to XP reward flow
- Incorrect flag submission is rejected and logged
- Repeated correct submissions for an already solved challenge do not trigger duplicate reward
- Rate-limited/cooldown responses are returned when thresholds are exceeded (if configured)
- Validation does not reveal the correct flag or partial-match information
- Unpublished or inaccessible challenges cannot be validated by players

### Dependencies

- Authentication System
- RBAC
- Challenge Engine
- XP System (on successful first solve)

### Edge Cases

- Invalid flag format submissions
- Leading/trailing whitespace or normalization-sensitive input
- Simultaneous submissions from multiple tabs/devices
- Challenge unpublished/deleted between page load and submission
- Session expires during submission
- Repeated identical wrong flags

### Out of Scope (for this feature)

- Fuzzy/partial flag matching
- Hint generation based on submitted flag
- AI-assisted validation explanations
- Automated ban system (detection only; manual review for MVP)

## 7. XP System

### Feature Name

XP System

### Description

Maintains authoritative XP progression by awarding fixed XP per challenge solve, storing aggregate totals, and recording immutable XP history.

### User Type (Player/Admin)

- Player (receives XP)
- Admin (may view impact; no advanced XP operations in MVP beyond challenge XP assignment)

### Purpose

- Provide measurable progression
- Power dashboard progression summaries and leaderboard ranking
- Preserve immutable audit trail of XP awards

### Functional Requirements

- Award XP once per challenge per user on first correct solve only
- Use challenge-defined XP reward value for award amount
- Maintain current XP total in a dedicated aggregate (authoritative read model)
- Record XP history for each award event
- Prevent double reward for the same challenge
- Do not recalculate XP dynamically for normal reads
- Update leaderboard-visible XP state immediately after successful reward commit

### Non-Functional Requirements

- Atomic consistency between XP history and XP total updates
- Deterministic tie-break timestamp handling for leaderboard use
- No client authority over XP amount
- Reliable behavior under simultaneous submissions

### Acceptance Criteria

- First correct solve awards configured XP and updates total XP
- XP history contains one award record for the solve
- Duplicate solve submissions do not create additional XP history entries
- XP total remains consistent with committed XP history events
- Leaderboard reflects updated XP immediately after reward completion

### Dependencies

- Flag Submission & Validation
- Challenge Engine (XP reward source)
- Authentication System

### Edge Cases

- Two correct submissions arrive at nearly the same time
- Client retries after timeout and reward may already be committed
- Challenge XP value changed by admin after a user already solved it
- Temporary write failure during XP award sequence

### Out of Scope (for this feature)

- XP decay
- Bonus XP events
- Streak multipliers
- Seasonal resets
- Manual XP adjustment UI (future administrative capability)
- Animation-driven XP feedback

## 8. Leaderboard

### Feature Name

Leaderboard

### Description

Displays ranked users based on total XP, with deterministic tie-break rules and paginated results.

### User Type (Player/Admin)

- Player
- Admin (read access)

### Purpose

- Provide competitive ranking visibility
- Reflect progression outcomes in a simple, consistent format
- Support scalable browsing via pagination

### Functional Requirements

- Rank users by total XP (highest first)
- Apply deterministic tie-breaker using earliest completion/tie-break timestamp
- Provide pagination for leaderboard results
- Display only approved public fields (for example: rank, username, total XP, solved count)
- Update displayed rankings immediately after committed XP changes (next refresh/request)
- Exclude hidden/private administrative data from leaderboard output

### Non-Functional Requirements

- Stable ordering across pages
- No exposure of sensitive identifiers or account details
- Consistent ranking behavior under concurrent XP updates
- Reasonable response performance at MVP scale

### Acceptance Criteria

- Users are sorted by total XP descending
- XP ties are resolved deterministically using defined tie-breaker logic
- Pagination returns consistent ordered pages without duplicates/skips in a stable dataset
- Newly awarded XP changes ranking on immediate subsequent leaderboard load
- Inactive user display policy is applied consistently (MVP recommendation: exclude inactive users)

### Dependencies

- XP System
- Authentication System
- RBAC (for protected access behavior, if leaderboard is not public)

### Edge Cases

- Multiple users with same XP and same visible state
- Rapid rank changes due multiple solves
- User deactivated after appearing on leaderboard
- Requesting page beyond available results

### Out of Scope (for this feature)

- Real-time live-updating websocket leaderboard
- Team leaderboard
- Seasonal leaderboard resets
- Region/track-specific leaderboard variants
- Achievement badges or animated rank effects

## 9. Admin Challenge Management Panel

### Feature Name

Admin Challenge Management Panel

### Description

Admin-only interface and workflow for creating, editing, and publishing static challenges, including difficulty, XP, flags, ordering, and attachments.

### User Type (Player/Admin)

- Admin

### Purpose

- Allow admins to manage MVP challenge content without developer intervention
- Control publication state and challenge metadata quality
- Provide auditable challenge lifecycle actions

### Functional Requirements

- Create challenge
- Edit challenge
- Publish challenge
- Unpublish challenge
- Set difficulty (`easy`, `medium`, `hard`)
- Assign XP reward
- Assign track (Linux, Networking, Crypto)
- Set order within track
- Manage challenge description/content
- Manage static file attachments
- Manage challenge valid flags (stored as hashes; no plaintext persistence)
- Enforce readiness checks before publish (valid metadata and at least one active flag)

### Non-Functional Requirements

- Admin-only access with backend enforcement
- No plaintext flag exposure after submission
- Deterministic publish/unpublish behavior affecting player visibility immediately
- Auditable actions through Admin Logs feature
- Safe handling of validation failures without partial inconsistent records

### Acceptance Criteria

- Admin can create a draft challenge with required metadata and valid flag(s)
- Admin can edit challenge metadata, difficulty, XP, and ordering
- Admin can publish a challenge only when publish prerequisites are met
- Published challenge becomes visible to players; unpublished challenge is hidden
- Admin can unpublish a challenge and player access is removed immediately
- All create/edit/publish/unpublish actions generate admin log entries

### Dependencies

- Authentication System
- RBAC
- Challenge Engine (consumer of published content)
- Admin Logs

### Edge Cases

- Two admins edit the same challenge concurrently
- Slug/order conflict during create or edit
- Admin session expires while editing
- Admin attempts to publish a challenge without active valid flags
- Admin attempts to manage challenge in inactive track

### Out of Scope (for this feature)

- Bulk import/export of challenges
- Version history / rollback UI
- Scheduled publishing
- Approval workflows / multi-step moderation
- Dynamic lab provisioning controls
- Challenge cloning across environments

## 10. Admin Logs

### Feature Name

Admin Logs

### Description

Provides append-only audit records for privileged admin actions affecting challenge content and role assignments.

### User Type (Player/Admin)

- Admin

### Purpose

- Maintain accountability for privileged changes
- Support incident review, content audit, and dispute resolution
- Track high-impact administrative actions in MVP

### Functional Requirements

- Log challenge creation actions
- Log challenge edit actions
- Log challenge publish/unpublish actions
- Log user role change actions (including admin promotion)
- Record actor, action type, target entity, timestamp, and outcome
- Store redacted change summaries (no secrets)
- Support basic retrieval/filtering in admin context (by action type/time/actor/target)

### Non-Functional Requirements

- Append-only behavior in normal operations
- No plaintext flags, password hashes, tokens, or other secrets in logs
- Reliable log creation for successful and failed admin actions where applicable
- Searchable enough for MVP operational review

### Acceptance Criteria

- Challenge create/edit/publish/unpublish operations generate admin log entries
- Role change operations generate admin log entries
- Each log entry includes actor, action, target, timestamp, and success/failure outcome
- Sensitive values are excluded/redacted from log content
- Admins can review logs relevant to recent administrative actions

### Dependencies

- Authentication System
- RBAC
- Admin Challenge Management Panel (event source)
- Role-Based Access Control role-change workflows (event source)

### Edge Cases

- Admin action succeeds but log write fails (operation should fail or be treated as incomplete per audit-critical policy)
- Duplicate repeated admin action requests (idempotent outcomes still logged appropriately)
- Deleted/missing target entity during attempted admin action
- System-initiated admin-equivalent action (actor may be recorded as system)

### Out of Scope (for this feature)

- Full SIEM integration
- External log forwarding pipelines
- Immutable compliance vaulting
- Advanced forensic diff visualization
- Non-admin security event logging (covered by other features, e.g., flag attempt logging)

## Future Phase Boundary (Not Approved for MVP)

The following may be considered after MVP, but are not approved in this document:

- Dynamic labs (Docker-based or otherwise)
- Cloud / IoT / OT / ICS / Blockchain domain expansion
- Team play and real-time attack/defense modes
- Hint systems, hint marketplace, token economies
- In-platform AI assistant or automated tutoring
- Payment/subscription system
- Mobile applications
- Advanced analytics and reporting
- Achievement/badge systems and visual gamification layers

## Change Control Rule

Any proposed MVP feature addition, scope expansion, or behavior change that materially affects user flows, data models, security rules, or admin responsibilities must be explicitly added to this document before implementation.
