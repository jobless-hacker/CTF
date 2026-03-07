# M7-05 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Exposure of sensitive administrative web directory.
- Task target: identify exposed sensitive directory name.

### Learning Outcome
- Analyze web surface artifacts to detect exposed management paths.
- Correlate listing, scan, route, and detection pipelines.
- Extract sensitive directory indicator for remediation.

### Previous Artifact Weaknesses
- Single directory listing made answer trivial.
- No realistic multi-source AppSec/SOC investigation flow.
- Missing route, monitoring, and process context.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Directory listing output exposing privileged paths.
2. Discovery scan inventories confirming path accessibility.
3. Route manifest/access telemetry showing exposed management endpoint.
4. Alert/SIEM classification pipeline for sensitive directory identification.

### Key Signals Adopted
- Exposed path `/admin/` appears across listing, scan, and access logs.
- Route manifest marks `/admin/` as public/weakly protected.
- Alerts/SIEM normalize sensitive directory as `admin`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `directory_listing.txt` classic listing output with sensitive path present.
- `discovery_scan.csv` (**6,701 lines**) noisy route-discovery telemetry.
- `access.log` (**6,201 lines**) web access baseline plus `/admin/` request.
- `route_manifest.log` (**5,501 lines**) app route visibility inventory.
- `robots_snapshot.txt` crawl policy context.
- `web_exposure_alerts.jsonl` (**4,301 lines**) detection stream with critical exposure event.
- `timeline_events.csv` (**5,004 lines**) SIEM confirmation and incident sequence.
- `admin_surface_protection_policy.txt` and `exposed_admin_panel_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- High-volume baseline data with one actionable exposure signal.
- Multi-artifact correlation required for directory identification.
- SOC/AppSec process context embedded for response readiness.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5705`).
2. Identify sensitive directory path in listing/scan/access artifacts.
3. Confirm exposure state via route manifest and security detections.
4. Validate final directory label from alert/SIEM enrichment.
5. Submit sensitive directory name.

Expected answer:
- `CTF{admin}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m7/m7-05-exposed-admin-panel.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `/admin/`, `sensitive_directory`, `sensitive_directory_identified`.
- Correlate listing + scan + route + alert/SIEM evidence.
- Use normalized label in alerts for final answer confirmation.
