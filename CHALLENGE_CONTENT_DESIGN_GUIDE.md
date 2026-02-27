# ZeroTrace CTF - CHALLENGE_CONTENT_DESIGN_GUIDE

## Scope

This document defines the internal doctrine for creating ZeroTrace CTF challenges.

It covers:

- Challenge design standards
- Difficulty rules
- Educational design rules
- Validation requirements before publishing
- XP assignment guidance
- Quality control criteria

Primary MVP tracks:

- Linux
- Networking
- Cryptography

Future track notes are included for expansion planning only.

## Critical Rules (Non-Negotiable)

- Flags must never be embedded visibly in frontend code.
- All challenge assets must be reviewed for unintended leaks.
- Challenge content must align with platform philosophy.
- No challenge should rely purely on luck.
- Difficulty must be honest.

## 1. Challenge Design Philosophy

### Real-World Simulation

- Challenges must model realistic security tasks, mistakes, artifacts, or attack paths.
- Use evidence, logs, files, traffic, configs, and outputs that resemble real environments.
- Prefer realistic misconfigurations and implementation mistakes over artificial puzzle tricks.

### Progressive Difficulty

- Challenges must support progression from fundamentals to layered reasoning.
- Early challenges teach core concepts with limited noise.
- Later challenges increase ambiguity, chaining, and interpretation burden.

### Concept Isolation

- Each challenge must have a primary learning target.
- Secondary complexity is allowed only if it supports the primary objective.
- Avoid mixing multiple unrelated concepts in a way that obscures what the challenge is teaching.

### Skill Stacking

- Tracks should build reusable skills over time.
- A later challenge may assume skills proven in earlier challenges.
- Difficulty increases should come from combination and context, not arbitrary obscurity.

### Attack + Defense Awareness

- Every challenge must teach both:
  - how the issue is exploited or identified (red-team thinking)
  - how it could be detected, prevented, or mitigated (blue-team thinking)
- Even purely offensive tasks must include a defensive takeaway in the internal write-up.

## 2. Flag Format Standard

### Global Format (Canonical)

All challenge flags must use the canonical platform format:

`ZTCTF{<challenge_slug>_<unique_token>}`

Example (illustrative only):

`ZTCTF{linux_file_perms_a94f2c}`

### Case Sensitivity Rules

- Flag comparison is exact and case-sensitive.
- Authors must not design challenges where case ambiguity is likely unless case sensitivity is part of the intended learning objective.
- If case sensitivity is intentionally part of the challenge, the output path must remain deterministic.

### Whitespace Handling

- Canonical stored flag has no leading or trailing whitespace.
- Challenge outputs that include trailing newlines or copied terminal formatting must still lead to a deterministic canonical flag after platform normalization policy.
- Authors must test copy-paste behavior from expected evidence sources (logs, decoded output, terminal output, PCAP reconstruction).

### No Ambiguous Flags

- Do not create flags that can be interpreted in multiple valid forms.
- Do not rely on visually ambiguous characters when avoidable (for example, `O` vs `0`, `l` vs `1`) unless necessary and clearly derivable.
- If multiple output variants are realistically possible, define multiple valid flags internally (hashed) rather than forcing guesswork.

### Validation Expectations

- Flags must be deterministic and reproducible from the intended solve path.
- Flags must be testable through the platform submission flow before publish.
- Plaintext flags must never appear in player-facing assets, frontend code, or published metadata.

## 3. Challenge Structure Template

Every challenge must include the following fields before it can be reviewed for publication.

### Required Challenge Metadata (Player-Facing)

- `Title`
- `Category` (track)
- `Difficulty` (`Easy` / `Medium` / `Hard`)
- `XP Value`
- `Short Description` (minimal, non-spoiler)
- `Attachment(s)` if applicable

### Required Internal Authoring Content (Not Visible to User)

- `Internal Solution Write-up` (mandatory)
- `Learning Objective`
- `Exploit Path Explanation`
- `Mitigation Explanation`

### Challenge Template (Canonical Authoring Structure)

#### 1. Title

- Short, descriptive, non-spoiler.
- Avoid joke titles that hide the actual theme entirely.

#### 2. Category

- One primary category only for MVP:
  - Linux
  - Networking
  - Cryptography

#### 3. Difficulty

- Must match the Difficulty Definition Matrix in this document.

#### 4. XP Value

- Must align with the XP Assignment Guidelines in this document.

#### 5. Short Description (Minimal)

- Minimal context only.
- Must set investigative direction without naming tools or exact steps.
- Must not contain direct hints disguised as flavor text.

