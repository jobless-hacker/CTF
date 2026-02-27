# ZeroTrace CTF - Cybersecurity Curriculum Master Plan

## 1. Scope

This document defines a complete training curriculum for ZeroTrace CTF content planning.

Topics covered:

- Intro to Cybersecurity
- Linux / Kali Linux
- Networking
- Cryptography
- GenAI Security
- Ethical Hacking
- VAPT (Web, Mobile, API, Network)
- SOC (L1, L2, L3)
- GRC
- Cloud Security
- IoT Security
- OT Security
- ICS Security
- Blockchain Security

Use this as the source of truth for future content design, challenge generation, and platform expansion.

## 2. Program Structure

Training is split into four phases:

1. Foundation
2. Offensive Security
3. Defensive and Governance
4. Specialized Domains and Emerging Risks

Each module includes:

- Theory outcomes
- Practical tooling
- Lab tasks
- CTF challenge seeds
- Assessment criteria

## 3. Module Roadmap (Recommended Order)

| # | Module | Level Focus | Duration |
|---|---|---|---|
| 1 | Intro to Cybersecurity | Beginner | 1 week |
| 2 | Linux and Kali Linux | Beginner | 2 weeks |
| 3 | Networking Fundamentals | Beginner | 2 weeks |
| 4 | Cryptography Fundamentals | Beginner | 2 weeks |
| 5 | Ethical Hacking Methodology | Beginner-Intermediate | 2 weeks |
| 6 | VAPT - Web | Intermediate | 2 weeks |
| 7 | VAPT - API | Intermediate | 1 week |
| 8 | VAPT - Mobile | Intermediate | 2 weeks |
| 9 | VAPT - Network | Intermediate | 1 week |
| 10 | SOC L1 Operations | Beginner-Intermediate | 1 week |
| 11 | SOC L2 Investigation | Intermediate | 1 week |
| 12 | SOC L3 and Threat Hunting | Advanced | 1 week |
| 13 | GRC Fundamentals | Intermediate | 1 week |
| 14 | Cloud Security | Intermediate | 2 weeks |
| 15 | IoT Security | Intermediate | 1 week |
| 16 | OT Security | Intermediate-Advanced | 1 week |
| 17 | ICS Security | Advanced | 1 week |
| 18 | Blockchain Security | Intermediate-Advanced | 1 week |
| 19 | GenAI Security | Intermediate-Advanced | 1 week |

Total recommended timeline: 25 weeks.

## 4. Detailed Module Design

## 4.1 Intro to Cybersecurity

### Outcomes

- Explain CIA triad and security principles.
- Understand threat actors and common attack lifecycle.
- Describe legal/ethical boundaries.

### Labs

- Classify incidents by confidentiality, integrity, availability impact.
- Map a sample incident to ATT&CK tactics.

### CTF Seeds

- Easy: Identify attack stage from provided logs.
- Easy: Determine which control failed in a breach scenario.

## 4.2 Linux and Kali Linux

### Outcomes

- Operate Linux CLI confidently.
- Use permissions, processes, networking commands.
- Use Kali tools safely in controlled environments.

### Labs

- File permissions and SUID misconfiguration analysis.
- Process/service inspection and suspicious binary discovery.

### CTF Seeds

- Easy: Hidden flag through Linux file traversal.
- Medium: Privilege escalation via weak sudoers or SUID.
- Medium: Service enumeration and local exploitation path.

## 4.3 Networking Fundamentals

### Outcomes

- Understand TCP/IP and OSI mappings.
- Analyze packets and protocol behavior.
- Diagnose DNS, routing, and HTTP/TLS issues.

### Labs

- Packet capture analysis with Wireshark/tcpdump.
- Reconstruct basic attack sequence from PCAP.

### CTF Seeds

- Easy: Extract credential artifact from packet stream.
- Medium: Identify lateral movement from netflow and logs.

## 4.4 Cryptography Fundamentals

### Outcomes

- Explain symmetric/asymmetric encryption, hashing, signatures.
- Distinguish secure vs insecure crypto usage.
- Understand PKI and TLS trust model.

### Labs

