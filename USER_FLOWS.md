# ZeroTrace CTF - USER_FLOWS (MVP)

## Scope

This document defines step-by-step user and admin journeys for the ZeroTrace CTF MVP only.

Covered MVP scope:

- Authentication (Register, Login, Logout)
- Dashboard
- Track listing
- Challenge view
- Flag submission
- XP reward system
- Leaderboard
- Admin challenge management

Excluded from MVP and this document:

- Docker labs
- Virtualization
- Advanced SOC workflows
- Dynamic lab orchestration

## Behavioral Conventions (Applies to All Flows)

### Actor Types

- `Anonymous User`
- `Authenticated Player`
- `Authenticated Admin`
- `System` (backend and data layer behavior)

### Session States

- `anonymous`
- `authenticated_player`
- `authenticated_admin`
- `session_expired`
- `invalid_token`

### Challenge Visibility States

- `published` (visible to authorized players)
- `unpublished` (admin-visible only through admin flows)
- `deleted_or_missing` (unexpected in normal operations; must be handled safely)

### Standard Security Response Rules

- Admin routes require backend role check (`admin`).
- Invalid/expired authentication returns an authorization failure and must not expose protected data.
- Hidden/unpublished challenges must not appear in player listings and must not be accessible by direct URL.
- Incorrect flag attempts must be logged.
- Correct submissions must not award XP more than once for the same user and challenge.
- Leaderboard must reflect successful XP updates immediately after a correct submission (same request/transaction outcome).

### Error Handling Conventions

- Player-facing errors should be specific enough for usability but must not reveal secrets (flags, internal identifiers, validation internals).
- Authorization failures should not disclose whether hidden content exists (prefer not-found style behavior for unpublished challenge access attempts in player flows).
- Write failures on security-critical records (attempt logging, XP history) should fail the operation rather than continue partially.

## 1. Flow: User Registration

### Flow Name

User Registration

### Entry Point

- Public registration page (`Register`)
- Direct navigation to registration route while in `anonymous` state

### Preconditions

- User is not authenticated (`anonymous`)
- Registration is enabled in MVP
- User does not already have an account using the same normalized email or username

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User opens registration page | System renders registration form (email, username, password, confirm password) | `anonymous` -> `anonymous` |
| 2 | User enters registration data | System performs client-side format checks (required fields, password confirmation match) and shows inline errors if needed | `anonymous` -> `anonymous` |
| 3 | User submits registration form | System validates request format and required fields server-side | `anonymous` -> `anonymous` |
| 4 | System normalizes email/username and checks uniqueness | If email or username already exists, system rejects registration with a safe message | `anonymous` -> `anonymous` |
| 5 | System validates password policy | If password fails policy, system rejects and returns validation error | `anonymous` -> `anonymous` |
| 6 | System creates user account | System stores password hash, sets `is_active = true`, records timestamps | `anonymous` -> `anonymous` |
| 7 | System assigns default role | System assigns `player` role to the new user | `anonymous` -> `anonymous` |
| 8 | System initializes XP aggregate | System creates user XP summary row with zero values | `anonymous` -> `anonymous` |
| 9 | System returns registration success | System prompts user to login (MVP behavior: registration does not auto-login) | `anonymous` -> `anonymous` |

### Success State

- User account exists and is active
- User has `player` role assignment
- User XP summary record is initialized
- User is redirected to login page or shown login call-to-action

### Failure State

- Registration rejected with no account created
- Partial writes are not allowed (user creation, role assignment, XP initialization must be atomic)
- User remains `anonymous`

### Edge Cases

- Simultaneous registration attempts with the same email/username (race condition)
- Email case normalization collision (for example, mixed-case vs lowercase input)
- User retries submission after network timeout and request was already processed
- Authenticated user manually navigates to registration page (should redirect to dashboard)

### Security Considerations

- Rate limit registration endpoint to reduce abuse and enumeration
- Do not return overly detailed duplicate account errors that facilitate user enumeration
- Never log plaintext passwords
- Enforce server-side validation even if client-side validation exists
- Ensure account creation, role assignment, and XP initialization are transactionally consistent

## 2. Flow: User Login

### Flow Name

User Login

### Entry Point

- Public login page (`Login`)
- Redirect from protected route due `session_expired` or `invalid_token`

### Preconditions

