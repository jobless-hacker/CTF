# ZeroTrace CTF - API_CONTRACT (MVP)

## Scope

This document defines the REST API contract for the ZeroTrace CTF MVP.

It is a request/response contract freeze. Implementation must conform to this document unless a documented contract change is approved.

In scope:

- Authentication
- Role-based access (`admin`, `player`)
- Dashboard data (composed from existing endpoints)
- Track listing (3 tracks only)
- Challenge listing and detail
- Flag submission
- XP system (read + reward effects via submission)
- Leaderboard
- Admin challenge management
- Admin logs

Out of scope:

- Docker labs
- SOC ingestion
- External integrations
- Dynamic lab orchestration
- Advanced attachment/file management APIs beyond simple challenge attachment metadata

## 1. Global API Rules

### 1.1 Response Envelope (All Endpoints)

All responses must use the same envelope shape:

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

or

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "string_code",
    "message": "Safe human-readable message"
  }
}
```

### 1.2 Error Object Contract

The `error` object must include:

- `code`
- `message`

Rules:

- Do not leak sensitive information in `message`.
- Do not expose stack traces, token internals, hash values, or validation internals.
- Unauthorized access returns generic `401` or `403` responses.
- Resource access denied due to hidden/unpublished challenge visibility should return a safe not-found style response where specified.

### 1.3 Authentication and Authorization Rules

- All protected routes require a valid JWT.
- Admin routes require server-side role check (`admin`).
- Frontend visibility controls are non-authoritative and do not replace backend checks.
- Invalid or expired tokens are treated as authentication failure.

### 1.4 Identifier Rules

- Resource IDs in path parameters are opaque UUIDs.
- APIs may return resource IDs only when needed for subsequent API calls.
- Do not expose unnecessary internal identifiers (especially on leaderboard responses).

### 1.5 Timestamp Rules

- All timestamps are UTC.
- Timestamps are returned in ISO 8601 string format.

### 1.6 Pagination Rules (List Endpoints)

When pagination is supported:

- `page` is 1-based
- `page_size` has a documented max
- Response includes pagination metadata

Common pagination response shape:

```json
{
  "page": 1,
  "page_size": 20,
  "total_items": 100,
  "total_pages": 5
}
```

### 1.7 Dashboard Data Composition (MVP)

There is no dedicated `GET /dashboard` endpoint in MVP.

Dashboard data is composed from:

- `GET /auth/me`
- `GET /tracks`
- `GET /users/me/xp`

This is intentional to keep the MVP API surface small.

## 2. Common Schemas (Pseudo-Definitions)

### 2.1 Error Codes (Common)

The following codes are used across endpoints (non-exhaustive):

- `validation.invalid_request`
- `auth.invalid_credentials`
- `auth.unauthorized`
- `auth.forbidden`
- `auth.session_expired`
- `auth.account_inactive`
- `auth.rate_limited`
- `resource.not_found`
- `resource.conflict`
- `challenge.already_solved`
- `challenge.track_locked`
- `challenge.publish_precondition_failed`
- `submission.rate_limited`
- `submission.cooldown_active`
- `role.operation_not_allowed`
- `server.internal_error`

### 2.2 User Summary

```json
{
  "id": "uuid",
  "email": "string",
  "username": "string",
  "roles": ["player"],
  "is_active": true,
  "created_at": "timestamp",
  "last_login_at": "timestamp | null"
}
```

### 2.3 Track Summary

```json
{
  "id": "uuid",
  "slug": "linux | networking | crypto",
  "name": "string",
  "order_index": 0,
  "access_state": "available | locked",
  "progress": {
    "solved_count": 0,
    "published_challenge_count": 0
  }
}
```

### 2.4 Challenge List Item

```json
{
  "id": "uuid",
  "track_id": "uuid",
  "slug": "string",
  "title": "string",
  "difficulty": "easy | medium | hard",
  "xp_reward": 100,
  "order_index": 0,
  "is_completed": false,
  "attachment_count": 0
}
```

### 2.5 Challenge Attachment

Attachment API support in MVP is metadata-based only (simple attachments). Binary upload workflow is out of this contract.

```json
{
  "id": "uuid",
  "display_name": "string",
  "file_name": "string",
  "download_path": "string",
  "content_type": "string | null",
  "size_bytes": 12345
}
```

### 2.6 Challenge Detail

```json
{
  "id": "uuid",
  "track": {
    "id": "uuid",
    "slug": "string",
    "name": "string"
  },
  "slug": "string",
  "title": "string",
  "description": "string",
  "difficulty": "easy | medium | hard",
  "xp_reward": 100,
  "is_published": true,
  "order_index": 0,
  "attachments": [
    {
      "id": "uuid",
      "display_name": "string",
      "file_name": "string",
      "download_path": "string",
      "content_type": "string | null",
      "size_bytes": 12345
    }
  ],
  "user_state": {
    "is_completed": false,
    "last_attempt_at": "timestamp | null"
  }
}
```

### 2.7 XP Summary

```json
{
  "total_xp": 0,
  "solved_challenges_count": 0,
  "tie_breaker_completed_at": "timestamp | null",
  "recent_xp_events": [
    {
      "id": "uuid",
      "event_type": "challenge_solve",
      "xp_delta": 100,
      "balance_after": 500,
      "challenge_id": "uuid | null",
      "challenge_title": "string | null",
      "awarded_at": "timestamp"
    }
  ]
}
```

### 2.8 Leaderboard Row

```json
{
  "rank": 1,
  "username": "string",
  "total_xp": 1000,
  "solved_challenges_count": 10,
  "is_current_user": false
}
```

### 2.9 Admin Challenge Summary

```json
{
  "id": "uuid",
  "track_id": "uuid",
  "slug": "string",
  "title": "string",
  "difficulty": "easy | medium | hard",
  "xp_reward": 100,
  "order_index": 0,
  "is_published": false,
  "published_at": "timestamp | null",
  "attachment_count": 0,
  "updated_at": "timestamp"
}
```

### 2.10 Admin Log Row

```json
{
  "id": "uuid",
  "actor_user": {
    "id": "uuid",
    "username": "string"
  },
  "action_type": "string",
  "target": {
    "target_type": "challenge | user_role",
    "challenge_id": "uuid | null",
    "user_id": "uuid | null",
    "role": "admin | player | null"
  },
  "is_success": true,
  "change_summary": "string",
  "request_id": "string | null",
  "created_at": "timestamp"
}
```

## 3. Endpoint Index

### Auth

1. `POST /auth/register`
2. `POST /auth/login`
3. `POST /auth/logout`
4. `GET /auth/me`

### Tracks

5. `GET /tracks`
6. `GET /tracks/{track_id}`

### Challenges

7. `GET /tracks/{track_id}/challenges`
8. `GET /challenges/{challenge_id}`
9. `POST /challenges/{challenge_id}/submit`

### XP & Leaderboard

10. `GET /users/me/xp`
11. `GET /leaderboard`

### Admin

12. `POST /admin/challenges`
13. `PUT /admin/challenges/{challenge_id}`
14. `PATCH /admin/challenges/{challenge_id}/publish`
15. `GET /admin/logs`
16. `PATCH /admin/users/{user_id}/role`

## 4. API Endpoints

## 1. Endpoint: Register User

### Endpoint Name

Register User

### HTTP Method

`POST`

### URL Path

`/auth/register`

### Auth Required

No

### Role Required (Player/Admin)

None

### Description

Creates a new user account with default `player` role and initializes user XP aggregate.

### Request Body Schema

```json
{
  "email": "string",
  "username": "string",
  "password": "string",
  "confirm_password": "string"
}
```

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `201 Created`

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "string",
      "username": "string",
      "roles": ["player"],
      "is_active": true,
      "created_at": "timestamp"
    },
    "next_action": "login"
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `409 Conflict` -> `resource.conflict` (email or username unavailable)
- `429 Too Many Requests` -> `auth.rate_limited`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Rate limit registration to reduce abuse and account enumeration.
- Do not log plaintext password fields.
- Email and username uniqueness checks must not reveal more detail than necessary.
- User creation + role assignment + XP initialization must be atomic.

### Notes

- Registration does not create an authenticated session in MVP.
- `email` is normalized before storage.

## 2. Endpoint: Login User

### Endpoint Name

Login User

### HTTP Method

`POST`

### URL Path

`/auth/login`

### Auth Required

No

### Role Required (Player/Admin)

None

### Description

Authenticates a user and returns session/auth state for protected API access.

### Request Body Schema

```json
{
  "identifier": "string",
  "password": "string"
}
```

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "access_token": "string",
    "token_type": "Bearer",
    "expires_in_seconds": 900,
    "user": {
      "id": "uuid",
      "email": "string",
      "username": "string",
      "roles": ["player"],
      "is_active": true,
      "last_login_at": "timestamp"
    }
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.invalid_credentials`
- `403 Forbidden` -> `auth.account_inactive`
- `429 Too Many Requests` -> `auth.rate_limited`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Do not distinguish user-not-found vs wrong-password in error messages.
- Rate limit and log failed login attempts.
- Do not log password or token values.
- Session/token issuance must occur only after successful password verification and account status check.

