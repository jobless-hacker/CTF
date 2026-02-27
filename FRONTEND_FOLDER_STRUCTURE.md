# ZeroTrace CTF - FRONTEND_FOLDER_STRUCTURE (MVP)

## Scope

This document defines the frontend folder layout, architectural boundaries, and module responsibilities for the ZeroTrace CTF MVP.

In scope:

- Authentication pages (Register, Login)
- Dashboard
- Track listing
- Challenge listing
- Challenge detail view
- Flag submission form
- XP display
- Leaderboard page
- Admin panel (challenge management)
- Admin logs view

Out of scope for MVP frontend structure:

- Animations and gamification effects
- Mobile app
- Real-time sockets
- Docker lab UI
- SOC analyst interface

## Critical Rules (Non-Negotiable)

- No business logic inside UI components.
- No direct fetch/API calls inside random components or page components.
- All API interaction must go through the service layer.
- Role enforcement must not rely solely on frontend.
- Avoid prop drilling for auth state.
- Avoid circular imports.

## 1. Architectural Overview

### Why Modular Frontend Architecture Matters

- MVP scope is small enough for a single frontend application but large enough to become disorganized quickly.
- Feature boundaries reduce duplication across pages, forms, tables, and role-gated views.
- Clear layers make reviews easier for security-sensitive flows (auth, submission, admin actions).

### Separation Between UI and Data Layer

Frontend responsibilities must be split into:

- `UI composition` (pages, layouts, presentational components)
- `State orchestration` (feature hooks, global auth state)
- `API interaction` (service layer and centralized client)
- `Validation and mapping` (schemas, DTOs, response normalization)

This separation prevents:

- API contracts leaking directly into UI components
- repeated request logic across pages
- inconsistent error handling
- ad-hoc auth/token handling in feature code

### Preventing Frontend Security Assumptions

- Frontend route protection is a UX layer only.
- Backend remains the source of truth for:
  - authentication validity
  - role authorization
  - hidden challenge visibility
  - flag submission eligibility
- Frontend must assume all protected actions can fail due to auth/authorization and handle those failures consistently.

## 2. Root Folder Structure (Tree Format)

Approved MVP frontend structure:

```text
frontend/
│
├── public/
│   ├── static-assets
│   └── attachment-placeholders (optional dev/test only)
│
├── src/
│   │
│   ├── app/
│   │   ├── bootstrap/
│   │   │   ├── app-entry
│   │   │   ├── providers
│   │   │   └── startup-auth-bootstrap
│   │   ├── router/
│   │   │   ├── route-definitions
│   │   │   ├── route-guards/
│   │   │   │   ├── protected-route
│   │   │   │   └── admin-route
│   │   │   └── route-fallbacks
│   │   └── error-handling/
│   │       ├── error-boundaries
│   │       └── page-error-mappers
│   │
│   ├── pages/
│   │   ├── auth/
│   │   │   ├── login-page
│   │   │   └── register-page
│   │   ├── dashboard/
│   │   │   └── dashboard-page
│   │   ├── tracks/
│   │   │   ├── track-list-page
│   │   │   └── track-detail-page
│   │   ├── challenges/
│   │   │   ├── challenge-list-page
│   │   │   └── challenge-detail-page
│   │   ├── leaderboard/
│   │   │   └── leaderboard-page
│   │   ├── admin/
│   │   │   ├── admin-challenges-page
│   │   │   ├── admin-challenge-edit-page
│   │   │   └── admin-logs-page
│   │   └── not-found-page
│   │
│   ├── layouts/
│   │   ├── auth-layout
│   │   ├── main-layout
│   │   ├── admin-layout
│   │   └── layout-shell-components/
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── services/
│   │   │   ├── state/
│   │   │   ├── schemas/
│   │   │   ├── types/
│   │   │   └── mappers/
│   │   │
│   │   ├── dashboard/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── services/
│   │   │   ├── types/
│   │   │   └── mappers/
│   │   │
│   │   ├── tracks/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── services/
│   │   │   ├── schemas/
│   │   │   ├── types/
│   │   │   └── mappers/
│   │   │
│   │   ├── challenges/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── services/
│   │   │   ├── schemas/
│   │   │   ├── types/
│   │   │   ├── mappers/
│   │   │   └── policies/
│   │   │
│   │   ├── xp/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── services/
│   │   │   ├── types/
│   │   │   └── mappers/
│   │   │
│   │   ├── leaderboard/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── services/
│   │   │   ├── schemas/
│   │   │   ├── types/
│   │   │   └── mappers/
│   │   │
│   │   └── admin/
│   │       ├── components/
│   │       ├── hooks/
│   │       ├── services/
│   │       ├── schemas/
│   │       ├── types/
│   │       ├── mappers/
│   │       └── policies/
│   │
│   ├── components/
│   │   ├── common/
│   │   ├── forms/
│   │   ├── tables/
│   │   ├── feedback/
│   │   └── navigation/
│   │
│   ├── hooks/
│   │   ├── ui/
│   │   ├── routing/
│   │   └── accessibility/
│   │
│   ├── services/
│   │   ├── api/
│   │   │   ├── client
│   │   │   ├── interceptors
│   │   │   ├── error-mapper
│   │   │   ├── response-normalizer
│   │   │   └── request-config
│   │   ├── auth-session/
│   │   └── file-download/
│   │
│   ├── context/
│   │   ├── auth-context
│   │   └── app-context (optional, minimal)
│   │
│   ├── state/
│   │   ├── auth/
│   │   ├── ui/
│   │   └── session/
│   │
│   ├── schemas/
│   │   ├── common/
│   │   └── api-envelope/
│   │
│   ├── types/
│   │   ├── api/
│   │   ├── domain/
│   │   ├── auth/
│   │   └── ui/
│   │
│   ├── utils/
│   │   ├── formatting/
│   │   ├── guards/
│   │   ├── pagination/
│   │   └── constants/
│   │
│   ├── assets/
│   │   └── static-ui-assets
│   │
│   └── styles/
│       └── global-style-entry (structure only; no styling policy defined here)
│
├── tests/
│   ├── component/
│   ├── integration/
│   ├── role-rendering/
│   ├── mocks/
│   ├── fixtures/
│   └── helpers/
│
├── scripts/
│   └── test-support (optional)
│
└── README (frontend-specific developer notes)
```