- User is `anonymous`, `session_expired`, or `invalid_token`
- User account exists and `is_active = true`

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User opens login page | System renders login form | `anonymous/session_expired/invalid_token` -> same |
| 2 | User enters credentials | System performs basic client-side required-field validation | same -> same |
| 3 | User submits login form | System validates request format server-side | same -> same |
| 4 | System looks up user by normalized identifier | If user not found, system returns generic credential failure | same -> same |
| 5 | System checks account state | If `is_active = false`, system denies login with account inactive message | same -> same |
| 6 | System verifies password hash | If mismatch, system returns generic credential failure and records failed login attempt | same -> same |
| 7 | System issues authenticated session artifacts | System creates authenticated session response (access token + refresh/session continuation mechanism) and loads role claims | same -> `authenticated_player` or `authenticated_admin` |
| 8 | System updates login metadata | System updates `last_login_at` | authenticated -> authenticated |
| 9 | System redirects user | Player goes to dashboard; admin may go to dashboard or admin landing based on last route intent | authenticated -> authenticated |

### Success State

- User is authenticated
- User role is resolved (`player` or `admin`)
- Protected routes become accessible according to role

### Failure State

- Login denied; user remains unauthenticated
- Failed attempt is logged for audit/security review
- System does not disclose whether the email or password was incorrect

### Edge Cases

- Expired session trying to access protected page and then redirected to login
- Invalid JWT present in client state during login page load (system should clear stale auth state)
- Multiple concurrent login attempts from same user
- User account deactivated after credentials entered but before login processing completes

### Security Considerations

- Rate limit login endpoint and track failed attempts
- Use generic credential failure messages to reduce account enumeration
- Do not log passwords or tokens
- Regenerate session/auth state on login to prevent token/session fixation behavior
- Enforce backend role claims; frontend route visibility is not sufficient

## 3. Flow: User Logout

### Flow Name

User Logout

### Entry Point

- Authenticated user selects `Logout` from navigation/menu
- System-initiated logout after auth failure recovery (optional behavior)

### Preconditions

- User is `authenticated_player` or `authenticated_admin`

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User clicks `Logout` | System sends logout request and/or begins local sign-out flow | `authenticated_*` -> `authenticated_*` (pending logout) |
| 2 | System validates auth/session continuation token | If valid, system invalidates or rotates server-tracked refresh/session continuation state as configured | `authenticated_*` -> `authenticated_*` |
| 3 | System clears client auth state | Tokens/session markers are removed from active client state | `authenticated_*` -> `anonymous` |
| 4 | System confirms logout | User is redirected to login page or public landing page | `anonymous` -> `anonymous` |

### Success State

- User is logged out locally
- Protected routes require re-authentication
- Server-side session continuation state (if tracked) is invalidated/rotated

### Failure State

- If logout request fails due to network error, client should still clear local auth state and redirect
- If session is already expired/invalid, system still completes local logout (idempotent outcome)

### Edge Cases

- Logout clicked multiple times
- Logout with expired session
- Logout from one tab while another tab remains open
- Invalid JWT during logout request (should not block local sign-out)

### Security Considerations

- Logout endpoint must be protected against CSRF if cookie-based session continuation is used
- Logout should be idempotent and not leak session validity details
- Clear privileged admin access state immediately on logout

## 4. Flow: View Dashboard

### Flow Name

View Dashboard

### Entry Point

- Redirect after successful login
- User clicks `Dashboard` in navigation

### Preconditions

- User is authenticated (`authenticated_player` or `authenticated_admin`)
- User account is active

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User navigates to dashboard | System checks local auth state and sends authenticated dashboard request | `authenticated_*` -> `authenticated_*` |
| 2 | System validates authentication | If JWT/session is invalid or expired, system returns auth failure | `authenticated_*` -> `session_expired` or `invalid_token` |
| 3 | System loads dashboard summary data | System retrieves user XP total, solved count, track progress summary, and recent activity summaries (MVP-safe fields only) | `authenticated_*` -> `authenticated_*` |
| 4 | System returns dashboard payload | Dashboard renders user-specific progression and navigation actions | `authenticated_*` -> `authenticated_*` |
| 5 | If auth failure occurred | System clears invalid auth state and redirects to login | `session_expired/invalid_token` -> `anonymous` |

### Success State

- Dashboard is displayed with current XP and progress summary
- Data reflects latest committed XP state (including recent correct submissions)

### Failure State

- Auth failure redirects user to login
- Backend/data failure returns generic dashboard load error without leaking internal state

### Edge Cases

- First-time user with zero XP and no attempts
- User deactivated after login but before dashboard request
- Dashboard data changes while page is open (new solves in another tab)

### Security Considerations

- Return only the authenticated user’s private progress data
- Do not include hidden/unpublished challenge content in player dashboard summaries
- Treat auth failures consistently (expired vs invalid token)

## 5. Flow: View Track List

### Flow Name

View Track List

### Entry Point

- Dashboard `Tracks` section
- Direct navigation to tracks route

### Preconditions

