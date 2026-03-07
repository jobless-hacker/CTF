# M1-04 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Security log tampering / deletion after privileged access.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate auth, audit, syslog, and SIEM evidence.
- Distinguish suspicious admin activity from normal background noise.
- Use forensic metadata (inode + size drop) to prove tampering.

### Previous Artifact Weaknesses
- Small evidence set with minimal background traffic.
- Easy single-hop answer path.
- Limited realism for SOC-style investigation workflow.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK T1070.002 (clear Linux/macOS system logs):  
   https://attack.mitre.org/techniques/T1070/002/
2. rsyslog `imfile` behavior for truncation handling (`reopenOnTruncate` context):  
   https://www.rsyslog.com/doc/tutorials/imfile.html
3. Linux `truncate` command behavior:  
   https://man7.org/linux/man-pages/man1/truncate.1.html
4. Red Hat audit logging guidance and event record interpretation:  
   https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/security_hardening/auditing-the-system_security-hardening
5. auditd utilities (`ausearch` event analysis model):  
   https://man7.org/linux/man-pages/man8/ausearch.8.html

### Key Signals Adopted
- `truncate -s 0 /var/log/auth.log` execution evidence.
- `audit.log` syscall/PATH/PROCTITLE chain proving file mutation.
- rsyslog truncation detection for same file/inode.
- SIEM high-severity log-tampering event amid noisy auth failures.

## Step 3 - Artifact Design Upgrade

Upgraded artifact pack includes:
- `auth.log` (**12,606 lines**) mixed normal activity + suspicious root session.
- `audit.log` (**19,608 lines**) syscall-level events with malicious truncate pivot.
- `rsyslog_messages.log` (**4,202 lines**) operational noise + truncation signal.
- `normalized_security_events.csv` (**5,203 lines**) SIEM feed with false positives.
- shell history, inode/size timeline, incident ticket, analyst handoff.

Realism upgrades:
- High-volume logs with false positives.
- Multiple users/source IPs.
- Cross-source correlation needed to conclude.
- Operational noise that mimics real SOC triage conditions.

## Step 4 - Flag Engineering

Expected path:
1. Identify privileged session around suspicious window.
2. Confirm log file clear command in host/audit telemetry.
3. Validate truncation event from rsyslog and inode-size timeline.
4. Distinguish from benign logrotate-like activity on other files.
5. Classify primary CIA impact.

Expected flag:
- `CTF{integrity}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-04-deleted-logs.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for command and file pivots.
- `ausearch`-style reasoning for audit event chains.
- `jq` not required here but SIEM CSV filtering is useful.
- Timeline correlation by timestamp + inode + user/source.

