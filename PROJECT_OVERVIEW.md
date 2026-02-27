# ZeroTrace CTF (Working Title)

## 1. What Is This Platform?

ZeroTrace CTF is a structured cybersecurity training platform built around challenge-first learning.

It is not a tutorial platform. It is a controlled environment where users learn by solving realistic security problems with minimal guidance.

The platform is designed to support both offensive and defensive learning tracks over time, with a strong emphasis on practical skill validation through flags and progression.

## 2. Who Is It For?

Primary audiences:

- Cybersecurity students
- CTF players
- SOC analysts (L1-L3)
- VAPT professionals
- Ethical hackers
- Cloud security engineers
- Blockchain security learners

This platform is for users who want hands-on practice, not lecture-heavy content.

## 3. What Problem Does It Solve?

Most training platforms fail in one of two ways:

- Too much theory, not enough practice
- CTFs that reward guessing tricks instead of transferable skills

ZeroTrace CTF addresses this by providing:

- Structured progression across domains
- Realistic challenge design with minimal hand-holding
- A single platform for red-team and blue-team skill development
- Clear difficulty and XP systems without diluting technical rigor

## 4. Core Value Proposition

ZeroTrace CTF provides a disciplined, multi-domain cybersecurity training path where users prove competency by solving realistic challenges, not by consuming content.

Key value:

- Challenge-first learning
- Minimal instructions, maximum signal
- Progressive skill building across domains
- Measurable progression through XP and leaderboards
- Admin-controlled challenge publishing for consistent quality

## 5. What Makes It Different From Traditional CTFs?

Traditional CTFs are often event-based, puzzle-heavy, and inconsistent in learning value.

ZeroTrace CTF is different by design:

- Structured tracks instead of random challenge collections
- Progression gating to enforce skill sequencing
- Blue-team and red-team integration in the long-term roadmap
- Real-world simulation mindset over puzzle gimmicks
- Minimal hints by default to promote investigation discipline

This is a training platform with CTF mechanics, not a one-time CTF event portal.

## 6. Learning Philosophy

### Core Principles

- Minimal instructions
- Maximum real-world simulation
- Challenge-first learning
- Blue + Red team integration
- No spoon-feeding

### Practical Interpretation

- Users should spend time investigating, testing, and validating assumptions.
- Challenges should teach through failure and iteration.
- Hints, if introduced later, should be controlled and costly (XP or progression impact), not default.
- Success should reflect repeatable security skills, not obscure trivia.

## 7. MVP Scope (Strictly Defined)

### MVP Goal

Validate the core training loop:

`sign in -> choose track -> solve challenge -> submit flag -> earn XP -> unlock progression -> compare on leaderboard`

### In Scope (MVP Only)

- Authentication
- User dashboard
- Static challenge engine
- XP system
- Leaderboard
- Admin panel for challenge creation
- Three core tracks only:
  - Linux
  - Networking
  - Cryptography

### MVP Challenge Model

- Static challenges only
- Single flag submission per challenge
- Challenge metadata managed by admins (title, description, track, difficulty, XP, flag)
- Progress tracked per user

### MVP Progression Model

- XP awarded on successful solve
- Track visibility and unlock rules can be simple but must be deterministic
- Leaderboard ranking based on total XP (with clear tie-break rules)

### MVP Success Criteria

- A user can register/login, access the dashboard, solve challenges in the three tracks, submit valid flags, earn XP, and appear on the leaderboard.
- An admin can create and publish challenges without developer intervention.

## 8. Out of Scope (MVP)

The following are explicitly excluded from MVP:

- Docker-based labs
- Dynamic or ephemeral labs
- Cloud/IoT/OT/ICS lab environments
- Advanced virtualization or sandbox orchestration
- Team-based play (squads/clans)
- Real-time attack/defense simulations
- Blue-team telemetry pipelines or SIEM simulations
- Hint marketplaces, tokens, or in-app economy systems
- Certificates, badges, or resume exports
- Multi-tenant enterprise features
- API integrations with external learning platforms
- Mobile applications

