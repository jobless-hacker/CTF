# ZeroTrace CTF Frontend Handoff Guide

This guide is for future contributors who need to modify or extend the frontend without breaking architecture boundaries.

## Core Principles

- No direct API calls in page or UI component files.
- All HTTP calls go through feature service files.
- Hooks orchestrate state and side effects.
- Pages compose hooks and UI only.
- Layouts remain presentation-only and route-shell focused.

## Current Route Ownership

- Auth: `src/pages/auth/*`
- Dashboard: `src/pages/dashboard/dashboard-page.tsx`
- Tracks: `src/pages/tracks/*`
- Challenges: `src/pages/challenges/*`
- Leaderboard: `src/pages/leaderboard/*`
- Admin: `src/pages/admin/*`
- Routing entry: `src/app/router/routes.tsx`

## Backend Contract Integration Pattern

When adding a new backend endpoint:

1. Define typed response/request in `src/features/<feature>/types/*`.
2. Add service call in `src/features/<feature>/services/*`.
3. Normalize errors in `src/features/<feature>/services/*errors.ts`.
4. Add hook in `src/features/<feature>/hooks/*`.
5. Consume hook in page/component.
6. Add/adjust query invalidations after mutations.

Do not skip intermediate layers.

## Query Key Conventions

- Auth profile: auth context hydration (service call in provider)
- XP: `["current-user-xp"]`
- Leaderboard: `["leaderboard", scope, limit, offset]`
- Tracks: `["tracks"]`
- Track challenges: `["track", slug, "challenges"]`
- Challenge detail: `["challenge", slug]`
- Admin tracks: `["admin", "tracks"]`
- Admin challenge catalog: `["admin", "challenge-catalog"]`
- Admin logs: `["admin", "logs", limit, offset]`

Keep keys stable and deterministic.

## Adding a New Page (Checklist)

1. Create page file under `src/pages/<domain>/`.
2. Create missing types/services/hooks under `src/features/<domain>/`.
3. Add route in `src/app/router/routes.tsx`.
4. Apply route guards (`ProtectedRoute`, `AdminRoute`) as required.
5. Add loading, error, empty states.
6. Add required cache invalidation on mutations.
7. Run:
   - `npm run lint`
   - `npm run build`

## Admin Surface Notes

- `/admin/challenges` is fully functional for create, set-flag, publish, unpublish.
- Catalog currently aggregates published challenge lists by track.
- For complete unpublished visibility across all challenges, introduce backend `GET /admin/challenges`.
- `/admin/logs` currently backed by challenge-attempt based log events.

## Safe Refactoring Rules

- Keep feature boundaries isolated.
- Avoid importing deep internals across feature modules.
- Move cross-feature primitives to shared `src/services` or `src/types` when reuse emerges.
- Preserve request/response typing and avoid `any`.
- Keep route guard logic centralized in `src/app/router`.

## Suggested Next Improvements

1. Add frontend integration tests for dashboard/admin pages.
2. Add admin challenge list endpoint and UI filtering.
3. Add track selector on global leaderboard page to toggle scope.
4. Add audit filtering and pagination state persistence in admin logs.