- Validate signatures and certificates.
- Detect weak hash/salt misuse.

### CTF Seeds

- Easy: Decode/transform encoded data correctly.
- Medium: Break weak implementation (bad IV, ECB, weak key handling).
- Hard: Multi-step cryptographic misuse chain.

## 4.5 Ethical Hacking Methodology

### Outcomes

- Execute recon, enumeration, exploitation, reporting workflow.
- Build evidence-driven findings with reproducible steps.
- Distinguish authorized testing from abuse.

### Labs

- Simulated scope review and rules-of-engagement setup.
- Full mini pentest report with impact and remediation.

### CTF Seeds

- Medium: Multi-stage target compromise with proper evidence.
- Medium: Report-writing challenge with severity scoring.

## 4.6 VAPT - Web Security

### Outcomes

- Test for OWASP Top 10 classes.
- Validate auth/session controls.
- Reproduce and document exploit chains.

### Labs

- XSS, SQLi, SSRF, CSRF labs in isolated apps.
- Session fixation and broken access control scenarios.

### CTF Seeds

- Easy: Reflected XSS discovery.
- Medium: Broken access control with privilege bypass.
- Hard: Chained vulnerabilities for admin takeover.

## 4.7 VAPT - API Security

### Outcomes

- Test REST/GraphQL APIs for authz/authn weaknesses.
- Validate token handling and rate limiting.
- Detect BOLA, BFLA, mass assignment, injection.

### Labs

- JWT abuse and claim tampering checks.
- API fuzzing with schema inconsistencies.

### CTF Seeds

- Medium: BOLA data exfiltration.
- Hard: Auth bypass + business logic abuse chain.

## 4.8 VAPT - Mobile Security

### Outcomes

- Perform static and dynamic mobile testing.
- Analyze insecure storage and transport weaknesses.
- Understand reverse engineering workflow.

### Labs

- APK/IPA static checks.
- Runtime traffic interception and pinning bypass scenario.

### CTF Seeds

- Medium: Hardcoded secret extraction from APK.
- Hard: Runtime bypass challenge with instrumentation.

## 4.9 VAPT - Network Security

### Outcomes

- Conduct network posture assessments.
- Validate segmentation, exposed services, misconfigurations.
- Produce prioritized remediation actions.

### Labs

- Internal network scan and service fingerprinting.
- Misconfigured protocol exploitation in lab VLAN.

### CTF Seeds

- Easy: Misconfigured service discovery.
- Medium: Pivot path identification across segmented hosts.

## 4.10 SOC L1

### Outcomes

- Triage alerts and classify severity.
- Execute initial containment and escalation playbooks.
- Maintain clean timeline documentation.

### Labs

- SIEM alert triage queue simulation.
- Phishing and brute-force investigation basics.

### CTF Seeds

- Easy: Determine true/false positive from event set.
- Medium: Build incident timeline from mixed telemetry.

## 4.11 SOC L2

### Outcomes

- Perform deep incident investigation and scope determination.
- Correlate endpoint, network, and identity telemetry.
- Draft incident response decisions.

### Labs

- Malware execution path investigation.
- Privilege abuse and persistence detection scenario.

### CTF Seeds

- Medium: Root cause analysis challenge.
- Hard: Multi-host compromise chain reconstruction.

## 4.12 SOC L3

### Outcomes

- Design detections and hunt hypotheses.
- Improve SOC coverage and tuning.
- Lead major incident technical response.

### Labs

- Sigma/KQL detection engineering.
- Threat hunting sprint with ATT&CK mapping.

### CTF Seeds

- Hard: Write detection logic for stealthy attack traces.
- Hard: Hunt and prove compromise with minimal indicators.

## 4.13 GRC

### Outcomes

- Build risk register and control mapping.
- Understand ISO 27001, NIST CSF, SOC 2 control intent.
- Translate technical findings into governance actions.

### Labs

- Risk assessment workshop.
- Control gap analysis against sample environment.

### CTF Seeds

- Medium: Map incident findings to missing controls.
- Medium: Prioritize remediations by risk impact.

## 4.14 Cloud Security

### Outcomes