#### 6. Attachments (If Applicable)

- Use realistic filenames and formats.
- Include only files necessary for the intended solve path.
- Remove hidden metadata or artifacts that unintentionally reveal the answer.

#### 7. Internal Solution Write-up (Mandatory)

Must include:

- Intended solve path
- Alternate valid solve paths (if any)
- Expected evidence/artifacts
- Validation of final flag derivation
- Failure points likely to confuse solvers

#### 8. Learning Objective

- State the primary skill being taught.
- State at least one secondary skill or mindset lesson (if applicable).

#### 9. Exploit Path Explanation

- Explain the root flaw, misconfiguration, or weakness.
- Explain why the attack/analysis works.
- Identify what evidence indicates the correct path.

#### 10. Mitigation Explanation

- Explain what would prevent the issue in a real environment.
- Include defensive detection, hardening, or operational safeguards where relevant.

## 4. Difficulty Definition Matrix

Difficulty is defined by cognitive effort and reasoning complexity, not by obscurity.

| Difficulty | Core Characteristics | Expected Solve Time (Target) | Typical Design Pattern | Disallowed Inflation |
|---|---|---|---|---|
| Easy | Single concept, tool-based or straightforward analysis, basic reasoning | < 30 minutes | One clear signal, limited noise, direct artifact interpretation | Hidden trick dependency, misleading wording, brute-force requirement |
| Medium | Multi-step reasoning, partial obfuscation, tool + logic combination | 30–90 minutes | Two or more linked clues, interpretation step, validation step | Random guess checkpoints, excessive noise, undocumented edge constraints |
| Hard | Multi-domain reasoning or deep single-domain analysis, obfuscation layers, reverse engineering/complex reconstruction | > 90 minutes | Layered evidence, indirect clues, anti-shortcut design, careful validation | Artificial complexity without learning value, impossible search space |

### Difficulty Classification Rules

- Difficulty must be based on the intended path, not accidental solver confusion.
- If most testers fail due to unclear wording, the challenge is poorly designed, not "Hard."
- If a challenge is easy conceptually but time-consuming due to repetitive work, redesign it.
- Difficulty rating must be reviewed by at least one reviewer other than the author before publish.

## 5. Track-Specific Guidelines

## A. Linux

### Design Principles

- Focus on realistic Linux artifacts and operational contexts.
- Use file system structure, permissions, configs, logs, cron jobs, services, shell history, and user context realistically.
- Prefer misconfiguration and evidence-based investigation over gimmick shell tricks.

### Recommended Challenge Themes

- File system analysis
- Permission abuse / over-privileged files
- SUID/SGID misuse (static analysis style in MVP assets)
- Log inspection for credential/token/command traces
- Misconfiguration exploitation (configs, service definitions, scheduled tasks)

### Linux Authoring Rules

- Use realistic filesystem paths and file names.
- Use realistic permission modes and ownership patterns.
- Ensure artifacts support a clear intended reasoning path.
- Avoid fake "Hollywood Linux" outputs that do not resemble real commands/logs.

### Blue + Red Team Angle

- Red: identify exploit/misconfiguration path.
- Blue: identify hardening change, permissions correction, audit logging, least-privilege improvements.

## B. Networking

### Design Principles

- Focus on protocol understanding, traffic reconstruction, and anomaly recognition.
- Challenges should reward reading traffic behavior, not random packet-clicking.
- Embed meaningful signals in realistic network captures or traffic logs.

### Recommended Challenge Themes

- PCAP analysis
- Protocol understanding and misuse
- Packet reconstruction / stream reassembly
- Traffic anomaly detection
- Credential leakage in transit

### Networking Authoring Rules

- Use realistic protocol traffic and timestamps.
- Ensure packet captures are not corrupted or incomplete unless intentionally part of the challenge.
- Avoid excessive noise that adds no educational value.
- If traffic is obfuscated, the deobfuscation logic must be inferable from evidence.

### Blue + Red Team Angle

- Red: reconstruct secret, exploit insecure transport, identify protocol misuse.
- Blue: recommend secure transport, protocol hardening, network monitoring signatures, anomaly detection improvements.

## C. Cryptography

### Design Principles

- Focus on cryptographic misuse and weak implementations, not impossible pure math challenges.
- Teach why systems fail when crypto is misapplied.
- Prioritize analysis and reasoning over raw computation burden.

### Recommended Challenge Themes