## 3. Layer Responsibilities

This section defines what each folder is for, what belongs there, what does not, and how dependencies must flow.

### 3.1 `src/app/`

#### Purpose

- Application bootstrap
- global providers
- route tree setup
- route guards
- top-level error handling

#### What Belongs There

- App startup orchestration
- provider composition (auth/query/global state providers)
- route registration and navigation fallbacks
- application-level error boundary wrappers

#### What Must NOT Be Placed There

- Feature business logic
- Feature-specific API calls
- Form validation rules for specific pages
- Admin/challenge/XP logic

#### Dependency Direction Rules

- `app` may depend on `layouts`, `pages`, `context`, `state`, `services/api`
- Feature modules must not depend on `app`

### 3.2 `src/pages/`

#### Purpose

- Route-level page composition
- Assembly of layouts + feature components/hooks

#### What Belongs There

- Page container components
- Page-level composition logic
- Route parameter reading and delegation to feature hooks/components
- Page-level empty/error/loading presentation decisions

#### What Must NOT Be Placed There

- Direct API calls
- Domain business logic (XP rules, flag validation logic, role decisions)
- Token handling logic
- Raw request/response transformation

#### Dependency Direction Rules

- `pages` -> `layouts`, `features/*`, shared `components`, shared `hooks`, `types/ui`
- `pages` must not depend on `services/api` directly

### 3.3 `src/layouts/`

#### Purpose

- Reusable page shells for auth, main user flows, and admin flows

#### What Belongs There

- Navigation shell
- header/sidebar/footer structures
- route outlet/container framing
- layout-specific UI wrappers

#### What Must NOT Be Placed There

- Feature business logic
- Feature-specific API requests
- Role authorization logic beyond rendering slots based on already-resolved auth context

#### Dependency Direction Rules

- `layouts` -> shared `components`, `context`/auth selectors, `utils`
- `layouts` must not call feature services directly

### 3.4 `src/features/`

#### Purpose

- Feature-level UI, hooks, service adapters, and feature-specific state/orchestration

#### What Belongs There

- Feature components
- Feature hooks
- Feature service wrappers (calling centralized API client)
- Feature schemas/types/mappers
- Feature-specific display policies (non-authoritative)

#### What Must NOT Be Placed There

- Global app bootstrap code
- Cross-feature shared UI primitives (move to `src/components/` if reused)
- Raw token storage primitives (centralize in auth/session layers)

