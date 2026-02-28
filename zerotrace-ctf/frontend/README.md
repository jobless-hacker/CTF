# ZeroTrace Frontend

Frontend for ZeroTrace CTF, built with React + TypeScript + Vite.

## Run
```bash
npm install
npm run dev
```

Default local URL:
- `http://127.0.0.1:5000`

## Environment Variables
- Development fallback API URL is `http://localhost:8000`.
- Production should set `VITE_API_BASE_URL` (for GitHub Pages builds, set repository variable `VITE_API_BASE_URL`).
- If production `VITE_API_BASE_URL` is not set, API requests use same-origin paths (for example `/auth/login`).

## Build and Lint
```bash
npm run lint
npm run build
```

## Architecture
- Routing: `src/app/router/routes.tsx`
- Layout shells: `src/layouts/`
- Feature modules: `src/features/`
- Route pages: `src/pages/`
- Shared API client: `src/services/api/client.ts`

## UI System
The cyber/hacker visual system is documented in:
- `CTF_HACKER_UI_GUIDE.md`

Primary style entry:
- `src/index.css`

Use shared `zt-*` classes and theme tokens instead of ad hoc inline style combinations.
