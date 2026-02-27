# ZeroTrace CTF - BACKEND_FOLDER_STRUCTURE (MVP)

## Scope

This document defines the backend folder layout, layer boundaries, and module responsibilities for the ZeroTrace CTF MVP.

In scope:

- Authentication
- Role-based access
- Track management (read/list for MVP player flows)
- Challenge engine (static challenge delivery)
- Flag validation
- XP system
- Leaderboard
- Admin panel backend endpoints
- Admin logs

Out of scope for MVP backend structure:

- Docker labs
- SOC ingestion
- Microservices decomposition
- Distributed workers

## Critical Rules (Non-Negotiable)

- No business logic in routes.
- No direct DB calls from controllers.
- XP logic isolated in XP service.
- Flag validation isolated in submission/challenge service boundary.
- Admin logic isolated and auditable.
- All cross-module interaction via service layer.
- Avoid circular dependencies.

## 1. Architectural Overview

### Layered Architecture Explanation

The MVP backend uses a single-service, layered architecture with feature modules.

Design model:

- `Route layer` -> HTTP endpoint registration only
- `Controller layer` -> request/response orchestration only
- `Service layer` -> business logic and workflow orchestration
- `Repository/data access layer` -> database access only
- `Model layer` -> persistence entity mappings and data contracts
- `Middleware/security layer` -> cross-cutting auth, authorization, rate limiting, request security
- `Validation layer` -> request schema validation and input normalization boundaries

Feature modules (Auth, Challenge, Submission, XP, Admin, etc.) own their controllers/services/schemas, while shared infrastructure (config, security, repositories, logging) is centralized.

### Why Separation Matters

- Prevents endpoint handlers from accumulating business logic.
- Makes security controls reusable and consistent.
- Keeps database access patterns controlled and reviewable.
- Enables transaction boundaries to be owned by services, not scattered across routes/controllers.
- Reduces accidental coupling between unrelated features.

### How This Prevents Security Issues

- Centralized auth/authorization middleware reduces inconsistent access checks.
- Isolated flag validation logic reduces risk of duplicated, incorrect validation code.
- Isolated XP service reduces duplicate reward bugs and race-condition vulnerabilities.
- Repository-only DB access reduces mass assignment and unauthorized field updates.
- Admin-only logic in a dedicated module improves audit coverage and reviewability.

## 2. Root Folder Structure (Tree Format)

The following is the approved MVP backend structure.