#### Dependency Direction Rules

- `features/*` -> `services/api`, `services/auth-session`, shared `components`, shared `hooks`, `types`, `utils`, `context` (read-only access via auth hooks/selectors)
- Feature modules must not import page components
- Feature modules should not import other feature internals directly; use public exports or shared service layer abstractions

### 3.5 `src/components/` (Shared UI Components)

#### Purpose

- Reusable presentational or low-complexity shared UI building blocks

#### What Belongs There

- Shared form controls
- tables and list primitives
- feedback components (error banners, empty states)
- navigation components used by multiple features/layouts

#### What Must NOT Be Placed There

- Feature-specific business logic
- API calls
- Feature-specific data orchestration

#### Dependency Direction Rules

- `components` -> `types/ui`, `utils`, shared hooks (UI-only)
- `components` must not depend on feature modules unless explicitly designated feature-composed components (prefer avoid)

### 3.6 `src/hooks/` (Shared Hooks)

#### Purpose

- Reusable UI and app behavior hooks that are not feature-specific

#### What Belongs There

- UI behavior hooks
- routing helper hooks
- accessibility helper hooks

#### What Must NOT Be Placed There

- Feature business workflows
- API endpoint logic for domain features
- Auth token mutation logic outside auth/session boundaries

#### Dependency Direction Rules

- Shared hooks may depend on `utils`, `types`, and safe shared contexts
- Shared hooks must not depend on feature internals

### 3.7 `src/services/` (Service Layer)

#### Purpose

- Centralize API interaction and non-UI service logic

#### What Belongs There

- API client
- request/response normalization
- error mapping
- auth session helper services
- file download helpers for challenge attachments

#### What Must NOT Be Placed There

- JSX/UI rendering logic
- route/page composition
- feature-specific view state

#### Dependency Direction Rules

- `services` -> `types/api`, `schemas`, `utils`
- `services` must not depend on `pages`, `layouts`, or feature UI components

### 3.8 `src/context/`

#### Purpose

- Provide cross-app state access patterns for limited global concerns

#### What Belongs There

- Auth context (current user, auth status, role list, auth actions)
- Minimal app-level context if necessary

#### What Must NOT Be Placed There

- Feature-specific server data caches (keep in feature/query layer)
- Business rules unrelated to cross-cutting state

#### Dependency Direction Rules

- `context` -> `services`, `state`, `types`, `utils`
- Feature modules may consume context through exported hooks/selectors

### 3.9 `src/state/`

#### Purpose

- Global client-side state containers for app-wide non-page-local state

#### What Belongs There

- Auth session state
- Minimal UI state (navigation open/closed, global filters if shared across routes)
- Session lifecycle state (auth refresh status, bootstrap loading)

#### What Must NOT Be Placed There

- Duplicated server resources already handled by feature data hooks
- Full copies of challenge lists, leaderboard, or dashboard responses unless explicitly justified
- Business rule engines

#### Dependency Direction Rules

- `state` -> `types`, `utils`
- `state` should not depend on UI components

### 3.10 `src/schemas/` and `src/features/*/schemas/`

#### Purpose

- Input and response validation schemas for frontend use

#### What Belongs There

- Shared API envelope schema
- Common primitive validation schemas
- Feature form validation schemas
- Feature response shape guards (if used)

#### What Must NOT Be Placed There

- Business logic
- API request execution
- UI rendering concerns

#### Dependency Direction Rules

- Schemas may depend on `types` and `utils`
- Pages/components should consume schemas via hooks/services, not duplicate validation rules

### 3.11 `src/types/`

#### Purpose

- Shared type/interface definitions used across features and services

#### What Belongs There

- API envelope types
- domain-facing frontend types (track, challenge summary, leaderboard row)
- auth/session types
- shared UI prop contracts for reusable components

#### What Must NOT Be Placed There

- Runtime business logic
- API call implementations
- Feature-specific component implementations

#### Dependency Direction Rules

- `types` must remain dependency-light
- All layers may depend on `types`
- `types` must not depend on feature UI code

### 3.12 `src/utils/`

#### Purpose

- Small pure utility functions and constants

#### What Belongs There

- formatting helpers
- pagination helpers
- constant maps
- type guards (non-domain workflow)

#### What Must NOT Be Placed There

- API calls
- auth token handling workflows
- feature business logic disguised as utilities

#### Dependency Direction Rules