- User is authenticated and active

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User opens track list | System sends authenticated request for track listing | `authenticated_*` -> `authenticated_*` |
| 2 | System validates authentication | If invalid/expired, system returns auth failure and no track data | `authenticated_*` -> `session_expired` or `invalid_token` |
| 3 | System loads track records | System retrieves active MVP tracks only (Linux, Networking, Crypto) | `authenticated_*` -> `authenticated_*` |
| 4 | System evaluates visibility/unlock status | For each track, system determines `available` or `locked` using configured deterministic rules (if enabled) | `authenticated_*` -> `authenticated_*` |
| 5 | System filters challenge counts | System includes counts only for published challenges visible to the user role | `authenticated_*` -> `authenticated_*` |
| 6 | System returns track list | UI displays track name, progress summary, and availability state | `authenticated_*` -> `authenticated_*` |
| 7 | If auth failure occurred | System clears auth state and redirects to login | `session_expired/invalid_token` -> `anonymous` |

### Success State

- User sees only active MVP tracks
- Locked/available state is clearly shown (if unlock logic is enabled)

### Failure State

- No track data is returned to unauthenticated users
- System returns generic error for data retrieval failures

### Edge Cases

- A track is deactivated while user is viewing the page
- No published challenges exist for a track yet
- Unlock rules disabled (all active tracks shown as available)

### Security Considerations

- Hidden/unpublished challenges must not influence visible challenge counts for players
- Admin-only metadata (draft counts, flag state, unpublished challenge details) must not be returned in player track list flow
- Backend must not trust frontend filters for visibility

## 6. Flow: Unlock Track (If Applicable)

### Flow Name

Unlock Track (Deterministic Progression)

### Entry Point

- User attempts to access a locked track
- System re-evaluates progression after a correct submission / XP update

### Preconditions

- User is authenticated and active
- Track exists and is active
- MVP progression gating is enabled (if disabled, all active tracks are available and this flow is bypassed)

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User views track list or clicks a locked track | System evaluates unlock conditions using current user progression data | `track_locked` -> `track_locked` or `track_available` |
| 2 | If prerequisites are not met | System returns locked state with minimal reason (for example: required XP or prerequisite completion not met) | `track_locked` -> `track_locked` |
| 3 | User completes prerequisite challenge(s) and gains XP | System updates XP and progression state via normal solve flow | user progression state advances |
| 4 | System re-evaluates unlock conditions | On next track list/challenge access request, system recalculates track accessibility | `track_locked` -> `track_available` (if met) |
| 5 | User opens newly available track | System returns track challenge list (published challenges only) | `track_available` -> `track_available` |

### Success State

- Track transitions from `locked` to `available`
- User can access the track list and published challenges within that track

### Failure State

- Track remains locked if prerequisites are not met
- If track is missing/deactivated, access fails safely (not found/unavailable)

### Edge Cases

- Unlock rules disabled in MVP configuration (flow becomes a no-op; all active tracks available)
- Simultaneous submissions update XP while user is viewing locked state (unlock on refresh/retry)
- Track deactivated after user unlocks it but before access

### Security Considerations

- Locked tracks must not expose hidden challenge content or unpublished challenge metadata
- Unlock checks must be performed server-side on every access, not only on UI state
- Unlock reasons should not reveal hidden challenge identifiers

## 7. Flow: View Challenge

### Flow Name

View Challenge

### Entry Point

- User clicks a challenge from a track list
- Direct navigation to a challenge route (ID or slug)

### Preconditions

- User is authenticated and active
- Challenge exists
- Challenge is published (player flow)
- User has access to the challenge’s track (if unlock gating is enabled)

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User requests challenge page | System sends authenticated challenge request | `authenticated_player` -> `authenticated_player` |
| 2 | System validates authentication | If JWT/session invalid or expired, system returns auth failure | `authenticated_player` -> `session_expired` or `invalid_token` |
| 3 | System resolves challenge identifier | If challenge does not exist (`deleted_or_missing`), system returns not found | `authenticated_player` -> `authenticated_player` |
| 4 | System checks publication and track access | If challenge is unpublished or track is locked, system denies access without exposing challenge content | `authenticated_player` -> `authenticated_player` |
| 5 | System loads challenge data | System returns challenge title, description, track, difficulty, XP reward, completion state for this user | `authenticated_player` -> `authenticated_player` |
| 6 | System renders challenge page | User can view challenge and submit a flag | `authenticated_player` -> `authenticated_player` |
| 7 | If auth failure occurred | System clears auth state and redirects to login | `session_expired/invalid_token` -> `anonymous` |

### Success State

- User sees the challenge content and current solve/completion state
- No hidden/internal challenge data is exposed

### Failure State

- Invalid/expired auth redirects to login
- Unpublished challenge access attempt returns safe denial (prefer not-found behavior for players)
- Deleted/missing challenge returns not found

### Edge Cases

- Challenge unpublished after it appears in the list but before user opens it
- Challenge deleted/missing due admin cleanup/test data issue
- User opens challenge directly from stale bookmark
- User solved challenge previously; page should show completed state