```text
backend/
│
├── src/
│   │
│   ├── main/
│   │   ├── server-entry
│   │   ├── app-bootstrap
│   │   └── route-registration
│   │
│   ├── app/
│   │   ├── routes/
│   │   │   └── index
│   │   ├── controllers/
│   │   │   └── health-controller (optional internal endpoint only)
│   │   ├── middleware/
│   │   │   ├── request-id
│   │   │   ├── error-handler
│   │   │   └── not-found-handler
│   │   ├── errors/
│   │   │   ├── error-codes
│   │   │   ├── domain-errors
│   │   │   └── error-mapper
│   │   └── presenters/
│   │       ├── response-envelope
│   │       └── pagination-presenter
│   │
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── routes/
│   │   │   ├── controllers/
│   │   │   ├── services/
│   │   │   ├── schemas/
│   │   │   ├── dto/
│   │   │   └── presenters/
│   │   │
│   │   ├── users/
│   │   │   ├── services/
│   │   │   ├── schemas/
│   │   │   ├── dto/
│   │   │   └── presenters/
│   │   │
│   │   ├── tracks/
│   │   │   ├── routes/
│   │   │   ├── controllers/
│   │   │   ├── services/
│   │   │   ├── schemas/
│   │   │   ├── dto/
│   │   │   └── presenters/
│   │   │
│   │   ├── challenges/
│   │   │   ├── routes/
│   │   │   ├── controllers/
│   │   │   ├── services/
│   │   │   ├── schemas/
│   │   │   ├── dto/
│   │   │   ├── presenters/
│   │   │   └── policies/
│   │   │
│   │   ├── submissions/
│   │   │   ├── routes/
│   │   │   ├── controllers/
│   │   │   ├── services/
│   │   │   │   ├── submission-service
│   │   │   │   ├── flag-validation-service
│   │   │   │   └── abuse-detection-service
│   │   │   ├── schemas/
│   │   │   ├── dto/
│   │   │   ├── presenters/
│   │   │   └── policies/
│   │   │
│   │   ├── xp/
│   │   │   ├── services/
│   │   │   │   ├── xp-award-service
│   │   │   │   ├── xp-query-service
│   │   │   │   └── xp-integrity-service
│   │   │   ├── schemas/
│   │   │   ├── dto/
│   │   │   ├── presenters/
│   │   │   └── policies/
│   │   │
│   │   ├── leaderboard/
│   │   │   ├── routes/
│   │   │   ├── controllers/
│   │   │   ├── services/
│   │   │   ├── schemas/
│   │   │   ├── dto/
│   │   │   └── presenters/
│   │   │
│   │   ├── admin/
│   │   │   ├── routes/
│   │   │   ├── controllers/
│   │   │   ├── services/
│   │   │   │   ├── admin-challenge-service
│   │   │   │   ├── admin-role-service
│   │   │   │   └── admin-log-query-service
│   │   │   ├── schemas/
│   │   │   ├── dto/
│   │   │   ├── presenters/
│   │   │   └── policies/
│   │   │
│   │   └── audit/
│   │       ├── services/
│   │       │   ├── admin-audit-service
│   │       │   └── security-event-service
│   │       ├── schemas/
│   │       └── dto/
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── user-model
│   │   │   ├── challenge-model
│   │   │   ├── challenge-attempt-model
│   │   │   ├── user-xp-model
│   │   │   ├── xp-history-model
│   │   │   └── admin-log-model
│   │   ├── repositories/
│   │   │   ├── user-repository
│   │   │   ├── role-repository
│   │   │   ├── track-repository
│   │   │   ├── challenge-repository
│   │   │   ├── challenge-flag-repository
│   │   │   ├── challenge-attempt-repository
│   │   │   ├── user-xp-repository
│   │   │   ├── xp-history-repository
│   │   │   └── admin-log-repository
│   │   ├── mappers/
│   │   │   ├── db-to-domain
│   │   │   └── domain-to-db
│   │   ├── transactions/
│   │   │   ├── transaction-manager
│   │   │   └── transaction-context
│   │   └── query-builders/
│   │       └── leaderboard-query
│   │
│   ├── common/
│   │   ├── middleware/
│   │   │   ├── auth-required
│   │   │   ├── role-required
│   │   │   ├── rate-limit
│   │   │   ├── request-logging
│   │   │   └── input-size-limits
│   │   ├── security/
│   │   │   ├── jwt/
│   │   │   │   ├── token-verifier
│   │   │   │   └── token-claims
│   │   │   ├── authorization/
│   │   │   │   ├── role-guard
│   │   │   │   └── resource-access-policy
│   │   │   ├── flags/
│   │   │   │   ├── flag-normalizer
│   │   │   │   ├── flag-hash-service
│   │   │   │   └── constant-time-compare
│   │   │   ├── passwords/
│   │   │   │   └── password-hash-service
│   │   │   └── request-signals/
│   │   │       ├── source-fingerprint
│   │   │       └── abuse-threshold-policy
│   │   ├── validation/
│   │   │   ├── request-schemas/
│   │   │   ├── schema-errors/
│   │   │   └── normalizers/
│   │   ├── logging/
│   │   │   ├── app-logger
│   │   │   ├── audit-logger-adapter
│   │   │   └── redaction-rules
│   │   ├── errors/
│   │   │   ├── error-types
│   │   │   └── safe-error-presenter
│   │   ├── utils/
│   │   │   ├── time
│   │   │   ├── pagination
│   │   │   └── ids
│   │   └── types/
│   │       ├── request-context
│   │       ├── auth-context
│   │       └── pagination-types
│   │
│   └── config/
│       ├── env/
│       ├── app/
│       ├── security/
│       ├── database/
│       └── logging/
│
├── migrations/
│   ├── versions/
│   └── migration-metadata
│
├── tests/
│   ├── unit/
│   │   ├── modules/
│   │   ├── common/
│   │   └── data/
│   ├── integration/
│   │   ├── api/
│   │   ├── modules/
│   │   └── transactions/
│   ├── contract/
│   │   └── api/
│   ├── security/
│   │   ├── auth/
│   │   ├── authorization/
│   │   ├── submissions/
│   │   └── admin/
│   ├── abuse/
│   │   └── submissions/
│   ├── fixtures/
│   │   ├── users/
│   │   ├── tracks/
│   │   ├── challenges/
│   │   └── xp/
│   ├── factories/
│   ├── helpers/
│   └── stubs/
│
├── scripts/
│   ├── seed/
│   ├── maintenance/
│   └── verification/
│
├── docs/
│   └── backend/
│
└── README (backend-specific operational notes)
```

