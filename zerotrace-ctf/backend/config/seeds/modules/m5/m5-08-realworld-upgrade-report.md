# M5-08 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Investigation of suspicious external script download activity on Linux hosts.
- Task target: identify malicious domain IOC used in the download flow.

### Learning Outcome
- Correlate host command telemetry with network and file-write evidence.
- Validate domain IOC through DNS, proxy, and security alert perspectives.
- Practice SOC-style reconstruction of download-to-write sequence.

### Previous Artifact Weaknesses
- Single small artifact with near-direct answer visibility.
- No realistic cross-source investigation or incident context.
- Minimal operational noise compared to production SOC datasets.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Linux command telemetry and wget/audit correlation for download incidents.
2. DNS + proxy + endpoint write-chain confirmation used in threat hunting.
3. SIEM timeline escalation from suspicious domain access to incident creation.
4. Download-response runbook practices for IOC extraction and containment.

### Key Signals Adopted
- Suspicious `wget` command referencing untrusted domain.
- Matching wget/proxy request to same malicious URI.
- DNS resolution event for same domain in incident window.
- Security alert and SIEM records explicitly tagging suspicious domain.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `shell_command_telemetry.csv` (**7,802 lines**) host command activity with suspicious download pivot.
- `wget_execution.log` (**6,401 lines**) command-level download telemetry.
- `dns_query.log` (**6,201 lines**) resolver evidence for IOC domain lookup.
- `proxy_egress.log` (**6,101 lines**) outbound request correlation for payload fetch.
- `file_write_audit.log` (**5,301 lines**) endpoint write events confirming payload placement.
- `download_alerts.jsonl` (**4,301 lines**) alert stream with `suspicious_domain` field.
- `timeline_events.csv` (**5,103 lines**) SIEM progression and incident opening.
- `remote_script_download_policy.txt` and `suspicious_download_triage_runbook.txt`.
- Briefing files (`incident_ticket.txt`, `analyst_handoff.txt`).

Realism upgrades:
- Multi-source, high-noise evidence aligned with SOC incident workflows.
- Strong temporal correlation across host/network/security telemetry.
- IOC extraction path is investigative, not single-line trivial.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5508`, node `lin-dl-02`).
2. Identify suspicious domain in shell and wget logs.
3. Correlate same domain in DNS and proxy logs.
4. Confirm related payload write and alert/SIEM attribution.
5. Submit malicious domain IOC.

Expected answer:
- `CTF{bad-domain.ru}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m5/m5-08-suspicious-download.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `bad-domain.ru`, `wget`, `/payload.sh`, `suspicious_domain`.
- CSV/log review for host command and egress telemetry.
- JSONL filter for critical download alert fields.