- `utils` -> `types` only (preferably)
- No imports from `features`, `pages`, or `services`

### 3.13 `tests/`

#### Purpose

- Frontend test suites organized by scope

#### What Belongs There

- component tests
- integration tests
- role-rendering tests
- mocked API scenarios
- fixtures and test helpers

#### What Must NOT Be Placed There

- production runtime code
- environment secrets

#### Dependency Direction Rules

- `tests` depend on production code
- production code must never depend on `tests`

## 4. Feature-Based Organization

Each feature module owns its UI pieces, hooks, and feature-facing service adapters, while relying on the centralized API client.

## 4.1 `features/auth/`

### Components

- Login form components
- Registration form components
- Auth error/feedback components (feature-specific)

### Hooks

- Login action hook
- Registration action hook
- Logout action hook (if UI-triggered from auth feature)
- Auth status selector hooks (may proxy auth context selectors)

### Service Layer Usage

- Uses centralized auth service wrapper built on top of the API client
- No direct HTTP requests from auth components/pages

### Shared State Usage

- Writes to global auth/session state
- Reads auth status and current user from centralized auth context/state

## 4.2 `features/dashboard/`

### Components

- XP summary panels
- Recent activity panels
- Track summary cards (dashboard-specific composition)

### Hooks

- Dashboard data composition hook (combines auth, tracks, XP summaries)
- Recent activity formatting hook (UI-focused only)

### Service Layer Usage

- Uses feature services that compose calls to:
  - current user endpoint
  - tracks endpoint
  - current user XP endpoint
- Composition happens in hooks/services, not page components

### Shared State Usage

- Reads global auth state
- Avoids duplicating user profile state already held in auth context

## 4.3 `features/tracks/`

### Components

- Track list
- Track card
- Track progress indicators
- Locked/available state indicators

### Hooks

- Track list data hook
- Track detail data hook
- Track access-state display helper hook (UI mapping only)

### Service Layer Usage

- Calls track endpoints through track service wrapper using centralized API client
- Response normalization handled in service/mappers

### Shared State Usage

- Reads auth state for role and session status
- Uses local feature state for filters/sorting UI (if any)

## 4.4 `features/challenges/`

### Components

- Challenge list
- Challenge list rows/cards
- Challenge detail content view
- Attachment list
- Flag submission form
- Submission result feedback panel

### Hooks

- Challenge list data hook
- Challenge detail data hook
- Flag submission action hook
- Submission cooldown/rate-limit UI state hook (presentation only)

### Service Layer Usage

- Uses challenge and submission service wrappers
- Submission hook calls service layer only; no direct HTTP in form component
- Error mapping for `already solved`, `rate limited`, `not found` handled centrally and surfaced to UI-safe states

### Shared State Usage

- Reads auth state
- Can trigger XP/leaderboard cache invalidation via shared data layer hooks/services
- Does not own global XP totals directly

## 4.5 `features/xp/`

### Components

- XP badge/summary display components
- XP history list components (MVP limited recent history)

### Hooks

- Current user XP summary hook
- XP refresh hook used after successful submissions

### Service Layer Usage

- Calls `users/me/xp` through XP service wrapper
- Performs response normalization to domain-safe XP view models

### Shared State Usage

- Read-only integration with global auth state
- Avoids duplicating auth user object

## 4.6 `features/leaderboard/`

### Components

- Leaderboard table
- Pagination controls
- Current-user rank highlighting row logic (UI-only)

### Hooks

- Leaderboard query hook
- Leaderboard pagination state hook (may be local to page if not shared)

### Service Layer Usage

- Leaderboard API calls go through leaderboard service wrapper
- Pagination params and response normalization are centralized

### Shared State Usage

- Reads auth state to mark current user row
- Keeps pagination state local unless shared across views is required

## 4.7 `features/admin/`

### Components

- Challenge management list
- Challenge create/edit forms
- Publish/unpublish action controls
- Admin logs table and filters
- Role change controls (if included in MVP admin UI)

### Hooks

- Admin challenge list/query hooks
- Admin challenge mutation hooks (create/edit/publish)
- Admin log query hook
- Admin role change hook

### Service Layer Usage

- Uses admin service wrappers only
- Admin feature must not call generic API client directly from components
- Error mapping for `forbidden`, `publish precondition failed`, and validation conflicts handled centrally

### Shared State Usage

- Reads global auth state/roles for access rendering
- Must assume backend may still reject stale admin state and handle gracefully