### Security Considerations

- Do not return flag hashes, admin notes, or unpublished content fields
- Player access to unpublished challenges must be blocked even via direct URL
- Access checks must be server-side and role-aware

## 8. Flow: Submit Correct Flag

### Flow Name

Submit Correct Flag

### Entry Point

- User is on a visible published challenge page and submits a flag

### Preconditions

- User is authenticated and active
- Challenge exists, is published, and is accessible
- Challenge has at least one active valid flag
- User is not currently blocked by submission cooldown/rate limit

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User enters flag and clicks `Submit` | System performs basic client-side format checks (required input) | `challenge_open` -> `submission_pending` |
| 2 | System sends authenticated submission request | Backend validates auth and challenge access | `submission_pending` -> `submission_processing` or auth failure |
| 3 | System validates request shape | If malformed/empty flag, system rejects and records attempt as failed/invalid format (per logging policy) | `submission_processing` -> `challenge_open` |
| 4 | System normalizes submitted flag | System prepares normalized value for deterministic validation | `submission_processing` -> `submission_processing` |
| 5 | System records attempt (security event) | System inserts attempt record with submitted data, hashes, and processing status metadata | `submission_processing` -> `submission_processing` |
| 6 | System validates flag against active challenge flags | System compares normalized submission against stored valid flag hashes without exposing match details | `submission_processing` -> `flag_valid` |
| 7 | System checks prior successful solve / XP award | If already solved, system stops XP allocation path and returns already-completed response | `flag_valid` -> `already_solved` or `eligible_for_reward` |
| 8 | If eligible, system allocates XP transactionally | System marks correct solve outcome, inserts XP history event, updates user XP aggregate, updates tie-break timestamp, commits | `eligible_for_reward` -> `reward_committed` |
| 9 | System returns success response | Response includes correct status, XP delta, new total XP, updated completion state | `reward_committed` -> `challenge_completed` |
| 10 | UI updates local state | Challenge marked completed; dashboard/leaderboard-dependent widgets refresh immediately | `challenge_completed` -> `challenge_completed` |

### Success State

- Attempt is recorded
- Correct solve is recorded exactly once for the user/challenge
- XP is awarded once
- XP history entry is created
- Leaderboard position is updated immediately after commit
- Challenge is shown as completed

### Failure State

- If already solved, system returns `already completed` response and no XP is awarded
- If auth expired/invalid, submission is denied and user is redirected to login after auth cleanup
- If challenge becomes unpublished/deleted before processing, submission is denied without validation details
- If XP transaction fails, no partial XP update or duplicate history entry is allowed

### Edge Cases

- Simultaneous double-submit from same page (double click)
- Simultaneous submissions from multiple tabs/devices
- Flag contains leading/trailing whitespace (system normalization policy must be explicit and consistent)
- Challenge unpublished after page load but before submission
- Session expires between page load and submit

### Security Considerations

- Rate limit and throttle submission endpoint
- Log all attempts (including invalid format and blocked attempts) for abuse analysis
- Do not reveal the correct flag or comparison details
- Use constant-time comparison behavior for hash validation
- Prevent duplicate XP via transactional checks and uniqueness constraints

## 9. Flow: Submit Incorrect Flag

### Flow Name

Submit Incorrect Flag

### Entry Point

- User is on challenge page and submits a non-matching flag

### Preconditions

- User is authenticated and active
- Challenge exists, is published, and is accessible
- Submission endpoint is reachable

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User enters incorrect flag and submits | System performs basic client-side checks and sends request | `challenge_open` -> `submission_pending` |
| 2 | System validates auth and challenge access | If invalid/expired auth or hidden challenge, system denies request | `submission_pending` -> auth/access failure or `submission_processing` |
| 3 | System validates request shape and normalizes flag | System prepares normalized value for matching and logging | `submission_processing` -> `submission_processing` |
| 4 | System checks brute-force/cooldown policy | If blocked, system logs blocked attempt and returns cooldown/rate-limit response | `submission_processing` -> `submission_blocked` or `submission_processing` |
| 5 | System records attempt | System writes incorrect attempt record (`is_correct = false`) including timestamp and abuse metadata | `submission_processing` -> `attempt_logged` |
| 6 | System validates against active flags | No match found; system returns incorrect flag response | `attempt_logged` -> `challenge_open` |
| 7 | UI displays failure feedback | User remains on challenge page; no XP change | `challenge_open` -> `challenge_open` |

### Success State

- Incorrect attempt is logged
- No XP is awarded
- Challenge remains unsolved
- User receives actionable but non-revealing feedback (`Incorrect flag`)

### Failure State

- Auth failure redirects to login after auth cleanup
- Hidden/unpublished/deleted challenge access attempt is denied safely
- If attempt logging fails, submission processing should fail and return generic error (no validation outcome returned)