### Notes

- `identifier` may be email or username.
- Session continuation artifacts (if used) may be set outside the JSON body (for example, secure cookie); this contract only freezes JSON response body.

## 3. Endpoint: Logout User

### Endpoint Name

Logout User

### HTTP Method

`POST`

### URL Path

`/auth/logout`

### Auth Required

Yes

### Role Required (Player/Admin)

Player or Admin

### Description

Invalidates the current authenticated session context for the calling user.

### Request Body Schema

None

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "logged_out": true
  },
  "error": null
}
```

### Error Responses

- `401 Unauthorized` -> `auth.unauthorized`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Logout must not leak token validity internals.
- If cookie-based session continuation is used, logout endpoint must be CSRF-protected.
- Client should clear local auth state even when logout request fails or returns `401`.

### Notes

- Logout should be idempotent from client perspective.

## 4. Endpoint: Get Current Authenticated User

### Endpoint Name

Get Current Authenticated User

### HTTP Method

`GET`

### URL Path

`/auth/me`

### Auth Required

Yes

### Role Required (Player/Admin)

Player or Admin

### Description

Returns the authenticated user profile and resolved roles for session bootstrap and route authorization.

### Request Body Schema

None

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "string",
      "username": "string",
      "roles": ["player"],
      "is_active": true,
      "created_at": "timestamp",
      "last_login_at": "timestamp | null"
    }
  },
  "error": null
}
```