- Secure IAM, network boundaries, and cloud workloads.
- Detect misconfigurations and credential abuse.
- Apply logging and posture management controls.

### Labs

- IAM policy abuse simulation.
- Cloud storage exposure and remediation exercise.

### CTF Seeds

- Medium: Public bucket data leak scenario.
- Hard: Privilege escalation through over-permissive IAM chain.

## 4.15 IoT Security

### Outcomes

- Assess IoT attack surface and firmware security.
- Evaluate communication protocol security.
- Recommend lifecycle hardening controls.

### Labs

- Firmware extraction and analysis workflow.
- Default credential and insecure API testing.

### CTF Seeds

- Medium: Extract secret from firmware artifact.
- Hard: Exploit insecure update mechanism.

## 4.16 OT Security

### Outcomes

- Understand IT/OT differences and safety constraints.
- Evaluate segmentation and remote access controls.
- Support OT-safe incident response planning.

### Labs

- Purdue-model architecture mapping.
- OT remote access hardening scenario.

### CTF Seeds

- Medium: Find risky trust boundary in OT architecture.
- Hard: Simulate containment decision under safety constraints.

## 4.17 ICS Security

### Outcomes

- Understand PLC/SCADA threat models.
- Analyze insecure ICS protocol interactions.
- Design monitoring and response approach for ICS events.

### Labs

- Modbus/DNP3 traffic interpretation.
- SCADA event anomaly investigation.

### CTF Seeds

- Hard: Detect manipulated command sequence in ICS traffic.
- Hard: Identify process-impacting attack path.

## 4.18 Blockchain Security

### Outcomes

- Understand wallet/key risk and smart contract attack classes.
- Analyze common contract vulnerabilities.
- Assess operational controls for Web3 environments.

### Labs

- Smart contract static analysis.
- Transaction trace review for exploit behavior.

### CTF Seeds

- Medium: Access-control flaw in smart contract logic.
- Hard: Reentrancy or arithmetic exploit challenge.

## 4.19 GenAI Security

### Outcomes

- Identify prompt injection and data leakage risks.
- Implement LLM guardrails and abuse controls.
- Establish governance for AI-assisted systems.

### Labs

- Red-team prompt testing against protected workflows.
- Data exfiltration prevention checks in AI pipelines.

### CTF Seeds

- Medium: Prompt injection to bypass tool policy.
- Hard: Multi-step model abuse and detection challenge.

## 5. Difficulty and Progression Matrix

| Level | Expectations | Typical Challenge Type |
|---|---|---|
| Beginner | Tool familiarity, basic triage, single-step logic | Guided challenge with clear signal |
| Intermediate | Multi-step reasoning, control validation, root-cause analysis | Linked clues with moderate noise |
| Advanced | Chained attacks/defense, cross-domain decisions, detection writing | Ambiguous scenarios and realistic telemetry |

Rule: No module should jump directly from Beginner to Advanced challenges without at least one Intermediate bridge challenge.

## 6. Assessment Framework

Each module should have:

1. Knowledge check (short quiz)
2. Practical lab completion
3. CTF challenge(s)
4. Debrief with attack and defense takeaways

Suggested weighting:

- Theory: 20%
- Labs: 40%
- CTF performance: 30%
- Documentation/report quality: 10%

## 7. Content Production Checklist

Before publishing any module:

1. Objectives mapped to specific outcomes.
2. Lab environment reproducible.
3. CTF challenges validated end-to-end.
4. Difficulty verified by at least one reviewer.
5. Defensive takeaways included in write-up.
6. Required docs updated:
   - `CHALLENGE_CONTENT_DESIGN_GUIDE.md`
   - `FRONTEND_IMPLEMENTATION_STATUS.md` (if UI/content features change)

## 8. Expansion Notes

After this baseline:

1. Add role-specific tracks (Red Team, Blue Team, GRC Analyst, Cloud Security Engineer).
2. Add capstone scenarios combining Web/API/Cloud/SOC.
3. Add certification mapping (Security+, CEH, PNPT, OSCP-aligned skills).
4. Add adaptive challenge difficulty based on solver telemetry.