### Edge Cases

- Invalid flag format (should still be treated as failed attempt and logged)
- User already solved challenge and submits again from stale page (should return `already completed`, not `incorrect`)
- Repeated identical wrong flag submissions
- Network timeout after server logs attempt and returns response (user may retry)

### Security Considerations

- Incorrect attempts must be logged for audit and brute-force detection
- Use generic incorrect response; do not reveal proximity, format hints, or partial match info
- Enforce rate limiting and optional cooldown after repeated failures
- Do not store or display submitted flag values in general admin listings

## 10. Flow: XP Reward Allocation

### Flow Name

XP Reward Allocation (Server Transaction)

### Entry Point

- Triggered by a correct flag submission that passed validation and is eligible for reward

### Preconditions

- Submission is verified as correct
- User has not already received `challenge_solve` XP for this challenge
- Challenge is valid for reward (published and configured with XP reward)

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | Correct submission reaches reward path | System begins atomic reward transaction | `eligible_for_reward` -> `reward_tx_open` |
| 2 | System re-checks solve/XP uniqueness invariants | System verifies no prior successful solve/XP event exists for this user/challenge | `reward_tx_open` -> `reward_tx_open` or `duplicate_detected` |
| 3 | System inserts XP history event | System writes immutable XP event with challenge reference and source attempt reference | `reward_tx_open` -> `reward_tx_open` |
| 4 | System updates user XP aggregate | System increments total XP, solved count, and tie-break timestamp as needed | `reward_tx_open` -> `reward_tx_open` |
| 5 | System commits transaction | XP history and user aggregate become durable and consistent | `reward_tx_open` -> `reward_committed` |
| 6 | System returns reward result to submission flow | Response includes new XP total and leaderboard-relevant state | `reward_committed` -> `reward_committed` |
| 7 | Leaderboard read path reflects update | Next leaderboard read (including immediate refresh) returns new ranking | `reward_committed` -> `leaderboard_updated` |

### Success State

- One XP history event created for the solve
- User XP aggregate updated exactly once
- Leaderboard reflects new total immediately after commit

### Failure State

- Transaction is rolled back on any write failure
- No partial state (for example, `xp_history` without `user_xp` update) is allowed
- If duplicate is detected during transaction, system returns `already completed` / no additional XP

### Edge Cases

- Simultaneous correct submissions for same challenge and user
- Retry after client timeout when server may have already committed
- Admin changes challenge XP reward while a submission is in flight (system must apply one committed value consistently)

### Security Considerations

- XP is server-authoritative; client cannot influence `xp_delta`
- Reward path must not be callable directly without successful flag validation context
- Use transaction and unique constraints to prevent duplicate XP under race conditions

## 11. Flow: Prevent Duplicate XP

### Flow Name

Prevent Duplicate XP for Same Challenge

### Entry Point

- User submits a correct flag for a challenge already solved
- Simultaneous valid submissions race for the same challenge

### Preconditions

- User is authenticated
- Challenge is valid and accessible for submission attempt
- System supports uniqueness checks on successful solves and XP history

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User submits flag | System processes submission normally through auth and validation checks | `challenge_open` -> `submission_processing` |
| 2 | System validates flag as correct | System detects candidate correct submission | `submission_processing` -> `flag_valid` |
| 3 | System checks existing solve/XP state | If prior solve or XP event exists, system marks request as duplicate reward attempt | `flag_valid` -> `duplicate_detected` or `eligible_for_reward` |
| 4 | If duplicate detected pre-transaction | System records attempt outcome (correct but already solved) and skips XP allocation | `duplicate_detected` -> `already_solved` |
| 5 | If race occurs and two requests pass pre-check | Transaction/unique constraints allow one request to commit XP; second request fails duplicate invariant and is mapped to already-completed response | `eligible_for_reward` -> `reward_committed` (one request) / `already_solved` (other request) |
| 6 | System returns response | User receives `already completed` or `correct, XP awarded` depending on winning request | terminal state |

### Success State

- XP is awarded at most once per user per challenge
- Duplicate correct submissions do not create duplicate XP history events
- User receives deterministic response (`already completed`) for subsequent submissions

### Failure State

- If duplicate-prevention checks fail due internal error, submission must fail safely with no XP changes committed
- System must not return ambiguous success if reward commit failed

### Edge Cases

- Double-click submit causing two near-simultaneous requests
- Multiple devices submitting same correct flag at the same time
- Client retries after timeout when first request already succeeded
- Correct submission arrives after challenge was already solved earlier in another session

### Security Considerations

- Duplicate-prevention logic must be enforced server-side and at data integrity layer
- Do not expose internal race-condition details in user-facing responses
- Continue logging attempts for abuse analytics, even when XP is not awarded