- Broken implementations
- Misuse of encryption primitives
- Encoding confusion vs encryption confusion
- Weak randomness / predictable key material
- Insecure key reuse or nonce reuse

### Cryptography Authoring Rules

- Make the weakness intentional and analyzable.
- Avoid requiring unrealistic compute resources.
- Distinguish encoding, hashing, and encryption clearly in the internal write-up.
- Ensure challenge wording does not incorrectly teach crypto terminology.

### Blue + Red Team Angle

- Red: exploit predictable/misused crypto behavior.
- Blue: prescribe correct primitive usage, key management, randomness requirements, and implementation safeguards.

## 6. Realism Rules

- Avoid fictional nonsense vulnerabilities.
- Use realistic file names.
- Use realistic log formats.
- Avoid toy examples unless the educational objective explicitly requires a simplified artifact.
- Align challenge narratives and artifacts with real-world attack or investigation scenarios.
- Use realistic timestamps, usernames, hostnames, and service names where context matters.
- Avoid impossible operational behaviors that break immersion for experienced users.

### Realism vs Clarity Rule

- Realism must not make the challenge unreadable.
- Keep realism high, but preserve a clear intended path and deterministic outcome.

## 7. Minimal Instruction Rule

### Core Rule

- Do not instruct the user which tool to use.
- Do not describe the exact next step.
- Do not convert the challenge prompt into a tutorial.

### Example (Required Style Direction)

- Avoid: `Use Wireshark to inspect the PCAP and follow the TCP stream.`
- Prefer: `The traffic never lies.`

### Instruction Design Standards

- Challenge descriptions should create direction, not procedure.
- Language should suggest context, evidence, or suspicion.
- Avoid explicit hinting that collapses the investigative process.
- Avoid unnecessary narrative padding that hides key facts.

### Acceptable Prompt Characteristics

- Minimal
- Directional
- Thematically aligned
- Non-spoiler
- Investigative

## 8. Anti-Frustration Safeguards

### Required Safeguards

- No unsolvable challenge.
- No guessing-based flags.
- No ambiguous output.
- No multiple hidden traps unless intentionally designed and documented.
- All flags must be deterministic.

### Authoring Safeguard Rules

- The intended solve path must be internally verified end-to-end.
- Alternate valid solve paths must not bypass the learning objective in a way that trivializes the challenge.
- If a challenge contains decoys, they must be purposeful and limited.
- Do not punish correct reasoning with arbitrary formatting traps.

### Frustration vs Difficulty Rule

- Difficulty is acceptable.
- Confusion caused by poor design is not.

## 9. Validation Checklist Before Publishing

Every challenge must pass all checks before publication.

### Required Validation Checks

- Flag validation test
- Difficulty review
- Internal solve verification
- XP alignment review
- Security review (no accidental leaks)
- Duplicate XP prevention validation

### Detailed Pre-Publish Checklist

#### Flag Validation Test

- Confirm final flag matches canonical format.
- Confirm accepted flag is deterministic and exact.
- Confirm no unintended alternate flags are accepted (unless intentionally configured).

#### Difficulty Review

- Reviewer confirms difficulty rating matches matrix.
- Reviewer confirms challenge complexity is intentional, not accidental.
- Reviewer confirms expected solve time is realistic.

#### Internal Solve Verification

- A reviewer other than the author solves or validates the intended path.
- Internal write-up is complete and accurate.
- Final flag derivation is reproducible from provided assets only.

#### XP Alignment Review

- XP value falls within the allowed range for the selected difficulty.
- XP matches cognitive effort, not file size, artifact count, or author effort.

#### Security Review (No Accidental Leaks)

- No flag in visible frontend content, challenge description, filenames, metadata, or comments.
- No accidental leakage in attachment metadata, hidden text layers, thumbnails, archive comments, or logs.
- No embedded author notes in artifacts.

#### Duplicate XP Prevention Validation

- Challenge is tested through normal solve flow:
  - first correct submission awards XP
  - second correct submission returns no additional XP
- Concurrent submission behavior is validated (at least once in staging/review environment)

## 10. Write-up Policy

### Internal Solution Documentation (Mandatory)

- Every challenge must have an internal solution write-up before publish.
- No challenge may be published without a reviewer-readable solution path.
- Internal write-up quality is part of challenge approval.

### Public Solution Release Policy

- Public write-ups are not released during the active season/event window.
- Public release is allowed only after the defined season or competition period ends.
- Public release timing must follow platform policy and competition fairness requirements.

### Required Write-up Content

Every internal (and later public) write-up must clearly explain:

