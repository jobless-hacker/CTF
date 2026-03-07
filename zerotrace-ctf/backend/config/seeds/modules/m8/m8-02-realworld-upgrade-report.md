# M8-02 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Cloud credential leakage from hardcoded secret in config/deployment artifacts.
- Task target: identify exposed cloud secret key value.

### Learning Outcome
- Investigate credential leaks across config, source control, CI, and detection pipelines.
- Correlate high-noise operational telemetry with one true exposed secret.
- Extract normalized leaked credential value for rotation workflow.

### Previous Artifact Weaknesses
- Single config file made answer immediate.
- No realistic commit/pipeline/secrets-scanner context.
- Missing SOC/CloudSec process and incident correlation data.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Configuration history traces showing secret source drift.
2. Repository commit logs with failed secret scan findings.
3. CI pipeline audits showing non-vault secret source violations.
4. Secret scanner alerts and SIEM timelines with normalized exposed secret value.

### Key Signals Adopted
- Hardcoded `aws_secret_key` appears in prod config path.
- Commit and pipeline logs flag leaked secret value `SecretKey987`.
- Secret scan and SIEM finalize exposed secret as `SecretKey987`.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `config_history.log` (**7,101 lines**) noisy config revisions with one hardcoded secret event.
- `repo_commits.log` (**5,601 lines**) commit stream and one failed secret scan leak.
- `pipeline_audit.log` (**5,201 lines**) CI audit stream with one credential source violation.
- `secrets_scan_alerts.jsonl` (**4,301 lines**) noisy security scanner alerts and one critical leak alert.
- `timeline_events.csv` (**5,004 lines**) SIEM incident progression and final secret identification.
- `config.json` direct leaked config artifact.
- `cloud_credentials_management_policy.txt` and `leaked_cloud_credentials_triage_runbook.txt`.
- `threat_intel_snapshot.txt` plus briefing files.

Realism upgrades:
- Multi-system credential leak investigation path (Cloud + Dev + CI + SOC).
- High-volume noisy telemetry requiring value-level pivots.
- Includes governance/runbook context for real response operations.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident scope (`INC-2026-5802`) and affected service.
2. Pivot config history for hardcoded secret event.
3. Confirm leak propagation in repo commits and pipeline audit.
4. Validate exposed value from scanner alerts and SIEM normalization.
5. Submit leaked secret value.

Expected answer:
- `CTF{SecretKey987}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m8/m8-02-leaked-cloud-credentials.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `aws_secret_key`, `SecretKey987`, `secret_scan=failed`, `exposed_secret`, `exposed_secret_identified`.
- Correlate config/dev/ci/security evidence before final submission.