## 12. Flow: Leaderboard Display

### Flow Name

Leaderboard Display

### Entry Point

- User navigates to leaderboard page
- Post-solve success flow triggers immediate leaderboard refresh

### Preconditions

- User is authenticated and active
- Leaderboard data source (`user_xp`) is available

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User opens leaderboard page | System sends authenticated leaderboard request | `authenticated_*` -> `authenticated_*` |
| 2 | System validates auth | If invalid/expired, system denies and redirects to login after auth cleanup | `authenticated_*` -> `session_expired`/`invalid_token`/`anonymous` |
| 3 | System loads leaderboard rows | System reads user XP aggregates and applies canonical sorting (XP desc, tie-break asc) | `authenticated_*` -> `leaderboard_query_complete` |
| 4 | System filters visible user fields | System returns rank, username, XP total, solved count, tie-break context (if displayed) without sensitive data | `leaderboard_query_complete` -> `leaderboard_ready` |
| 5 | UI renders leaderboard | Current user row may be highlighted | `leaderboard_ready` -> `leaderboard_ready` |
| 6 | After correct submission | System refreshes leaderboard data immediately (same page or next request) | `leaderboard_ready` -> `leaderboard_ready` (reordered if needed) |

### Success State

- Leaderboard is displayed using current committed XP totals
- Ties are resolved deterministically using earliest completion time
- Recent solve changes appear immediately after reward commit

### Failure State

- Auth failure redirects to login
- Data load failure returns generic leaderboard load error without exposing internal query details

### Edge Cases

- Multiple users tied on XP
- Users with zero XP
- User deactivated after prior leaderboard inclusion (policy should define hide vs retain display; MVP should prefer hiding inactive accounts from current leaderboard)
- Rapid submissions by many users causing rank changes between refreshes

### Security Considerations

- Do not expose email addresses, role data, or internal IDs in player leaderboard response
- Leaderboard should read from server-authoritative XP aggregates only
- Admin-only users should not gain extra leaderboard data unless explicitly authorized

## 13. Flow: Admin Create Challenge

### Flow Name

Admin Create Challenge

### Entry Point

- Authenticated admin opens admin panel and selects `Create Challenge`

### Preconditions

- User is `authenticated_admin`
- Admin route access passes backend role check
- Target track exists (Linux, Networking, or Crypto)

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | Admin opens create challenge form | System validates admin auth/role and renders form | `authenticated_admin` -> `admin_create_form_open` |
| 2 | Admin enters challenge metadata | System performs basic form validation (required fields, allowed difficulty, positive XP) | `admin_create_form_open` -> `admin_create_form_open` |
| 3 | Admin enters one or more valid flags | System accepts flag inputs for hashing on submit; plaintext is not persisted in admin UI logs | `admin_create_form_open` -> `admin_create_form_open` |
| 4 | Admin submits create request | System validates admin auth/role and request payload server-side | `admin_create_form_open` -> `admin_create_processing` |
| 5 | System validates business rules | System checks track existence, slug uniqueness, order constraints, and challenge metadata validity | `admin_create_processing` -> `admin_create_processing` or validation failure |
| 6 | System hashes flag values and stores challenge + flags | System creates challenge (default `unpublished` unless explicitly publishing is requested and allowed) and stores hashed flags only | `admin_create_processing` -> `challenge_created_draft` or `challenge_created_published` |
| 7 | System writes admin audit log | Action logged with actor, target challenge, summary (no plaintext flag values) | `challenge_created_*` -> same |
| 8 | System returns create success | Admin sees created challenge details and current publication state | `challenge_created_*` -> `admin_create_complete` |

### Success State

- Challenge record is created
- One or more hashed valid flags are stored
- Admin audit log entry exists
- Challenge is available for further editing/publishing

### Failure State

- Non-admin access is denied (no form data processed)
- Validation failure returns actionable errors without persisting partial challenge data
- If flag hashing/storage fails, challenge creation must roll back (no challenge without intended flags unless explicitly saved as metadata-only draft policy)

### Edge Cases

- Simultaneous admins creating same slug
- Invalid `order_index` collision within track
- Admin session expires while form is open
- Admin attempts to create challenge in inactive/missing track

### Security Considerations

- Admin routes must be protected by backend role check
- Plaintext flags must not be stored, logged, or returned after submission
- Audit log must record challenge creation attempts and outcomes
- Hidden (unpublished) challenge content must remain inaccessible to players until publish

## 14. Flow: Admin Edit Challenge

### Flow Name

Admin Edit Challenge

### Entry Point

- Authenticated admin opens an existing challenge in admin panel and selects `Edit`

### Preconditions