## 3. Layer Responsibilities

This section defines what each layer/folder is responsible for and what it must not contain.

### 3.1 `src/main/` (Entry and Bootstrap)

#### Purpose

- Application startup
- Dependency wiring
- Global route registration
- Startup validation and shutdown hooks

#### Allowed Inside

- Startup orchestration
- Module registration
- Configuration loading coordination
- Global middleware registration order

#### Not Allowed Inside

- Business logic
- Domain decisions
- Direct SQL/domain queries
- Endpoint-specific logic

#### Dependency Direction Rules

- May depend on `config`, `app`, `modules`, `common`, `data`
- No other layer should depend on `src/main`

### 3.2 `src/app/routes/` (Global Route Composition)

#### Purpose

- Compose module routes into a single application route tree
- Apply global prefixes/versioning (if used)

#### Allowed Inside

- Route registration
- Global route grouping
- Middleware attachment at route-group level

#### Not Allowed Inside

- Validation logic
- Business logic
- Database calls
- Authorization decisions beyond attaching middleware

#### Dependency Direction Rules

- Depends on module `routes/` and shared middleware only
- Must not depend on repositories directly

### 3.3 `src/modules/*/routes/` (Feature Route Layer)

#### Purpose

- Define endpoint paths and bind them to controllers

#### Allowed Inside

- Route path definitions
- HTTP method bindings
- Route-scoped middleware assignment
- Controller method binding

#### Not Allowed Inside

- Business logic
- DB access
- XP calculations
- Flag validation

#### Dependency Direction Rules

- `routes` -> `controllers`, `common/middleware`, `module schemas`
- Never `routes` -> `repositories`

### 3.4 `src/modules/*/controllers/` and `src/app/controllers/` (Controller Layer)

#### Purpose

- Translate HTTP requests into service calls
- Perform request-to-service DTO mapping
- Return standardized response envelopes

#### Allowed Inside

- Request parsing and orchestration
- Input schema invocation (if not handled in middleware)
- Response formatting/presenter calls
- Error propagation to global handler

#### Not Allowed Inside

- Business rules
- Security policy decisions (beyond invoking guard outcomes)
- Transaction management
- Direct database access

#### Dependency Direction Rules

- `controllers` -> `services`, `schemas`, `dto`, `presenters`
- Never `controllers` -> `repositories` or `models`

### 3.5 `src/modules/*/services/` (Business Logic Layer)

#### Purpose

- Own domain workflows and business rules
- Orchestrate repository calls
- Coordinate cross-module operations through service interfaces
- Own transactional boundaries (via transaction manager)

#### Allowed Inside