## 5. API Client Layer Design

### Centralized API Service

- A single API client layer is the only place that performs raw HTTP request execution.
- Feature services call the API client, not low-level network APIs directly.
- API client enforces:
  - base URL/config usage
  - auth token injection
  - response envelope handling
  - error mapping

### Token Handling

- Token handling is centralized in auth/session services and API client interceptors/adapters.
- UI components and page components must not manipulate tokens directly.
- Auth headers are attached centrally.
- Session expiration behavior is standardized (clear auth state + redirect flow via auth context/route guards).

### Error Handling Strategy

- API errors are normalized into frontend-safe error objects before reaching UI components.
- Feature hooks map normalized errors to display states/messages.
- Raw backend error payloads must not be parsed ad hoc inside pages/components.
- Security-sensitive responses (`401`, `403`, hidden challenge `404`) must have consistent handling paths.

### Response Normalization

- Services normalize API envelope and resource shapes into feature/domain view models.
- Components consume stable feature-facing data shapes rather than raw API responses.
- This reduces coupling to backend payload evolution and prevents repeated mapping logic.

### Preventing API Leakage Into Components

- Page and component layers must only use feature hooks or feature service abstractions.
- Shared components must receive data via props, not trigger domain API calls.
- Exception policy: none for MVP (no direct fetch in any UI component/page).

## 6. Auth & Route Protection Strategy

### Global Auth Context

- Auth state is globally controlled through a dedicated auth context/store.
- Single source of truth for:
  - auth status (`anonymous`, `authenticated`, `loading`, `expired`)
  - current user
  - roles
  - session refresh/logout actions

### Token Storage Policy

- Access token should be treated as session runtime state, not embedded in arbitrary component state.
- Frontend token handling must minimize exposure and centralize access.
- Session continuation (if used) must be handled via secure backend-aligned mechanisms; UI code should not rely on persistent insecure storage for privileged auth state.

### Protected Route Wrapper

- Protected route wrapper enforces authenticated access for:
  - dashboard
  - tracks/challenges
  - XP/leaderboard
  - admin routes (base auth check before admin role check)
- If auth is missing/expired:
  - redirect to login
  - preserve intended destination where appropriate

### Admin-Only Route Wrapper

- Admin wrapper enforces `admin` role presence in frontend auth state.
- Used only for UI gating and route navigation control.
- Backend remains authoritative; frontend admin wrapper is not a security boundary.

### Handling Expired Tokens

- Central API error handling detects auth expiration.
- Auth context transitions to expired/unauthenticated state.
- Protected routes redirect to login.
- In-progress page components must render safe fallback states and stop assuming prior authorization.

## 7. State Management Strategy

### What Is Global State

Global state should be limited to cross-application concerns:

- auth/session state
- current user identity and roles
- minimal global UI state (for example, navigation shell state)
- app bootstrap status

### What Is Local State

Local or feature-level state should handle:

- form input state
- page filter inputs
- modal/dialog visibility
- pagination state (unless shared across routes)
- temporary UI interaction state (loading indicators, expanded rows)

### Avoid Unnecessary Global State

- Do not store entire challenge lists, leaderboard pages, or dashboard payloads in global state by default.
- Prefer feature data hooks and service-backed caching patterns.
- Promote to global state only when multiple unrelated routes require the exact same client-owned state.

### Prevent Duplication of User Data

- Current user profile/roles should exist in one global auth source.
- Other features should read from auth selectors/context instead of copying user data into feature stores.
- If user data is refreshed, the auth source is updated centrally and consumers re-render from that source.

## 8. Layout Strategy

### Main Layout

Purpose:

- Default shell for authenticated player-facing pages (dashboard, tracks, challenges, leaderboard)

Contains:

- primary navigation
- user context display (non-sensitive)
- route outlet area
- shared page-level error/notification region

Does Not Contain:

- feature-specific API calls
- challenge submission logic
- XP business logic

### Auth Layout

Purpose:

- Minimal shell for login/register pages

Contains:

- simple auth page framing
- route outlet for auth pages

Does Not Contain:

- authenticated navigation
- feature data loading

### Admin Layout

Purpose:

- Shell for admin routes (challenge management and admin logs)

Contains:

- admin navigation and route outlet
- clear separation from player navigation context
- admin page framing and shared admin feedback regions

Does Not Contain:

- admin mutation logic
- audit query logic