- User is `authenticated_admin`
- Challenge exists (draft or published)
- Admin role validation passes

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | Admin opens challenge edit view | System validates admin role and loads challenge metadata (including unpublished challenges) | `authenticated_admin` -> `admin_edit_form_open` |
| 2 | Admin updates metadata (title, description, difficulty, XP, order) | System validates field formats client-side and on submit server-side | `admin_edit_form_open` -> `admin_edit_form_open` |
| 3 | Admin optionally updates valid flags | System treats flag changes as secure flag-management updates (hash new flags, activate/deactivate flag records) | `admin_edit_form_open` -> `admin_edit_processing` |
| 4 | Admin submits edit request | System validates auth/role, challenge existence, and business rules | `admin_edit_form_open` -> `admin_edit_processing` |
| 5 | System applies changes | System updates challenge and/or challenge flag state without exposing plaintext flags | `admin_edit_processing` -> `admin_edit_applied` |
| 6 | System writes admin audit log | Log includes actor, action type, target challenge, and redacted before/after summary | `admin_edit_applied` -> `admin_edit_applied` |
| 7 | System returns success | Admin sees updated challenge state | `admin_edit_applied` -> `admin_edit_complete` |

### Success State

- Challenge metadata updates are saved
- Flag updates are stored as hashed values only
- Admin audit log entry records the change

### Failure State

- Non-admin access denied
- Deleted/missing challenge returns not found in admin context
- Validation/order conflict/slug conflict prevents save; no partial write
- Auth expiration during submit returns auth failure and requires re-login

### Edge Cases

- Simultaneous edits by two admins (MVP behavior should be deterministic; last committed write wins unless explicit conflict handling is added later)
- Editing a challenge that was unpublished or deleted after form load
- Changing XP reward affects future solves only; prior XP history remains unchanged

### Security Considerations

- Backend role enforcement required for all edit endpoints
- Plaintext flags must not be written to logs or returned in responses
- Admin change logs must record challenge edits with redacted field snapshots
- Published challenge edits should be auditable due downstream impact on player experience

## 15. Flow: Admin Publish/Unpublish Challenge

### Flow Name

Admin Publish / Unpublish Challenge

### Entry Point

- Authenticated admin uses publish toggle/action from admin challenge list or challenge detail page

### Preconditions

- User is `authenticated_admin`
- Challenge exists
- For publish: challenge has at least one active valid flag and valid metadata

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | Admin triggers publish or unpublish action | System validates admin auth/role and target challenge existence | `authenticated_admin` -> `publish_toggle_processing` |
| 2 | If publishing, system validates readiness | System checks challenge metadata completeness and active flag availability | `publish_toggle_processing` -> `publish_ready` or validation failure |
| 3 | System applies publication state change | `is_published` is updated; `published_at` handled per platform policy | `publish_toggle_processing/publish_ready` -> `published` or `unpublished` |
| 4 | System writes admin audit log | System logs action type and target challenge | `published/unpublished` -> same |
| 5 | System returns result | Admin UI updates challenge state immediately | `published/unpublished` -> `publish_toggle_complete` |
| 6 | Player visibility updates | Published challenges become visible to authorized players; unpublished challenges disappear from player listings and direct player access | visibility state updates |

### Success State

- Challenge publication state is updated
- Player visibility reflects the change immediately
- Admin audit log entry exists

### Failure State

- Publish denied if no active valid flag exists
- Non-admin access denied
- Missing/deleted challenge returns not found
- Auth expiration during request requires re-login

### Edge Cases

- Publish action triggered twice (idempotent response should be supported)
- Unpublish action while players are actively viewing challenge page
- Admin publishes challenge in deactivated track (should be denied or track activation required; MVP should deny for consistency)

### Security Considerations

- Player routes must enforce `is_published` check server-side on every access
- Unpublished challenge access attempts by players must not reveal content
- Audit logging for publish/unpublish is mandatory

## 16. Flow: Role Change (Admin Promotes User)

### Flow Name

Role Change (Admin Promotes User to `admin`)

### Entry Point

- Authenticated admin opens user management view and selects `Promote to Admin`

### Preconditions

- Actor is `authenticated_admin`
- Target user exists and is active (recommended MVP policy)
- `admin` role exists in role catalog
- Actor has permission to manage roles

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | Admin opens user management for target user | System validates actor auth/role and loads target user + current roles | `authenticated_admin` -> `role_change_form_open` |
| 2 | Admin selects `Promote to Admin` | System prepares role assignment request | `role_change_form_open` -> `role_change_processing` |
| 3 | System validates request | Checks actor authorization, target user existence, role existence, and duplicate assignment state | `role_change_processing` -> `role_change_processing` or validation failure |
| 4 | System applies role assignment | Inserts `user_roles` assignment for target user -> `admin` (if not already present) | `role_change_processing` -> `role_change_applied` |
| 5 | System writes admin audit log | Logs actor, target user, target role, action result | `role_change_applied` -> `role_change_applied` |
| 6 | System returns success | Admin UI shows updated roles for target user | `role_change_applied` -> `role_change_complete` |
| 7 | Target user authorization updates | New admin privileges take effect on next token refresh or next login (MVP-safe behavior) | target user role state updated on next auth cycle |