- Domain decisions
- Authorization checks that depend on domain state
- Orchestration of validation/normalization/security utilities
- Transaction orchestration
- Audit event emission

#### Not Allowed Inside

- Raw HTTP request/response handling
- Route registration
- Direct serialization decisions for response envelopes
- Hardcoded environment configuration

#### Dependency Direction Rules

- `services` -> `repositories`, `models` (via mappers/contracts), `common/security`, `common/utils`, other module public services
- Never `services` -> `routes`
- Cross-module calls must target service interfaces, not repositories

### 3.6 `src/data/repositories/` (Data Access Layer)

#### Purpose

- Encapsulate all database reads/writes
- Provide query methods to services
- Enforce data access consistency and mapping boundaries

#### Allowed Inside

- Query execution
- Persistence mapping
- Transaction-context-aware DB operations
- Repository-level filtering and lookup methods

#### Not Allowed Inside

- Business rules (XP award eligibility, role policy, challenge visibility policy)
- HTTP logic
- Response formatting

#### Dependency Direction Rules

- `repositories` -> `data/models`, `data/mappers`, `data/transactions`
- Never `repositories` -> `controllers`, `routes`, `presenters`

### 3.7 `src/data/models/` (Persistence Models)

#### Purpose

- Define persistence entity structures and database-facing model shapes

#### Allowed Inside

- Entity definitions
- Field-level persistence typing/metadata
- Minimal model constraints metadata (if applicable)

#### Not Allowed Inside

- Business workflows
- HTTP concerns
- Security policies

#### Dependency Direction Rules

- Consumed by repositories and mappers
- Must not depend on controllers/services

### 3.8 `src/data/transactions/` (Transaction Boundary Infrastructure)

#### Purpose

- Provide transaction manager and transaction context abstraction
- Ensure service-owned transactions are consistent across repositories

#### Allowed Inside

- Transaction lifecycle management
- Transaction context propagation utilities

#### Not Allowed Inside

- Feature business logic
- XP rules
- Admin policies

#### Dependency Direction Rules

- Used by services and repositories
- Must not depend on feature modules

### 3.9 `src/common/middleware/` and `src/app/middleware/` (Middleware Layer)

#### Purpose

- Apply cross-cutting request processing and security controls

#### Allowed Inside

- Auth-required checks
- Role-required checks (generic middleware wrapper)
- Rate limiting hooks
- Request logging
- Error handling
- Request ID assignment
- Input size limits

#### Not Allowed Inside

- Feature business logic
- DB queries unrelated to auth/security middleware requirements
- XP logic
- Flag validation

#### Dependency Direction Rules

- `middleware` -> `common/security`, `common/logging`, minimal service interfaces where necessary
- Must not depend on repositories directly unless explicitly designated auth context loader (avoid if possible)

### 3.10 `src/common/security/` (Security Utilities)

#### Purpose

- Centralize reusable security primitives and policies

#### Allowed Inside

- JWT verification helpers
- Role/resource policy helpers
- Password hashing utilities
- Flag normalization/hashing/comparison utilities
- Source fingerprint derivation and abuse policy primitives

#### Not Allowed Inside

- HTTP routing/controller code
- Endpoint-specific business workflows
- Direct persistence writes (except if explicitly isolated crypto adapters, still discouraged)

#### Dependency Direction Rules

- Used by middleware and services
- Must not depend on module routes/controllers

### 3.11 `src/common/validation/` and `src/modules/*/schemas/` (Validation Layer)

#### Purpose

- Define request schemas and normalization rules
- Enforce input contracts before service execution

#### Allowed Inside

- Request/DTO schemas
- Input normalizers
- Validation error mapping helpers

#### Not Allowed Inside

- Business decisions
- DB access
- Cross-module orchestration

#### Dependency Direction Rules

- Consumed by routes/controllers/services
- Must not depend on repositories

### 3.12 `src/common/logging/` and `src/modules/audit/` (Logging and Audit)

#### Purpose