### Layout Reuse Rules

- Layouts are shells, not feature containers.
- Shared UI shell components belong in `layouts/layout-shell-components` or shared `components/navigation`.
- If a layout starts owning feature-specific data dependencies, move that logic into a feature hook/component and inject it into the layout.

## 9. Naming Conventions

### Component Naming

- Use `PascalCase` for component names.
- Suffix by responsibility when helpful:
  - `Page`
  - `Layout`
  - `Form`
  - `Table`
  - `Panel`
  - `Card`
- Use descriptive names over generic names.

Examples of naming style (not implementation):

- `LoginPage`
- `ChallengeDetailPage`
- `FlagSubmissionForm`
- `LeaderboardTable`

### Folder Naming

- Use lowercase `kebab-case` for folders.
- Feature folders use domain nouns:
  - `auth`
  - `tracks`
  - `challenges`
  - `xp`
  - `leaderboard`
  - `admin`

### Hook Naming

- Hooks must start with `use`.
- Name hooks by outcome or resource, not UI placement.

Preferred naming style:

- `useCurrentUser`
- `useTrackList`
- `useChallengeDetail`
- `useSubmitFlag`
- `useLeaderboardPage`

Avoid:

- `useData`
- `useCommonHook`
- `useHelper`

### Page Naming

- Route pages end with `Page`.
- Admin pages include `Admin` prefix or live under `admin/` with explicit names.
- Avoid route file names that expose backend terminology unnecessarily.

## 10. Testing Structure (Frontend)

### Component Tests

Location:

- `tests/component/`

Focus:

- Reusable UI components
- Feature components with mocked hooks/services
- Form rendering and validation feedback behavior

Rule:

- Component tests should not depend on real network calls.

### Integration Tests

Location:

- `tests/integration/`

Focus:

- Page + feature + route guard interaction
- Auth flow UI transitions
- Challenge submission UX states (`correct`, `incorrect`, `already solved`, `rate limited`)
- Admin page flows with role-gated navigation

Rule:

- Integration tests should exercise feature hooks and API-service boundaries with controlled mock responses.

### Mock API Testing

Location:

- `tests/mocks/` and `tests/fixtures/`

Focus:

- API envelope success/error variants
- auth expiration responses
- hidden challenge `404` responses
- leaderboard pagination responses
- admin forbidden responses

Rule:

- Mock at the centralized API client or feature service boundary, not inside UI components.

### Role-Based Rendering Tests

Location:

- `tests/role-rendering/`

Focus:

- Player UI should not render admin navigation/actions
- Admin UI should render admin route access
- Expired auth state redirects protected pages
- Admin route wrapper denies non-admin UI access

Rule:

- These tests validate UX gating only.
- Backend authorization remains separately tested in backend/security test suites.

## 11. Future Scalability Notes

### Where Lab UI Would Plug In Later

Future module placement:

- `src/features/labs/`
- `src/pages/labs/`
- `src/layouts/lab-layout` (only if lab UX diverges from main layout)

Rules:

- Lab UI must use the same centralized API client and auth context.
- Lab-specific state must remain isolated from core challenge/XP UI state.
- Lab UI must not embed core XP logic; XP updates still flow through standard XP/leaderboard refresh paths.

### Where SOC Interface Would Plug In Later

Future module placement:

- `src/features/soc/`
- `src/pages/soc/`
- optional `src/layouts/soc-layout`

Rules:

- SOC UI must not reuse challenge/player components unless semantics match.
- Keep SOC-specific schemas/types separate from CTF challenge schemas/types.

### Avoiding Monolithic UI Growth

- Add new capabilities as feature modules, not ad-hoc page folders with embedded data logic.
- Promote shared components only after real reuse (at least two features).
- Keep `common`/`shared` directories strict; do not turn them into a dumping ground.
- Review import graphs periodically to prevent:
  - feature-to-feature internal coupling
  - circular dependencies
  - API client usage outside service layer

### Dependency Direction Rule (Frontend-Wide)

Preferred dependency flow:

`app/router/pages/layouts` -> `features` -> `services/api` -> backend API

Shared dependencies (`components`, `hooks`, `types`, `utils`) may be used by pages/features, but must not depend on feature internals unless explicitly designated as feature-owned components.

## Governance Rule

- Any change to frontend architectural boundaries, route protection ownership, auth state ownership, or API service layer rules must update this document before implementation is considered complete.
