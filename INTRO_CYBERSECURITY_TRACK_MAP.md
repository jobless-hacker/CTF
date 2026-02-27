# ZeroTrace CTF - Track Map: Introduction to Cybersecurity

## Purpose

This document is the visual and structural map for the Foundation track.

Direct-use assets:

- Seed definition: `zerotrace-ctf/backend/config/seeds/intro-cybersecurity-track.seed.json`
- Seeder script: `zerotrace-ctf/backend/scripts/seed_intro_cybersecurity_track.py`

## Visual Tree

```text
Introduction to Cybersecurity (intro-cybersecurity)
|
|-- M1 CIA Triad (100 XP)
|   |-- m1-cia-triad-integrity-breach (50 XP)
|   `-- m1-cia-triad-multi-impact (50 XP)
|
|-- M2 Threat vs Vulnerability vs Risk (150 XP)
|   `-- m2-threat-vulnerability-risk-classifier (150 XP)
|
|-- M3 Attack Surface Mapping (150 XP)
|   `-- m3-attack-surface-map (150 XP)
|
|-- M4 Threat Actor Identification (200 XP)
|   `-- m4-threat-actor-apt-identification (200 XP)
|
|-- M5 Cyber Kill Chain (250 XP)
|   `-- m5-cyber-kill-chain-mapping (250 XP)
|
|-- M6 MITRE ATT&CK Basics (300 XP)
|   `-- m6-mitre-attack-technique-mapping (300 XP)
|
`-- M7 Cyber Law and Compliance (150 XP)
    `-- m7-cyber-law-data-protection (150 XP)
```

Track XP total: `1300`

## Progression Model

```text
Beginner -> Analyst Mindset -> Risk Evaluator -> Threat Mapper
```

Badge progression:

1. Cyber Awareness
2. Risk Analyst
3. Threat Mapper
4. Attack Strategist

## Module-to-Domain Connections

| Foundation Module | Connects To |
|---|---|
| CIA Triad | GRC, Cloud Security |
| Threat/Vulnerability/Risk | GRC, VAPT |
| Attack Surface | Web, API, Cloud |
| Threat Actors | Red Teaming, SOC |
| Kill Chain | SOC Operations |
| MITRE ATT&CK | Threat Hunting, Detection Engineering |
| Cyber Law and Compliance | GRC, Security Governance |

## Skill Tree UI Shape

```text
           [M6 MITRE]
                |
 [M4 Threat Actors] -- [M5 Kill Chain]
                |
      [M3 Attack Surface]
                |
 [M2 Threat/Vulnerability/Risk]
                |
          [M1 CIA Triad]
                |
      [M7 Compliance Overlay]
```

## Backend Mapping Notes

Current backend model supports:

- `tracks`
- `challenges`

Current backend model does not have a dedicated `modules` table.  
Module grouping is represented by:

1. Seed file hierarchy (`modules[] -> challenges[]`)
2. Challenge slug prefix (`m1-`, `m2-`, ...)
3. Description header (`[Module Mx - Name]`)

This keeps seeding compatible with existing MVP schema without migrations.

## Seed Execution

From `zerotrace-ctf/backend`:

```bash
./venv/bin/python scripts/seed_intro_cybersecurity_track.py --dry-run
./venv/bin/python scripts/seed_intro_cybersecurity_track.py
```

Optional flags:

- `--update-existing`: update existing challenge metadata by slug
- `--no-publish`: create/set flags but skip publish action

## Frontend Integration Guidance

Recommended grouping logic on track detail page:

1. Parse challenge slug prefix (`m1`, `m2`, ...)
2. Group and sort by module order
3. Render module cards with XP subtotal and completion ratio

This gives Track -> Modules -> Challenges UX now, without backend schema changes.
