# ZeroTrace CTF - TECH_STACK (MVP Approved)

## Scope and Approval Rule

This document defines the approved MVP technology stack for ZeroTrace CTF.

Future implementation decisions must stay within this list unless a change is explicitly justified and approved.

This document covers the MVP only:

- Authentication
- Dashboard
- Static challenge engine
- XP system
- 3 tracks (Linux, Networking, Crypto)
- Leaderboard
- Admin panel

Excluded from this document and MVP:

- Docker labs
- Virtualization engines
- Dynamic lab orchestration
- Advanced cloud deployment patterns

## 1. Architecture Overview

### High-Level Structure

The MVP uses a three-layer architecture with strict separation of concerns:

- Frontend: SPA for user and admin interfaces
- Backend: REST API for authentication, challenge delivery, submissions, scoring, leaderboard, and admin operations
- Database: Persistent relational store for users, challenges, solves, XP, leaderboard data, and audit logs

### API-Based Architecture

- Frontend communicates with backend only through HTTP APIs.
- No server-rendered business logic is required for MVP.
- Admin panel uses the same API boundary as the user-facing frontend, with role-based restrictions.

### Stateless Backend

- The backend is stateless for application requests.
- Authentication state is carried by JWTs, not server-side sessions.
- No in-memory user session store is used.
- Refresh-token rotation metadata may be persisted in the database; this is not a server-side session store.

### Role-Based Access Control (RBAC)

MVP roles:

- `user`: solve challenges, view dashboard, leaderboard, and progression
- `admin`: challenge creation/management and administrative visibility

RBAC is enforced in the backend API, not only in the frontend UI.

## 2. Frontend

### Approved Technologies

- `React` (TypeScript)
- `Vite` (build tool and dev server)
- `React Router` (routing)
- `TanStack Query` (server-state management and caching)
- `Zustand` (minimal client-side UI/auth state)
- `React Hook Form` (form state and submission handling)
- `Zod` (schema validation for forms and API payload shaping)
- `Axios` (HTTP client)
- `Tailwind CSS` (styling system with project-defined tokens via CSS variables)

### Framework

Approved: `React` + `TypeScript`

Why:

- Clear component model for dashboard, challenge views, leaderboard, and admin panel
- Strong ecosystem support for form handling and API-heavy applications
- TypeScript reduces auth and payload-shape errors across user/admin flows

### Styling System

Approved: `Tailwind CSS` + CSS variables for design tokens

Why:

- Fast implementation of admin-heavy interfaces without introducing a UI framework dependency
- Consistent spacing, typography, and state styling with low CSS maintenance overhead
- CSS variables allow a controlled design system without locking into a component library

### State Management

Approved:

- `TanStack Query` for server state
- `Zustand` for small client state (UI preferences, auth session metadata)

Why:

- Separates server data concerns (fetch/cache/invalidation) from local UI state
- Avoids overusing global state tools for API data
- Keeps MVP state model simple and explicit

### Routing

Approved: `React Router`

Why:

- Sufficient for SPA route segmentation (public, authenticated, admin)
- Mature route guards/layout patterns without requiring a full-stack framework

### Form Handling

Approved: `React Hook Form` + `Zod`

Why:

- Efficient form state management for login, registration, challenge submission, and admin challenge creation
- Schema-driven validation reduces inconsistent client-side validation logic

### Authentication Handling

Approved approach:

- Access JWT held in memory (not local storage)
- Refresh JWT in `HttpOnly`, `Secure`, `SameSite=Strict` cookie
- Axios request interceptor for bearer token injection
- Axios response interceptor for controlled token refresh flow
- Route guards based on authenticated state and role claims

Why:

- Avoids storing access tokens in browser storage (reduces XSS impact)
- Preserves usable login persistence with refresh tokens
- Keeps auth handling centralized and testable

## 3. Backend

### Approved Technologies

- `Node.js` (LTS)
- `TypeScript`
- `Fastify` (API framework)
- `@fastify/jwt` (JWT support)
- `@fastify/cookie` (cookie handling)
- `@fastify/csrf-protection` (CSRF protection for cookie-based auth flows)
- `@fastify/rate-limit` (request throttling)
- `@fastify/helmet` (security headers)
- `@fastify/cors` (CORS policy)
- `Zod` (input validation schemas)
- `Prisma` (ORM)
- `argon2` (password hashing)
- `Pino` (structured logging)

### Framework

Approved: `Fastify` + `TypeScript`

Why:

- Good performance and low overhead for API-driven applications
- Clean plugin model for auth, rate limiting, cookies, and security headers
- Native alignment with structured logging (`Pino`)
- Less framework complexity than full enterprise stacks for this MVP scope

### API Style

Approved: `REST` over HTTPS

Why:

- Fits MVP resources and feature set (auth, challenges, submissions, leaderboard, admin CRUD)
- Easy to test, secure, and document
- Clear endpoint boundaries for user vs admin actions

### Authentication

Approved: `JWT` (access + refresh token model)

Implementation model:

- Short-lived access token for API authorization
- Refresh token rotation for session continuity
- Role claims embedded in access token (minimal claim set only)

Why:

- Supports stateless API authorization
- Reduces server-side session complexity
- Works cleanly with SPA frontend and RBAC

### Password Hashing Approach

Approved: `Argon2id` via `argon2`

Why:

- Memory-hard hashing suitable for modern password storage
- Stronger offline attack resistance than legacy fast hashes
- Widely supported in Node.js ecosystems

### Input Validation

Approved: `Zod` schemas enforced at API boundaries

Why:

- Explicit runtime validation for request bodies, params, and query strings
- Shared validation definitions can be aligned with frontend forms
- Reduces malformed input and authorization bypass bugs caused by implicit coercion

### Rate Limiting

Approved:

- `@fastify/rate-limit` for IP-based endpoint throttling
- Additional application-level submission throttling per user/challenge in database logic

Why:

- IP throttling handles generic abuse quickly
- Per-user/per-challenge throttling directly protects flag submission endpoints
- Avoids introducing Redis for MVP single-instance deployment

### Logging Strategy

Approved: `Pino` structured JSON logging

Requirements:

- Log request/response metadata (without sensitive payloads)
- Redact secrets, tokens, password fields, and flag submissions
- Include request IDs for traceability
- Separate application logs from audit logs (audit logs persisted in database)

Why:

- Structured logs are easier to filter, alert on, and review during incidents
- Redaction is mandatory in a platform handling credentials and flags

## 4. Database

### Approved Technologies

- `PostgreSQL` (primary database engine)
- `Prisma` (ORM and migrations)

### Database Engine

Approved: `PostgreSQL`

Why:

- Strong relational modeling for users, roles, challenges, solves, XP, and audit records
- Reliable transactional behavior for scoring/progression updates
- Mature indexing and constraint support for leaderboard and solve integrity

### ORM

Approved: `Prisma`

Why:

- Strong TypeScript integration for API development
- Clear schema definition and generated client reduce query-shape mistakes
- Supports MVP velocity without sacrificing schema discipline

### Migration Strategy

Approved approach:

- Versioned migrations committed to the repository
- `Prisma Migrate` for schema evolution
- No auto-schema sync in production
- Migrations run as an explicit deployment step

Why:

- Prevents schema drift across environments
- Supports rollback planning and change review
- Keeps database changes auditable

### Indexing Approach

Approved baseline indexing strategy:

- Primary keys on all core tables
- Unique indexes on `users.email` and `users.username`
- Unique constraint on user-challenge solve records (prevents duplicate solve credit)
- Indexes on challenge track + difficulty for listing/filtering
- Indexes on solve timestamps for audit/review
- Indexes on leaderboard-relevant fields (total XP, updated timestamp)
- Indexes on audit log event type + timestamp

Why:

- Supports common MVP read patterns (dashboard, challenge lists, leaderboard, admin review)
- Preserves solve integrity and reduces accidental duplicate scoring

## 5. Security Architecture

### Password Storage Model

Approved model:

- Store only `Argon2id` password hashes (never plaintext)
- Per-password salt handled by the hashing library
- Optional application-level pepper stored in environment variables (not database)

Why:

- Limits impact of database compromise
- Keeps password verification cost tunable as hardware changes

### Role-Based Access Control

Approved model:

- Backend-enforced RBAC on every protected route
- Default deny for admin endpoints
- Role checks based on validated JWT claims plus server-side authorization middleware
- Frontend route guards are UX only, not security controls

Why:

- Prevents privilege escalation through direct API calls
- Keeps enforcement centralized and auditable

### Challenge Flag Storage Strategy

Approved model:

- Do not store plaintext flags in the database
- Store normalized flag digests using `HMAC-SHA-256` (Node.js `crypto`) with a server-held secret key
- Compare submitted flag digests using constant-time comparison

Why:

- Protects flags if the database is exposed
- Fast verification without using expensive password hashing on every submission
- Prevents accidental flag exposure in admin exports or logs