- `common/logging`: operational application logging and redaction rules
- `modules/audit`: domain audit events (admin actions, security events)

#### Allowed Inside

- Log adapters
- Redaction policy
- Audit event creation services
- Audit query services (via admin module orchestration)

#### Not Allowed Inside

- Core business workflows unrelated to logging/audit
- Raw controller logic

#### Dependency Direction Rules

- `common/logging` used by all layers
- `audit` services called by feature services
- `audit` uses repositories, not controllers

### 3.13 `src/config/` (Configuration Layer)

#### Purpose

- Centralize environment and runtime configuration loading/validation

#### Allowed Inside

- Configuration schemas
- Config grouping (app/security/database/logging)
- Safe config accessors

#### Not Allowed Inside

- Business logic
- DB queries
- Request handling

#### Dependency Direction Rules

- `config` can be consumed by all runtime layers
- `config` should not depend on feature modules

### 3.14 `tests/` (Test Layer)

#### Purpose

- Organize unit, integration, contract, security, and abuse tests with shared fixtures

#### Allowed Inside

- Tests
- Fixtures
- Factories
- Helpers/stubs

#### Not Allowed Inside

- Production runtime logic
- Environment-specific secrets

#### Dependency Direction Rules

- Tests depend on production modules
- Production modules must never depend on `tests/`

## 4. Security Boundaries

### Where JWT Validation Lives

- Primary location: `src/common/security/jwt/`
- Request enforcement integration: `src/common/middleware/auth-required`
- Role/context resolution should be attached to request context after JWT validation

Rule:

- Controllers and services consume authenticated context; they do not parse JWTs directly.

### Where Role Enforcement Lives

- Generic role gate middleware: `src/common/middleware/role-required`
- Reusable role/resource policy helpers: `src/common/security/authorization/`
- Domain-sensitive authorization checks (for example unpublished challenge visibility) live in feature services using policy helpers

Rule:

- Route-level role middleware handles coarse access (`admin` vs `player`)
- Service-level checks handle resource-level access decisions

### Where Flag Hashing Logic Lives

- Security primitive and normalization functions: `src/common/security/flags/`
- Submission flow orchestration and validation outcome handling: `src/modules/submissions/services/flag-validation-service`

Rule:

- No controller or route may implement flag hashing/comparison.
- No other module should duplicate flag comparison logic.

### Where XP Atomic Transaction Logic Lives

- XP award transaction orchestration: `src/modules/xp/services/xp-award-service`
- Transaction infrastructure: `src/data/transactions/`
- Repository writes used within the transaction:
  - challenge attempt/completion marker
  - `xp_history`
  - `user_xp`

Rule:

- XP transaction boundaries are service-owned.
- Controllers/routes cannot open or manage XP transactions.

### Where Admin Audit Logging Lives

- Audit event creation and persistence: `src/modules/audit/services/admin-audit-service`
- Admin workflow services (in `src/modules/admin/services/`) must call audit service for all privileged mutations

Rule:

- Audit logging is mandatory for admin challenge mutations and role changes.
- Admin controllers must not write audit logs directly.

## 5. Module Breakdown

The MVP uses explicit module boundaries. Cross-module calls must go through service interfaces.

## 5.1 Auth Module (`src/modules/auth`)

### Responsibilities

- Register, login, logout, and `auth/me` workflows
- Credential verification orchestration
- Session/auth context creation
- Account active-state checks during auth flows

### Public Interfaces

- Register user
- Login user
- Logout user
- Get current authenticated user context

### Dependencies

- User Module (user lookup/create support)
- Common Security (password hashing, JWT)
- Audit Module (security event logging, failed login logging if routed there)
- Repositories (`users`, `roles`, `user_roles`, session-related state if used)

## 5.2 User Module (`src/modules/users`)

### Responsibilities

- User profile retrieval (MVP internal/supporting usage)
- Role assignments read support for auth/RBAC context
- Account active state management support (non-admin user-management UI is not MVP)