Domain exclusions for MVP:

- GenAI Security
- Ethical Hacking (beyond overlap with core tracks)
- VAPT (Web/Mobile/API/Network as dedicated tracks)
- SOC L1/L2/L3
- GRC
- Cloud Security
- IoT Security
- OT Security
- ICS Security
- Blockchain Security

## 9. Flag Format Definition

### Canonical Format

All flags must use the format:

`ZTCTF{<challenge_slug>_<unique_token>}`

Example format (illustrative only):

`ZTCTF{linux_file_perms_a94f2c}`

### Rules

- Prefix is fixed: `ZTCTF`
- Curly braces are required
- Flag matching is exact and case-sensitive
- No leading/trailing whitespace
- One canonical flag per challenge in MVP
- `<challenge_slug>` should identify the challenge context
- `<unique_token>` ensures uniqueness and prevents easy guessing

### Purpose of This Format

- Consistent validation
- Easier challenge administration
- Clear separation between challenge identity and secret value

## 10. Gamification Philosophy (XP, Unlocks, Progression)

Gamification exists to support learning discipline, not entertainment loops.

### XP

- XP reflects challenge difficulty and effort.
- XP rewards verified solves only.
- XP values must be predictable and consistent across tracks.

### Unlocks

- Unlocks enforce progression order where needed.
- Early challenges establish fundamentals before harder content becomes available.
- Unlocks should reduce random skipping, not block legitimate exploration unnecessarily.

### Progression

- Progression should communicate competence growth, not just activity volume.
- Track progress must be visible at a glance (completed, available, locked).
- Leaderboard ranking should reinforce performance without distorting learning goals.

### Leaderboard Philosophy

- Leaderboards motivate pace and consistency.
- They should not become the primary product experience.
- The platform should reward depth of solving, not brute-force participation.

## 11. Lab Architecture Vision (High-Level Only)

### MVP Reality

MVP does not include live labs. The platform delivers static challenges and validates flag submissions.

### Future Architecture Direction

The platform should evolve toward a layered training system with clear separation between:

- Content management (challenge definitions, metadata, difficulty, track placement)
- Challenge delivery (user-facing challenge experience)
- Validation and scoring (flag verification, XP, progression, leaderboard)
- Administration and governance (authoring, publishing, review, auditing)
- Execution environments (introduced in later phases for dynamic labs)

### Design Intent

- Preserve challenge portability across static and future live-lab formats
- Keep scoring and progression independent from execution environment type
- Support both offensive and defensive scenarios without redesigning the core platform model

## 12. Long-Term Vision (Phase 2+ Expansion)

### Phase 2: Platform Depth

- Add dynamic lab support (ephemeral challenge environments)
- Expand challenge engine beyond static flags where appropriate
- Introduce guided-but-minimal hints with controlled use
- Add team mode for collaborative solving

### Phase 3: Domain Expansion

Add structured tracks for:

- Intro to Cyber Security
- Linux / Kali Linux (expanded)
- Networking (expanded)
- Cryptography (expanded)
- GenAI Security
- Ethical Hacking
- VAPT (Web, Mobile, API, Network)
- SOC L1/L2/L3
- GRC
- Cloud Security
- IoT Security
- OT Security
- ICS Security
- Blockchain Security

### Phase 4: Blue + Red Team Integration

- Cross-track scenarios that require both attack and defense reasoning
- Detection, response, and remediation challenges tied to exploitation paths
- Scenario chains with evidence collection and reporting outcomes

### Phase 5: Advanced Simulation and Assessment

- Role-based learning paths (SOC analyst, pentester, cloud security engineer, etc.)
- Enterprise-style challenge packs and assessment modes
- Performance analytics for skill-gap identification

## Scope Discipline Statement

ZeroTrace CTF succeeds only if scope is enforced.

The MVP is a static challenge platform with progression and administration for three tracks: Linux, Networking, and Cryptography.

Anything beyond that is a later phase.
