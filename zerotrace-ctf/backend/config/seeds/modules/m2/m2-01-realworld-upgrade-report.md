# M2-01 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Off-hours production access triage with source attribution.
- Task target: identify the suspicious external IP.

### Learning Outcome
- Correlate host auth logs with bastion/VPN controls and SOC enrichment.
- Distinguish expected internal maintenance from suspicious external access.
- Practice investigation sequencing used in real SOC triage.

### Previous Artifact Weaknesses
- Single auth file with low realism.
- No policy, enrichment, or control-correlation context.
- Minimal noise and weak investigative depth.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. Linux OpenSSH authentication logging behavior (`sshd`):  
   https://www.openssh.com/manual.html
2. NIST SP 800-61 incident handling workflow for triage and analysis:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. MITRE ATT&CK valid account / remote services investigation context:  
   https://attack.mitre.org/techniques/T1078/  
   https://attack.mitre.org/techniques/T1021/
4. SOC best-practice pattern: multi-source correlation (auth + VPN + SIEM + enrichment).

### Key Signals Adopted
- Successful SSH admin logins during off-hours from unknown external source.
- Bastion sessions show missing MFA for same source.
- VPN denies from same IP before successful SSH path.
- Geo/IP enrichment classifies source as unexpected external infrastructure.
- SIEM high-severity after-hours alert sequence confirms anomaly.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `sshd_auth.log` (**12,404 lines**) high-volume auth evidence.
- `bastion_sessions.csv` (**6,704 lines**) bastion control telemetry.
- `vpn_sessions.csv` (**5,304 lines**) remote-access control evidence.
- `timeline_events.csv` (**4,205 lines**) SIEM normalized alerts and context.
- `geoip_context.csv` (**8 lines**) source enrichment.
- `prod_ssh_access_policy.txt` (**11 lines**) policy baseline.
- Briefing files for analyst workflow.

Realism upgrades:
- Multi-source triage with operational noise and false positives.
- Explicit control mismatch (VPN denied / SSH accepted).
- Policy-aware investigation instead of simple grep-only answering.

## Step 4 - Flag Engineering

Expected investigation path:
1. Start from incident ticket and lock timeframe (`02:10`-`02:20` UTC).
2. Locate successful off-hours SSH logins in `sshd_auth.log`.
3. Pivot same source into bastion and VPN logs.
4. Validate external/unexpected classification via geo context.
5. Confirm SIEM high-severity sequence.
6. Return suspicious IP as flag answer.

Expected answer:
- `CTF{45.83.22.91}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m2/m2-01-after-hours-access.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for IP pivoting across files.
- CSV filtering for timeline and access-control correlation.
- Incident timeline reconstruction from auth -> VPN/bastion -> SIEM.
