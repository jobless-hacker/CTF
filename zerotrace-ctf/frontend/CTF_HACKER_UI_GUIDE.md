# ZeroTrace Hacker UI Guide

## Purpose
This guide documents the visual system used by the frontend so future contributors can extend the UI without breaking the cyber/CTF look and feel.

Primary style source:
- `src/index.css`

Theme asset files:
- `src/assets/cyber-grid.svg`
- `src/assets/noise-tile.svg`
- `src/assets/panel-frame.svg`
- `src/assets/skull-holo.svg`
- `public/skull.svg`

## Visual Direction
- Theme: tactical cyber operations console
- Tone: high-contrast neon + glass panels on dark gradients
- Typography:
  - Headings: `Orbitron`
  - Body/code feel: `Share Tech Mono`
- Motion:
  - subtle entrance animation (`zt-enter`)
  - reduced-motion support is built in

## Theme Tokens
Core tokens are defined in `:root` in `src/index.css`.

Key tokens:
- `--zt-bg-*`: layered page background
- `--zt-surface`, `--zt-surface-strong`: panel surfaces
- `--zt-border`, `--zt-border-strong`: UI borders
- `--zt-accent`: primary cyan accent
- `--zt-danger`, `--zt-success`, `--zt-warning`: semantic colors
- `--zt-text`, `--zt-muted`: text hierarchy

Do not hardcode random colors in pages. Add/adjust tokens first.

Tailwind token aliases are also available in `tailwind.config.js`:
- `cyber.bg`
- `cyber.panel`
- `cyber.neon`
- `cyber.neonSoft`
- `cyber.border`
- `cyber.textPrimary`
- `cyber.textMuted`

## Texture/Frame Layering
The UI now uses local asset overlays for a stronger cyber-console feel:
- `body` background includes `cyber-grid.svg`
- `body::after` overlays subtle digital noise from `noise-tile.svg`
- `.zt-panel::before` adds frame chrome from `panel-frame.svg`

When replacing these assets, keep:
1. transparent backgrounds
2. low-opacity lines/details
3. dimensions optimized for tiling/scaling

## Reusable UI Classes
Use these classes instead of one-off style combinations:

- Layout:
  - `zt-app-screen`, `zt-app-bg-grid`, `zt-app-glow-top`, `zt-app-glow-right`, `zt-app-glow-left`, `zt-app-content`
  - `zt-shell`
  - `zt-auth-screen`, `zt-auth-shell`, `zt-auth-header`
  - `zt-auth-brand`, `zt-auth-tagline`
  - `zt-auth-frame`, `zt-auth-panel`, `zt-auth-panel-title`, `zt-auth-glyph`
  - `zt-auth-bg-grid`, `zt-auth-content`
  - `zt-auth-glow-top`, `zt-auth-glow-right`, `zt-auth-glow-left`
  - `zt-terminal-frame`, `zt-terminal-corner`, `zt-terminal-corner--tl|tr|bl|br`
  - `zt-auth-skull`, `skull-glow`, `zt-auth-hud-ring`
  - `zt-field-label`, `zt-auth-separator`
  - `zt-topbar`, `zt-topbar-inner`
  - `zt-main`
  - `zt-page`, `zt-page--narrow`
  - `zt-sidebar`, `zt-sidebar-link`, `zt-sidebar-link--active`
- Branding/navigation:
  - `zt-brand`, `zt-brand-mark`
  - `zt-nav-link`, `zt-nav-link--active`
  - `zt-pill`
- Content:
  - `zt-panel`, `zt-panel-title`
  - `zt-kicker`, `zt-heading`, `zt-subheading`
  - `zt-grid-3`
  - `zt-stat-card`, `zt-stat-label`, `zt-stat-value`
  - `zt-card-link`
- Forms:
  - `zt-form`, `zt-form-grid`
  - `zt-input`, `zt-select`, `zt-textarea`
  - `cyber-input`
- Buttons:
  - `zt-button`
  - `zt-button--primary`
  - `zt-button--ghost`
  - `zt-button--success`
  - `zt-button--warn`
  - `zt-button--danger`
  - `cyber-button`
- Feedback:
  - `zt-alert`
- `zt-alert--error`, `zt-alert--success`, `zt-alert--warn`, `zt-alert--info`
- Data tables:
  - `zt-table-wrap`, `zt-table`
  - `zt-row-highlight`
  - `zt-pagination`

## Extension Rules
When adding a new page or component:
1. Start with `zt-page`.
2. Group major sections in `zt-panel`.
3. Use semantic feedback via `zt-alert--*`.
4. Use `zt-table` stack for tabular data.
5. Keep business logic in hooks/services; visual files should stay presentational.

## Accessibility Baseline
- Reduced motion respected globally (`prefers-reduced-motion`).
- Inputs include visible focus ring via shared classes.
- Keep text contrast aligned with existing tokens.
- Keep semantic HTML (`button`, `table`, headings).

## QA Checklist
Before merging UI changes:
1. `npm run lint`
2. `npm run build`
3. Desktop + mobile quick pass
4. Check auth, track, challenge, leaderboard, admin pages
5. Verify no inline hardcoded colors unless introducing a new token
- Background helpers:
  - `cyber-grid`
  - `cyber-pulse`
  - `scan-overlay`
  - `animate-spin-slow`
  - `glitch-text`

Reusable component:
- `src/components/common/cyber-panel.tsx` (`CyberPanel`)

Shared cinematic hooks:
- `src/hooks/ui/useParallax.ts`
- `src/hooks/ui/useTypewriter.ts`