### Public Interfaces

- Get user by ID/email/username (service-level)
- Get user roles
- Check active status
- Apply role assignment/removal support (admin-driven)

### Dependencies

- Repositories (`users`, `roles`, `user_roles`)
- Common Security (normalization helpers if needed)
- Audit Module (for role change logging via Admin Module orchestration)

## 5.3 Track Module (`src/modules/tracks`)

### Responsibilities

- Track listing
- Track detail retrieval
- Track access-state evaluation (available/locked) for player views
- Track ordering and progress summary composition

### Public Interfaces

- List tracks for user
- Get track detail for user
- Evaluate track accessibility

### Dependencies

- Challenge Module (published challenge counts)
- XP Module (progress data if unlock logic uses progression)
- Repositories (`tracks`, challenge summary reads)
- Common Authorization policies (resource visibility rules)

## 5.4 Challenge Module (`src/modules/challenges`)

### Responsibilities

- Challenge list/detail retrieval for player and admin-consumable read paths
- Published/unpublished visibility enforcement (service layer)
- Attachment metadata exposure rules
- Challenge metadata read support for submissions and XP flows

### Public Interfaces

- List challenges in track (published player view)
- Get challenge detail with user completion state
- Get challenge metadata for submission/XP workflows
- Admin-facing challenge read helpers (draft/published)

### Dependencies

- Repositories (`challenges`, `challenge_flags` metadata only when needed, attachment metadata repository if separate, `challenge_attempts` summaries)
- Track Module (track access checks, or shared policy helper)
- XP Module (completion state summaries via query service)
- Common Authorization/resource access policy

## 5.5 Submission Module (`src/modules/submissions`) [Mandatory for Flag Isolation]

### Responsibilities

- Flag submission workflow orchestration
- Flag normalization and validation invocation
- Attempt logging (correct/incorrect/blocked)
- Abuse checks (rate/cooldown policy integration)
- Delegation to XP Module for first-correct award

### Public Interfaces

- Submit flag for challenge
- Validate flag (service-internal/public to module)
- Evaluate submission abuse state

### Dependencies

- Challenge Module (challenge access + metadata)
- XP Module (award XP on first correct solve)
- Audit Module (security event logging / suspicious patterns if applicable)
- Repositories (`challenge_attempts`, challenge read repositories)
- Common Security (`flags`, authorization, request signals)
- Common Middleware outputs (auth context, request metadata)

## 5.6 XP Module (`src/modules/xp`)

### Responsibilities

- XP award transaction orchestration
- Duplicate XP prevention
- XP aggregate query (`user_xp`)
- XP history query (`xp_history`)
- XP integrity/reconciliation support (MVP internal/admin/maintenance)

### Public Interfaces

- Award XP for validated first solve (atomic)
- Get current user XP summary
- Check completion/award status for user-challenge
- Reconcile/validate XP integrity (internal service)

### Dependencies

- Repositories (`user_xp`, `xp_history`, `challenge_attempts`)
- Transaction Manager
- Challenge Module (XP source metadata when needed)
- Common Utilities (time, ids)
- Audit Module (security/integrity event logging for anomalies)

## 5.7 Leaderboard Module (`src/modules/leaderboard`)

### Responsibilities

- Leaderboard query and pagination
- Deterministic sorting using trusted XP aggregate data
- Response shaping for public-safe leaderboard rows

### Public Interfaces

- Get paginated leaderboard
- Get user rank context (optional internal helper)

### Dependencies

- XP Module query service or `user_xp` repository (via service boundary preferred)
- User Module (username and active-state filtering support)
- Repositories/query builders for leaderboard reads

## 5.8 Admin Module (`src/modules/admin`)

### Responsibilities

- Admin challenge create/edit/publish/unpublish workflows
- Admin role assignment/removal workflows
- Admin log retrieval orchestration (via Audit Module)
- Admin-only business rules and validation orchestration

### Public Interfaces