- Exploit or analysis path
- Root cause / weakness
- Defense mechanism / mitigation

### Write-up Quality Standards

- Explain why the intended path works.
- Distinguish signal from noise in the artifacts.
- Avoid hand-waving or "just know this" explanations.
- Document known alternate solve paths if they exist.

## 11. XP Assignment Guidelines

### XP Ranges by Difficulty

- Easy: `50-100 XP`
- Medium: `100-250 XP`
- Hard: `250-500 XP`

### XP Assignment Rules

- XP must align with cognitive effort and reasoning depth.
- XP must not be inflated for trivial tasks.
- XP must reflect the intended path, not author difficulty or asset size.
- Within a difficulty band, assign higher XP only when complexity, ambiguity handling, and verification effort are materially higher.

### XP Review Heuristics

- Easy at upper band (`~100 XP`) requires strong beginner learning value or mild multi-step reasoning.
- Medium at upper band (`~250 XP`) requires clear multi-step reasoning and meaningful interpretation.
- Hard at lower band (`~250-300 XP`) should still exceed Medium in complexity and solve effort.

### XP Consistency Rule

- Similar effort challenges across tracks should receive comparable XP.
- Track label alone must not inflate XP.

## 12. Educational Integrity

### Minimum Educational Value Requirement

Every challenge must teach at least one of the following:

- Technical skill
- Analytical skill
- Security mindset principle
- Defensive awareness

### Educational Integrity Standards

- The learning objective must be explicit in the internal documentation.
- The challenge must reward correct reasoning, not memorized trivia alone.
- The challenge must not teach insecure or incorrect concepts without clarifying why they are wrong.
- The mitigation explanation must be technically valid and relevant.

### Security Mindset Requirement

- Each challenge should reinforce at least one security thinking habit:
  - verify assumptions
  - inspect evidence
  - distinguish signal from noise
  - validate output before concluding
  - think about detection/prevention, not just exploitation

## 13. Future Expansion Tracks (Design Notes)

These notes guide future content doctrine and are not MVP track requirements.

### Cloud Security

- Focus on identity, permissions, storage exposure, logging gaps, and configuration drift.
- Prefer realistic misconfigurations over vendor trivia.
- Include both exploitation and remediation posture.

### IoT Security

- Focus on firmware artifacts, exposed services, insecure defaults, and weak update/security controls.
- Keep hardware assumptions explicit when using simulated artifacts.

### OT / ICS Security

- Prioritize protocol understanding, safety implications, segmentation, and monitoring.
- Avoid unrealistic "instant shutdown" narratives without operational context.
- Emphasize defensive impact and safety-aware handling.

### Blockchain Security

- Focus on implementation flaws, key management, transaction logic, and smart contract misuse.
- Avoid hype-driven challenge framing.
- Make exploitability and impact technically grounded.

### GenAI Security

- Focus on prompt injection, insecure tool invocation chains, data leakage, and model integration weaknesses.
- Prefer system-level security failures over novelty prompt puzzles.
- Include defensive controls and monitoring guidance.

## 14. Quality Control Principles

### Core Quality Rules

- No recycled internet CTF challenges.
- No plagiarism.
- No trivial copy-paste problems.
- No impossible brute-force challenges.
- Every challenge must have learning value.

### Additional Quality Controls

- Challenge authorship provenance must be known internally.
- External inspiration must be transformed into original content and documented internally.
- Reviewers must reject challenges that depend on:
  - luck
  - hidden guesswork
  - accidental parser behavior
  - undocumented assumptions

### Quality Gate Decision Rule

Reject or return for revision if any of the following are true:

- Difficulty rating is dishonest
- Learning objective is unclear
- Internal write-up is incomplete
- Flag is ambiguous or leak-prone
- Realism is poor without pedagogical justification
- Security review finds unintended flag exposure

## Challenge Review Workflow (Recommended Internal Process)

### Stage 1: Author Draft

- Author completes full challenge template.
- Author performs self-solve and flag validation.

### Stage 2: Peer Review

- Reviewer validates difficulty, realism, and learning objective.
- Reviewer checks for leaks and ambiguity.

### Stage 3: Independent Solve Verification

- Reviewer (or designated tester) solves from assets and prompt only.
- Expected time and difficulty rating are confirmed or adjusted.

### Stage 4: Publish Readiness Approval

- XP assignment confirmed
- Write-up complete
- Security review complete
- Pre-publish checklist complete

## Governance Rule

- Any change to challenge standards, difficulty definitions, flag format rules, or review requirements must update this document before the change is adopted.