### Success State

- Target user has `admin` role assignment
- Admin audit log captures role change
- Future authenticated sessions for target user include admin authorization

### Failure State

- Non-admin actor denied
- Target user missing/deactivated (per policy) prevents role change
- Duplicate role assignment returns no-op or validation error without duplicate row
- Auth expiration during request requires re-login

### Edge Cases

- Two admins promote the same user simultaneously (duplicate role assignment race)
- Target user currently logged in and using old token (admin access may not appear until token refresh)
- Role catalog misconfiguration (missing `admin` role record)

### Security Considerations

- Role changes must be backend-enforced and fully audited
- UI role visibility is not sufficient for authorization
- Do not expose sensitive target user data during role management beyond what is needed
- Consider stronger controls for admin role changes (re-auth confirmation) in future phases

## 17. Flow: Attempt Brute Force Prevention Logic

### Flow Name

Attempt Brute Force Prevention Logic (Flag Submission Protection)

### Entry Point

- Any flag submission request to a challenge endpoint
- Repeated failed submissions for the same user/challenge and/or source fingerprint

### Preconditions

- Submission endpoint is hit by an authenticated user
- Attempt logging and rate/cooldown policy are configured

### Step-by-Step Actions and System Responses

| Step | Actor Action | System Response | State Transition |
|---|---|---|---|
| 1 | User submits a flag | System validates auth and challenge access before expensive checks | `challenge_open` -> `submission_processing` |
| 2 | System checks global/API rate limits | If exceeded, system rejects request with generic throttling response and logs blocked attempt | `submission_processing` -> `submission_blocked_global` or continue |
| 3 | System loads recent attempt signals | System evaluates recent failed attempts by user, challenge, and source fingerprint/hash | `submission_processing` -> `submission_processing` |
| 4 | System evaluates cooldown policy | If failed-attempt threshold `X` exceeded within window, system enters or enforces cooldown state | `submission_processing` -> `submission_blocked_cooldown` or continue |
| 5 | If blocked | System records blocked attempt event (`attempt_status` indicates rate-limited/cooldown) and returns generic try-later message | blocked state -> `challenge_open` |
| 6 | If not blocked | System proceeds with normal flag validation flow and logs processed attempt outcome | `submission_processing` -> normal correct/incorrect flow |
| 7 | On repeated failures | System may extend cooldown duration per policy (optional) while continuing to log events | `challenge_open` -> `challenge_open` / cooldown active |
| 8 | After cooldown expires | System accepts new submission attempts under normal flow | `cooldown_active` -> `challenge_open` |

### Success State

- Brute-force attempts are slowed or blocked
- Incorrect and blocked attempts are logged
- Legitimate users can resume submissions after cooldown expires

### Failure State

- If attempt logging fails, submission request should fail safely (no validation outcome returned)
- If rate-limit/cooldown state cannot be evaluated reliably, system should return a protective error or stricter temporary throttling response rather than silently disabling protections

### Edge Cases

- Simultaneous submissions that cross threshold at the same time
- User submits correct flag while in cooldown (MVP policy should still enforce cooldown consistently)
- Distributed brute-force attempts across multiple accounts from same source
- Session expires during repeated attempts
- Challenge becomes unpublished/deleted while cooldown is active

### Security Considerations

- Do not reveal whether a submission was close to correct
- Use layered controls: endpoint rate limit + per-user/per-challenge cooldown + attempt logging
- Hash source identifiers for correlation where required by privacy policy
- Ensure blocked attempts are auditable
- Keep responses generic to avoid assisting automation tuning

## MVP System-Wide Failure Handling Matrix (Reference)

### Expired Session

- Protected routes and actions return auth failure
- Client clears auth state and redirects to login
- No protected data is returned

### Invalid JWT

- Treated as auth failure
- Client clears auth state and redirects to login
- Event may be logged as security signal

### Deleted Challenge (Unexpected but Must Be Handled)

- Player challenge view/submission returns not found
- Admin edit/publish actions return not found and write audit outcome if request was authenticated
- No stale cached content should be trusted after server denial

### Unpublished Challenge Access Attempt

- Player challenge view/submission returns safe denial (prefer not-found behavior)
- Admin can access through admin routes only
- Event may be logged for abuse review if repeated

### Simultaneous Submissions

- One correct solve can award XP
- Duplicate submissions are resolved by server-side uniqueness checks and transactions
- Leaderboard reflects the single committed reward outcome