- Create challenge
- Update challenge
- Publish/unpublish challenge
- Change user role
- List admin logs

### Dependencies

- Challenge Module (shared challenge read logic where appropriate)
- User Module (target user and role operations)
- Audit Module (mandatory audit logging)
- XP Module (read-only checks for XP-related challenge change policy, e.g., XP change restrictions)
- Repositories (admin-only write paths through repositories)
- Transaction Manager (admin mutations + audit logging)

## 5.9 Audit Module (`src/modules/audit`) [Admin Logs + Security Event Support]

### Responsibilities

- Admin audit event creation and persistence
- Security event logging support (failed logins, suspicious submissions, etc., if stored in DB-backed events)
- Audit query primitives for Admin Module

### Public Interfaces

- Record admin action
- Record security event
- Query admin audit logs

### Dependencies

- Repositories (`admin_logs` and optional security-event storage)
- Common Logging (redaction + operational logging integration)
- Common Utilities (time, request IDs)

## 5.10 Logging Module (`src/common/logging`) [Cross-Cutting]

### Responsibilities

- Operational application logging
- Error logging helpers
- Redaction rules for sensitive fields
- Request correlation support

### Public Interfaces

- Create/request logger
- Structured info/warn/error logging
- Redacted payload logging helpers

### Dependencies

- Config (logging configuration)
- Common types and utilities

## 6. Transaction Management Strategy

### Where Transactions Are Handled

- Transactions are initiated and owned by services only.
- Transaction infrastructure lives in `src/data/transactions/`.
- Repositories must accept a transaction context so multiple repository calls participate in the same atomic unit.

### Preventing Partial Writes

Transaction-required workflows (MVP minimum):

- Flag submission -> first correct solve -> XP award
- Admin challenge create/edit + flag updates + audit log write
- Admin role change + audit log write

Rules:

- If any required write fails, the full transaction is rolled back.
- No controller may continue response success after a partial write.
- Audit-critical operations must fail if required audit log write fails (per MVP policy).

### Service-Level Atomicity Rules

- `xp-award-service` owns XP-related atomic transaction boundaries.
- `admin-challenge-service` owns challenge mutation + audit log transaction boundaries.
- `admin-role-service` owns role change + audit log transaction boundaries.
- Submission service may orchestrate workflow but delegates XP transaction ownership to XP service.

### Nested Transaction Rule

- Avoid nested unmanaged transactions.
- If a service calls another service within a transaction, the transaction context must be explicitly propagated.
- The outermost orchestration service owns commit/rollback decisions.

## 7. Validation Layer Strategy

### Request Validation

- Request shape validation occurs at the route/controller boundary using module-specific schemas.
- Invalid requests must fail before service business logic runs.
- Error mapping to safe API errors is centralized.

### Input Normalization

- General normalization (trim, case-normalize identifiers, pagination bounds) occurs before service execution.
- Security-sensitive normalization (flag normalization) is owned by the Submission/Flag Validation service and common flag security utilities.
- Normalization rules must be deterministic and shared, not reimplemented per controller.

### Preventing Mass Assignment

- Controllers map request payloads into explicit service DTOs.
- Services accept only whitelisted fields required for the operation.
- Repositories persist explicit field sets; they do not accept raw request payloads.
- Admin update flows must explicitly control mutable fields (for example: no implicit updates to hidden or audit-sensitive fields).

### Schema Separation

Use separate schema/contract layers for:

- HTTP request schemas (`modules/*/schemas`)
- Service DTOs (`modules/*/dto`)
- Persistence models (`data/models`)

Rule:

- Do not reuse persistence models as request schemas.
- Do not bind request bodies directly to DB models.

## 8. Testing Folder Strategy

### Unit Tests Structure

Location:

- `tests/unit/modules/`
- `tests/unit/common/`
- `tests/unit/data/`

Coverage focus:

- Service business logic (XP, submission, RBAC policy paths)
- Flag normalization/validation helpers
- Authorization policy helpers
- Leaderboard sorting logic
- Error mapping and validation behavior

### Integration Tests Structure

Location:

- `tests/integration/api/`
- `tests/integration/modules/`
- `tests/integration/transactions/`

Coverage focus:

- End-to-end API behavior for MVP endpoints
- Multi-repository transaction behavior
- Hidden challenge access rules
- XP atomicity and duplicate prevention
- Admin mutations + audit logs

### Test Fixtures

Location:

- `tests/fixtures/`

Contents:

- Seed users (player/admin/inactive)
- Tracks (Linux/Networking/Crypto)
- Published/unpublished challenges
- XP history and aggregate states
- Admin logs and challenge attempts for query tests

Rules:

- Fixtures must be deterministic.
- Fixtures must not contain real secrets or production data.

### Mock Strategy

- Unit tests may mock repositories and cross-module service interfaces.
- Integration tests should avoid mocking repositories for transaction-critical flows.
- Security and abuse tests should test real middleware/service interactions where possible.
- Mock only at stable boundaries; avoid mocking internal functions of the unit under test.

## 9. Naming Conventions

### File Naming

- Use lowercase `kebab-case` for files and folders.
- Use singular file names for single responsibilities (`xp-award-service`, `user-repository`).
- Use plural folder names for collections/domains (`users`, `challenges`, `repositories`).

### Class Naming (If Class-Based Components Are Used)

- Use `PascalCase`.
- Suffix by responsibility:
  - `Controller`
  - `Service`
  - `Repository`
  - `Middleware`
  - `Policy`
  - `Presenter`

### Service Naming

- Name services by business responsibility, not transport or framework concern.
- Preferred examples:
  - `XpAwardService`
  - `SubmissionService`
  - `AdminChallengeService`
  - `AdminAuditService`

Avoid:

- Generic names like `HelperService`, `CommonService`, `DataService`.

### Route Naming

- Route files should map to resource groups and align with API contract nouns.
- Route paths remain REST-oriented and deterministic.
- Do not encode business rules in route names.

Examples of route grouping intent (not implementation):

- Auth routes
- Track routes
- Challenge routes
- Submission routes
- Leaderboard routes
- Admin routes

## 10. Future Scalability Considerations

### How Docker Lab Module Would Plug In Later

Add new modules without disturbing MVP core:

- `src/modules/labs/` (lab lifecycle orchestration API)
- `src/modules/lab-sessions/` (user lab session state)
- `src/modules/lab-artifacts/` (lab-specific outputs/logs)

Rules for integration:

- Lab modules must consume Auth/RBAC via shared middleware and service interfaces.
- Lab modules must not embed XP logic; they submit completion outcomes through XP service boundaries.
- Lab execution infrastructure must remain isolated from the core API process in future phases.

### How SOC Ingestion Could Integrate Later

Add dedicated modules (future):

- `src/modules/telemetry-ingestion/`
- `src/modules/detections/`
- `src/modules/incident-scenarios/`

Rules for integration:

- Ingestion paths must remain isolated from core player-facing request paths.
- Do not couple SOC ingestion schemas to challenge delivery schemas.
- Reuse audit/logging infrastructure patterns, not direct feature coupling.

### How to Avoid Monolithic Sprawl

- Keep cross-module dependencies one-directional and reviewed.
- Enforce service interfaces as the only module integration surface.
- Do not allow modules to call each other’s repositories directly.
- Extract shared utilities only when truly cross-cutting; avoid dumping domain logic into `common/`.
- Periodically review module boundaries as features expand.

### Scaling Boundary Rule

- Add new features as modules, not as scattered route/controller/service files across unrelated folders.
- If a module grows too large, split it into submodules with explicit interfaces before introducing a separate service.

## Governance Rule

- Any change to backend layer boundaries, security control placement, transaction ownership, or cross-module dependency rules must update this document before implementation is considered complete.