### Preventing Flag Enumeration

Approved controls:

- Challenge flags include unpredictable tokens (see `PROJECT_OVERVIEW.md` flag format)
- Exact-match validation only (no partial match feedback)
- Uniform error responses for invalid submissions
- No flag hints in API responses or logs
- Redaction of submitted flags in application logs

Why:

- Reduces signal available to attackers attempting automated guessing
- Prevents operational leaks through logging or verbose errors

### Protecting Against Brute Force Submissions

Approved controls:

- Endpoint rate limiting (IP-based)
- Per-user and per-challenge submission throttling
- Temporary cooldown after repeated failed submissions
- Audit logging for repeated submission failures
- Optional admin review threshold for suspicious accounts (manual action, MVP)

Why:

- Flag submission endpoint is the highest-probability abuse target in MVP
- Layered throttling is required even for a single-instance deployment

### CSRF / XSS Considerations

Approved protections:

- Access token kept in memory (not local storage)
- Refresh token in `HttpOnly`, `Secure`, `SameSite=Strict` cookie
- `@fastify/csrf-protection` for CSRF token validation on refresh/logout endpoints
- `@fastify/helmet` for baseline browser security headers
- Strict output encoding in frontend rendering (React defaults retained; no dangerous HTML rendering in MVP)
- Input validation on both client and server

Why:

- Balances SPA usability with reduced token exposure
- Addresses the primary web risks relevant to auth and admin functionality in MVP

## 6. Deployment Strategy (MVP)

### Development Environment

Approved local development baseline:

- `Node.js` (LTS)
- `pnpm` (package manager/workspace management)
- Local `PostgreSQL`
- `.env` files for local non-production configuration

Why:

- Minimal local setup with predictable package resolution
- No container requirement for MVP development

### Production Hosting Model (Simple)

Approved MVP production model:

- Single Linux VM/VPS
- `Nginx` as reverse proxy and static file server for frontend build output
- Backend API as a `systemd`-managed Node.js service
- `PostgreSQL` database (same host for MVP simplicity)

Why:

- Lowest operational complexity for initial release
- Clear process supervision and restart behavior
- No orchestration platform required

Not approved in MVP:

- Kubernetes
- Multi-service orchestration
- Containerized lab infrastructure
- Auto-scaling deployment patterns

### CI/CD Overview

Approved tooling:

- `GitHub` (source control)
- `GitHub Actions` (CI/CD pipelines)

Approved pipeline stages:

- Lint
- Type check
- Unit tests
- Integration/API tests
- Build frontend and backend
- Migration deployment step (explicit)
- Deployment to VPS via SSH (manual approval gate recommended)

Why:

- Sufficient automation for MVP quality control without complex deployment tooling
- Supports controlled database migrations and release traceability

### Environment Variable Management

Approved approach:

- Backend secrets stored as OS/service environment variables on the VPS (`systemd` environment file or equivalent)
- Frontend uses build-time environment variables with `VITE_` prefix only for non-secret configuration
- No secrets committed to the repository
- Separate values per environment (dev/test/prod)

Why:

- Prevents secret leakage into client bundles or source control
- Keeps secret management simple and auditable for MVP

## 7. Testing Strategy

### Approved Technologies

- `Vitest` (unit testing)
- `React Testing Library` (frontend component/interaction tests)
- `Supertest` (backend API/integration tests)
- `Playwright` (basic end-to-end smoke tests for critical flows)
- `Semgrep` (basic SAST checks)

### Unit Testing

Approved scope:

- Frontend utility logic and form validation behavior
- Backend domain logic (XP calculations, progression rules, flag verification normalization)
- RBAC helper logic and permission guards

Why:

- MVP correctness depends on scoring, auth, and permission logic more than UI complexity

### Integration Testing

Approved scope:

- Backend service + database integration for auth, challenge solves, XP updates, and leaderboard calculations
- Admin challenge creation flow validation at API level

Why:

- Most MVP risk sits in multi-step state changes across API and database layers

### API Testing

Approved scope:

- Authentication endpoints
- Challenge list/detail endpoints
- Flag submission endpoint
- Leaderboard endpoint
- Admin challenge management endpoints

Requirements:

- Positive and negative cases
- RBAC enforcement checks
- Rate-limit behavior checks on submission endpoint

Why:

- API is the security boundary and product core for this MVP

### Basic Security Testing

Approved scope and tools:

- `Semgrep` rules for common web/API security issues
- Dependency vulnerability scanning using `pnpm audit`
- Manual abuse-case tests for auth and flag submission flows

Why:

- Catches common implementation regressions early without introducing a full AppSec toolchain in MVP

## 8. Monitoring & Logging

### Error Logging

Approved approach:

- Backend application errors logged in structured JSON via `Pino`
- Process/service logs captured by `systemd`/`journald`
- Frontend runtime errors handled minimally in UI and surfaced through backend/API diagnostics when applicable

Why:

- MVP requires reliable server-side observability before adding external monitoring platforms

### Basic Audit Logging

Approved events (database-backed audit log):

- User registration and login attempts (success/failure)
- Password changes/resets (if implemented in MVP)
- Challenge solve events (success only; failed attempts logged as security events, not full payloads)
- XP updates and leaderboard-impacting events

Why:

- Provides traceability for scoring disputes and suspicious activity review

### Admin Activity Logging

Approved events:

- Challenge creation
- Challenge updates
- Challenge publish/unpublish
- Challenge XP/difficulty changes
- Admin-authenticated actions affecting user-visible content

Requirements:

- Include actor ID, action type, target entity ID, timestamp
- Do not log plaintext flags or secrets

Why:

- Admin panel is a high-risk surface for accidental or malicious platform impact

## 9. Folder Structure Overview

### Frontend Structure

Approved structure (conceptual):

- `frontend/src/app/` - app bootstrap, providers, routing setup
- `frontend/src/features/auth/` - login/register/session handling UI and hooks
- `frontend/src/features/challenges/` - challenge listing, detail, flag submission
- `frontend/src/features/dashboard/` - user progress and overview
- `frontend/src/features/leaderboard/` - leaderboard views
- `frontend/src/features/admin/` - admin challenge management UI
- `frontend/src/components/` - shared UI components
- `frontend/src/lib/` - API client, query client, utilities
- `frontend/src/schemas/` - Zod schemas (frontend-facing)
- `frontend/src/styles/` - global styles and token definitions

Why:

- Feature-first grouping reduces coupling and keeps user/admin logic separated

### Backend Structure

Approved structure (conceptual):

- `backend/src/app/` - server bootstrap and plugin registration
- `backend/src/config/` - environment parsing and config validation
- `backend/src/modules/auth/` - auth routes, services, token handling
- `backend/src/modules/users/` - user profile and role-related logic
- `backend/src/modules/challenges/` - challenge retrieval and admin challenge management
- `backend/src/modules/submissions/` - flag submission validation and throttling logic
- `backend/src/modules/xp/` - XP calculation and progression logic
- `backend/src/modules/leaderboard/` - leaderboard queries and ranking logic
- `backend/src/modules/audit/` - audit/security event logging
- `backend/src/common/` - shared middleware, guards, errors, helpers
- `backend/prisma/` - Prisma schema and migrations

Why:

- Module boundaries align with core MVP features and security controls
- Keeps admin behavior inside domain modules rather than separate insecure shortcuts

### Docs Structure

Approved structure (conceptual):

- `docs/architecture/` - architecture decisions and diagrams
- `docs/security/` - security decisions, threat notes, operational procedures
- `docs/api/` - API contracts and endpoint behavior
- `docs/product/` - scope documents and functional specs

Required MVP documents:

- `PROJECT_OVERVIEW.md`
- `TECH_STACK.md`

Why:

- Keeps architecture, security, and product decisions separated and reviewable

### Clear Separation of Concerns

Required boundaries:

- Frontend does not implement security enforcement; backend does
- Backend business logic is separated from database access concerns
- Database constraints enforce integrity in addition to application checks
- Documentation is versioned with the codebase and treated as part of the system design

## MVP Stack Summary (Approved)

Frontend:

- React (TypeScript)
- Vite
- React Router
- TanStack Query
- Zustand
- React Hook Form
- Zod
- Axios
- Tailwind CSS

Backend:

- Node.js (LTS)
- TypeScript
- Fastify
- `@fastify/jwt`
- `@fastify/cookie`
- `@fastify/csrf-protection`
- `@fastify/rate-limit`
- `@fastify/helmet`
- `@fastify/cors`
- Zod
- Prisma
- argon2
- Pino

Database:

- PostgreSQL

Ops / Delivery:

- Nginx
- systemd
- GitHub
- GitHub Actions
- pnpm

Testing / Security:

- Vitest
- React Testing Library
- Supertest
- Playwright
- Semgrep
- `pnpm audit`
