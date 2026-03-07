# M3-10 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Public web exposure of backup artifacts due to web server misconfiguration.
- Task target: identify the full website backup filename.

### Learning Outcome
- Correlate backup exposure evidence across web logs, scanner findings, inventory, and SIEM.
- Identify root-cause config issue and confirm exploitation.
- Extract the exact high-impact backup artifact from noisy listings.

### Previous Artifact Weaknesses
- Minimal listing artifact with immediate answer.
- No realistic web/server/cloud telemetry chain.
- No false positives, timeline correlation, or policy context.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. OWASP Sensitive Data Exposure and logging guidance for web misconfigurations:  
   https://owasp.org/www-project-top-ten/  
   https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
2. NIST SP 800-61 incident correlation approach:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. MITRE ATT&CK exposure/exfiltration context:  
   https://attack.mitre.org/techniques/T1567/
4. Operational pattern: autoindex-enabled backup directory + external retrieval + SIEM escalation.

### Key Signals Adopted
- `autoindex on;` in backup web location.
- Public path reveals `site_backup_full.tar`.
- External IP requests same backup file from edge/web telemetry.
- SIEM opens incident based on critical exposure + external download.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `nginx_access.log` (**9,602 lines**) web access telemetry.
- `backup_object_inventory.csv` (**8,404 lines**) backup object metadata.
- `directory_listing_snapshot.txt` (**6,208 lines**) noisy directory listing evidence.
- `web_exposure_scan.jsonl` (**4,501 lines**) scanner outputs with one critical finding.
- `cdn_edge_requests.csv` (**5,802 lines**) edge request telemetry with external retrieval.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression.
- `webserver_backup_location.conf` (**9 lines**) root-cause web config.
- `web_backup_exposure_policy.txt` (**5 lines**) governance baseline.
- Briefing files.

Realism upgrades:
- Full evidence chain from misconfiguration -> exposure -> external access -> incident.
- Multi-source noisy telemetry requiring pivots.
- Root cause and policy violations included for analyst context.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident brief and exposure window.
2. Validate backup-path misconfiguration in web config.
3. Correlate directory listing and object inventory to identify candidate full backup file.
4. Confirm scanner critical finding and external download telemetry.
5. Validate SIEM timeline and submit exact full backup filename.

Expected answer:
- `CTF{site_backup_full.tar}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m3/m3-10-web-backup-exposure.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `site_backup_full.tar`, `autoindex on`, `public_backup_detected`, `INC-2026-5264`.
- CSV analysis for inventory/CDN/SIEM.
- JSONL filtering for critical scanner findings.