### Error Responses

- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `403 Forbidden` -> `auth.account_inactive`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Return only current user data.
- Role claims in response are informational; backend authorization remains authoritative.
- Invalid tokens must not expose parsing/verification details.

### Notes

- Used by frontend to determine route access (`player` vs `admin`).

## 5. Endpoint: List Tracks

### Endpoint Name

List Tracks

### HTTP Method

`GET`

### URL Path

`/tracks`

### Auth Required

Yes

### Role Required (Player/Admin)

Player or Admin

### Description

Returns the MVP track list (Linux, Networking, Crypto) with access state and basic progress summary for the authenticated user.

### Request Body Schema

None

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "tracks": [
      {
        "id": "uuid",
        "slug": "linux",
        "name": "Linux",
        "order_index": 1,
        "access_state": "available",
        "progress": {
          "solved_count": 3,
          "published_challenge_count": 10
        }
      }
    ]
  },
  "error": null
}
```

### Error Responses

- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Player responses must not expose unpublished challenge counts/details.
- Access state must be computed server-side.
- Only active MVP tracks must be returned.

### Notes

- Track list order is deterministic (`order_index`).
- If unlock gating is disabled, `access_state` is `available` for all active tracks.

## 6. Endpoint: Get Track Detail

### Endpoint Name

Get Track Detail

### HTTP Method

`GET`

### URL Path

`/tracks/{track_id}`

### Auth Required

Yes

### Role Required (Player/Admin)

Player or Admin

### Description

Returns metadata and user progress summary for a single track.

### Request Body Schema

None

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "track": {
      "id": "uuid",
      "slug": "networking",
      "name": "Networking",
      "order_index": 2,
      "access_state": "locked",
      "progress": {
        "solved_count": 0,
        "published_challenge_count": 8
      },
      "unlock_requirements": {
        "is_enabled": true,
        "summary": "Complete prerequisite requirements to unlock."
      }
    }
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request` (invalid `track_id` format)
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `404 Not Found` -> `resource.not_found`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Must not expose inactive/non-MVP track metadata to players.
- Unlock requirement summary must not reveal hidden challenge identifiers.
- Authorization and access-state calculation must be server-side.

### Notes

- Locked track metadata may still be returned; challenge list access is enforced separately.
- `track_id` is a UUID.

## 7. Endpoint: List Challenges in Track

### Endpoint Name

List Challenges in Track

### HTTP Method

`GET`

### URL Path

`/tracks/{track_id}/challenges`

### Auth Required

Yes

### Role Required (Player/Admin)

Player or Admin

### Description

Returns a paginated list of visible challenges in a track. For player behavior, only published challenges are returned.

### Request Body Schema

None

### Query Parameters (if any)

```json
{
  "page": "integer, optional, default=1, min=1",
  "page_size": "integer, optional, default=20, min=1, max=100"
}
```

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "track": {
      "id": "uuid",
      "slug": "crypto",
      "name": "Crypto",
      "access_state": "available"
    },
    "items": [
      {
        "id": "uuid",
        "track_id": "uuid",
        "slug": "string",
        "title": "string",
        "difficulty": "easy",
        "xp_reward": 100,
        "order_index": 1,
        "is_completed": false,
        "attachment_count": 1
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total_items": 10,
      "total_pages": 1
    }
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `403 Forbidden` -> `challenge.track_locked` (player track lock)
- `404 Not Found` -> `resource.not_found`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Player callers must never receive unpublished challenge rows.
- Track lock checks must be enforced server-side before returning challenge list.
- Challenge list response must not include flag-related or admin-only metadata.

### Notes

- Admin callers using this endpoint receive the same published-only view; draft/unpublished management is handled via admin endpoints.

## 8. Endpoint: Get Challenge Detail

### Endpoint Name

Get Challenge Detail

### HTTP Method

`GET`

### URL Path

`/challenges/{challenge_id}`

### Auth Required

Yes

### Role Required (Player/Admin)

Player or Admin

### Description

Returns challenge content and metadata for a single challenge. Player access is limited to published and authorized challenges. Admins may read draft/unpublished challenge details for management workflows.

### Request Body Schema

None

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "challenge": {
      "id": "uuid",
      "track": {
        "id": "uuid",
        "slug": "linux",
        "name": "Linux"
      },
      "slug": "string",
      "title": "string",
      "description": "string",
      "difficulty": "medium",
      "xp_reward": 150,
      "is_published": true,
      "order_index": 3,
      "attachments": [
        {
          "id": "uuid",
          "display_name": "string",
          "file_name": "string",
          "download_path": "string",
          "content_type": "string | null",
          "size_bytes": 12345
        }
      ],
      "user_state": {
        "is_completed": false,
        "last_attempt_at": "timestamp | null"
      }
    }
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `404 Not Found` -> `resource.not_found` (includes hidden/unpublished challenge access attempts by unauthorized users)
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Never return valid flags, hashed flags, or flag-validation metadata.
- For unauthorized access (including unpublished challenge access by player), return generic not-found behavior.
- Admin access still must be role-checked server-side.
- Challenge content is admin-authored input and must be safely rendered by clients.

### Notes

- `challenge_id` is a UUID.
- `is_published` is safe to return; for player access it will always be `true`.

## 9. Endpoint: Submit Challenge Flag

### Endpoint Name

Submit Challenge Flag

### HTTP Method

`POST`

### URL Path

`/challenges/{challenge_id}/submit`

### Auth Required

Yes

### Role Required (Player/Admin)

Player or Admin

### Description

Validates a submitted flag for an accessible challenge, records the attempt, and triggers XP allocation on first correct solve.

### Request Body Schema

```json
{
  "flag": "string"
}
```

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `200 OK` (processed submission result)

Correct result:

```json
{
  "success": true,
  "data": {
    "result": "correct",
    "challenge_id": "uuid",
    "is_completed": true,
    "xp_awarded": 150,
    "total_xp": 850,
    "solved_challenges_count": 7,
    "leaderboard_refresh_required": true
  },
  "error": null
}
```

Incorrect result:

```json
{
  "success": true,
  "data": {
    "result": "incorrect",
    "challenge_id": "uuid",
    "is_completed": false,
    "attempt_recorded": true
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `404 Not Found` -> `resource.not_found` (includes hidden/unpublished/unauthorized challenge access)
- `409 Conflict` -> `challenge.already_solved`
- `429 Too Many Requests` -> `submission.rate_limited` or `submission.cooldown_active`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Rate limit this endpoint.
- Do not reveal validation internals, flag format hints, partial-match hints, or correct flag values.
- Never return hashed flag values.
- All attempts (incorrect and blocked) must be logged.
- Handle simultaneous submissions safely so XP is awarded at most once.

### Notes

- If the user already solved the challenge, submission is rejected with `409` and no validation result details.
- For race conditions, one request may succeed and concurrent duplicates may return `409 challenge.already_solved`.

## 10. Endpoint: Get Current User XP Summary

### Endpoint Name

Get Current User XP Summary

### HTTP Method

`GET`

### URL Path

`/users/me/xp`

### Auth Required

Yes

### Role Required (Player/Admin)

Player or Admin

### Description

Returns current XP totals and recent XP activity for the authenticated user. Used by the dashboard and post-solve refresh flows.

### Request Body Schema

None

### Query Parameters (if any)

```json
{
  "history_limit": "integer, optional, default=10, min=1, max=50"
}
```

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "total_xp": 850,
    "solved_challenges_count": 7,
    "tie_breaker_completed_at": "timestamp | null",
    "recent_xp_events": [
      {
        "id": "uuid",
        "event_type": "challenge_solve",
        "xp_delta": 150,
        "balance_after": 850,
        "challenge_id": "uuid",
        "challenge_title": "string",
        "awarded_at": "timestamp"
      }
    ]
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Return only the authenticated user's XP data.
- XP values must come from trusted XP aggregate/history, not client input.
- Do not expose administrative correction metadata unless explicitly required (not in MVP).

### Notes

- This endpoint is part of dashboard data composition.
- XP is not recalculated dynamically for normal reads in MVP.

## 11. Endpoint: Get Leaderboard

### Endpoint Name

Get Leaderboard

### HTTP Method

`GET`

### URL Path

`/leaderboard`

### Auth Required

Yes

### Role Required (Player/Admin)

Player or Admin

### Description

Returns paginated leaderboard rows ranked by total XP with deterministic tie-break logic.

### Request Body Schema

None

### Query Parameters (if any)

```json
{
  "page": "integer, optional, default=1, min=1",
  "page_size": "integer, optional, default=20, min=1, max=100"
}
```

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "rank": 1,
        "username": "string",
        "total_xp": 1200,
        "solved_challenges_count": 12,
        "is_current_user": false
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total_items": 250,
      "total_pages": 13
    },
    "sort": {
      "primary": "total_xp_desc",
      "tie_breaker": "tie_breaker_completed_at_asc"
    }
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Leaderboard data must derive from trusted XP data only.
- Do not expose email addresses, roles, or internal user IDs.
- Pagination limits must be enforced to reduce scraping/abuse load.

### Notes

- Leaderboard updates are visible immediately after XP award commits (next request/refresh).
- Inactive user handling policy for MVP: inactive users should not appear in current leaderboard results.

## 12. Endpoint: Admin Create Challenge

### Endpoint Name

Admin Create Challenge

### HTTP Method

`POST`

### URL Path

`/admin/challenges`

### Auth Required

Yes

### Role Required (Player/Admin)

Admin

### Description

Creates a challenge draft (or published challenge if requested and publish preconditions pass), stores hashed flags, and records an admin audit log.

### Request Body Schema

```json
{
  "track_id": "uuid",
  "slug": "string",
  "title": "string",
  "description": "string",
  "difficulty": "easy | medium | hard",
  "xp_reward": 100,
  "order_index": 1,
  "is_published": false,
  "flags": [
    "plaintext_flag_string"
  ],
  "attachments": [
    {
      "display_name": "string",
      "file_name": "string",
      "download_path": "string",
      "content_type": "string | null",
      "size_bytes": 12345
    }
  ]
}
```

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `201 Created`

```json
{
  "success": true,
  "data": {
    "challenge": {
      "id": "uuid",
      "track_id": "uuid",
      "slug": "string",
      "title": "string",
      "difficulty": "easy",
      "xp_reward": 100,
      "order_index": 1,
      "is_published": false,
      "published_at": "timestamp | null",
      "attachment_count": 1,
      "updated_at": "timestamp"
    }
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `403 Forbidden` -> `auth.forbidden`
- `409 Conflict` -> `resource.conflict` (slug/order conflict)
- `422 Unprocessable Entity` -> `challenge.publish_precondition_failed`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Admin role check required server-side.
- `flags` are sensitive request inputs: never log plaintext flag values.
- Response must never include stored hashed flags or plaintext flags.
- Challenge create action must be audit-logged.
- If create includes `is_published=true`, publish preconditions must be enforced in same operation.

### Notes

- Attachment entries are metadata references only (simple attachments); binary upload transport is outside this contract.

## 13. Endpoint: Admin Update Challenge

### Endpoint Name

Admin Update Challenge

### HTTP Method

`PUT`

### URL Path

`/admin/challenges/{challenge_id}`

### Auth Required

Yes

### Role Required (Player/Admin)

Admin

### Description

Updates mutable challenge metadata and optionally replaces the challenge’s active valid flags. Writes an admin audit log entry.

### Request Body Schema

```json
{
  "track_id": "uuid",
  "slug": "string",
  "title": "string",
  "description": "string",
  "difficulty": "easy | medium | hard",
  "xp_reward": 100,
  "order_index": 1,
  "attachments": [
    {
      "display_name": "string",
      "file_name": "string",
      "download_path": "string",
      "content_type": "string | null",
      "size_bytes": 12345
    }
  ],
  "flag_update": {
    "mode": "unchanged | replace_all",
    "flags": [
      "plaintext_flag_string"
    ]
  }
}
```

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "challenge": {
      "id": "uuid",
      "track_id": "uuid",
      "slug": "string",
      "title": "string",
      "difficulty": "hard",
      "xp_reward": 200,
      "order_index": 2,
      "is_published": true,
      "published_at": "timestamp | null",
      "attachment_count": 2,
      "updated_at": "timestamp"
    }
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `403 Forbidden` -> `auth.forbidden`
- `404 Not Found` -> `resource.not_found`
- `409 Conflict` -> `resource.conflict` (slug/order conflict)
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Admin role check required server-side.
- `flag_update.flags` are sensitive and must not be logged or returned.
- Response must never include hashed/plaintext flags.
- Updates affecting published challenges must be audit-logged with redacted change summary.

### Notes

- `flag_update.mode = unchanged` means current active flags remain unchanged.
- `flag_update.mode = replace_all` replaces active flags with the supplied new set (hashed on server).

## 14. Endpoint: Admin Publish/Unpublish Challenge

### Endpoint Name

Admin Publish/Unpublish Challenge

### HTTP Method

`PATCH`

### URL Path

`/admin/challenges/{challenge_id}/publish`

### Auth Required

Yes

### Role Required (Player/Admin)

Admin

### Description

Changes challenge publication state. Publishing requires valid metadata and at least one active valid flag.

### Request Body Schema

```json
{
  "is_published": true
}
```

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "challenge": {
      "id": "uuid",
      "is_published": true,
      "published_at": "timestamp | null",
      "updated_at": "timestamp"
    }
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `403 Forbidden` -> `auth.forbidden`
- `404 Not Found` -> `resource.not_found`
- `422 Unprocessable Entity` -> `challenge.publish_precondition_failed`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Admin role check required server-side.
- Publish/unpublish actions must be audit-logged.
- Player visibility must update immediately after publication state change commit.

### Notes

- Idempotent behavior is recommended:
  - Publishing an already published challenge returns success with unchanged state.
  - Unpublishing an already unpublished challenge returns success with unchanged state.

## 15. Endpoint: Get Admin Logs

### Endpoint Name

Get Admin Logs

### HTTP Method

`GET`

### URL Path

`/admin/logs`

### Auth Required

Yes

### Role Required (Player/Admin)

Admin

### Description

Returns paginated admin audit logs for challenge management and role change actions.

### Request Body Schema

None

### Query Parameters (if any)

```json
{
  "page": "integer, optional, default=1, min=1",
  "page_size": "integer, optional, default=20, min=1, max=100",
  "action_type": "string, optional",
  "actor_user_id": "uuid, optional",
  "challenge_id": "uuid, optional",
  "affected_user_id": "uuid, optional",
  "date_from": "timestamp, optional",
  "date_to": "timestamp, optional"
}
```

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "actor_user": {
          "id": "uuid",
          "username": "string"
        },
        "action_type": "challenge_update",
        "target": {
          "target_type": "challenge",
          "challenge_id": "uuid",
          "user_id": null,
          "role": null
        },
        "is_success": true,
        "change_summary": "Updated difficulty and XP reward.",
        "request_id": "string | null",
        "created_at": "timestamp"
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total_items": 500,
      "total_pages": 25
    }
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `403 Forbidden` -> `auth.forbidden`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Admin role check required server-side.
- Log content must be redacted (no flags, password hashes, tokens, or secrets).
- Filter parameters must be validated to avoid abuse and broad unintended exposure.

### Notes

- This endpoint is for admin audit review only.
- Returned logs are append-only records; editing/deleting logs is out of scope for MVP.

## 16. Endpoint: Admin Change User Role

### Endpoint Name

Admin Change User Role

### HTTP Method

`PATCH`

### URL Path

`/admin/users/{user_id}/role`

### Auth Required

Yes

### Role Required (Player/Admin)

Admin

### Description

Assigns or removes the `admin` role for a target user. Regular users cannot call this endpoint.

### Request Body Schema

```json
{
  "role": "admin",
  "action": "assign | remove"
}
```

### Query Parameters (if any)

None

### Response Schema (Success)

Success status: `200 OK`

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "string",
      "roles": ["player", "admin"],
      "is_active": true
    },
    "role_change": {
      "role": "admin",
      "action": "assign",
      "effective_on": "next_token_refresh_or_login"
    }
  },
  "error": null
}
```

### Error Responses

- `400 Bad Request` -> `validation.invalid_request`
- `401 Unauthorized` -> `auth.unauthorized` or `auth.session_expired`
- `403 Forbidden` -> `auth.forbidden`
- `404 Not Found` -> `resource.not_found`
- `409 Conflict` -> `resource.conflict` (role already assigned / not assigned)
- `422 Unprocessable Entity` -> `role.operation_not_allowed`
- `500 Internal Server Error` -> `server.internal_error`

### Security Considerations

- Admin role check required server-side.
- Regular users must never be able to assign admin privileges.
- Role changes must be audit-logged with actor and target details.
- Sensitive user data must not be returned.

### Notes

- MVP scope supports `role = "admin"` only through this endpoint.
- `player` is the default role and is not managed here as a general-purpose role editor.

## 5. Cross-Endpoint Security and Consistency Requirements

### Hidden Challenge Protection

- `GET /challenges/{challenge_id}` and `POST /challenges/{challenge_id}/submit` must return `404 resource.not_found` when the user is not authorized to access the challenge, including unpublished player access attempts.
- Do not disclose whether the challenge exists in unauthorized cases.

### Flag Validation Confidentiality

- No endpoint may return plaintext flags or hashed flags.
- `POST /challenges/{challenge_id}/submit` must not reveal validation internals or partial-match hints.

### XP Integrity

- XP awards occur only through successful first-time flag submissions.
- Duplicate submissions must not create duplicate XP rewards.
- XP award, XP history, and leaderboard-relevant XP aggregate updates must commit atomically.

### Leaderboard Trust

- `GET /leaderboard` must use trusted XP data only (no client-calculated values).
- Ranking order must be deterministic:
  - `total_xp` descending
  - tie-breaker completion timestamp ascending
  - deterministic internal final tie-break (not required in response payload)

### Admin Enforcement

- All `/admin/*` endpoints require valid JWT + `admin` role.
- Admin audit logs are required for challenge mutations and role changes.

## 6. Non-MVP API Endpoints (Explicitly Excluded)

Not included in MVP contract:

- Dynamic lab lifecycle endpoints
- Docker/container orchestration endpoints
- Team management endpoints
- Hint marketplace endpoints
- Payments/subscription endpoints
- In-platform AI assistant endpoints
- Advanced analytics/reporting endpoints
- SOC/SIEM ingestion/export endpoints
- General file upload service endpoints (beyond simple attachment metadata references in admin challenge APIs)

## 7. Change Control

- Any endpoint addition, removal, path change, response field change, error code change, or authorization behavior change requires an update to this document before implementation is considered complete.
- Backward-incompatible changes require explicit versioning or a documented migration plan.
