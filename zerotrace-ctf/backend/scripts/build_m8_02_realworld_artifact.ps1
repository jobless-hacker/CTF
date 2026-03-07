param()

$ErrorActionPreference = "Stop"

$bundleName = "m8-02-leaked-cloud-credentials"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m8_02_realworld_build"
$bundleRoot = Join-Path $buildRoot $bundleName

function Write-TextFile {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    [System.IO.File]::WriteAllText(
        $Path,
        $Content.Replace("`n", [Environment]::NewLine),
        [System.Text.Encoding]::UTF8
    )
}

function Write-LinesFile {
    param([string]$Path, [System.Collections.Generic.List[string]]$Lines)
    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    [System.IO.File]::WriteAllLines($Path, $Lines, [System.Text.Encoding]::UTF8)
}

function New-ConfigHistoryLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("billing-worker","orders-api","reporting-job","notifier","sync-agent")
    $envs = @("dev","staging","prod")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $svc = $services[$i % $services.Count]
        $env = $envs[$i % $envs.Count]
        $cfg = "cfg-" + ("{0:D8}" -f (77000000 + $i))
        $lines.Add("$ts config-history service=$svc env=$env revision=$cfg key=aws_secret_key value=REDACTED source=secrets-manager")
    }

    $lines.Add("2026-03-08T16:04:21Z config-history service=billing-worker env=prod revision=cfg-77089999 key=aws_secret_key value=SecretKey987 source=local-config-json note=hardcoded_secret_detected")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RepoCommitsLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $authors = @("arun","devi","nisha","vijay","rohit")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $commit = ("{0:x8}" -f (169000000 + $i))
        $author = $authors[$i % $authors.Count]
        $lines.Add("$ts git-commit hash=$commit author=$author file=config/defaults.json summary=`"config cleanup`" secret_scan=clean")
    }

    $lines.Add("2026-03-08T16:04:22Z git-commit hash=0aa7f0c1 author=arun file=deploy/config.json summary=`"temporary credential testing`" secret_scan=failed leaked_key=aws_secret_key leaked_value=SecretKey987")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PipelineAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $pipelines = @("build-api","deploy-billing","deploy-reporting","config-validate")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $pl = $pipelines[$i % $pipelines.Count]
        $runId = "run-" + ("{0:D8}" -f (99000000 + $i))
        $lines.Add("$ts pipeline-audit pipeline=$pl run_id=$runId secret_source=vault status=pass")
    }

    $lines.Add("2026-03-08T16:04:23Z pipeline-audit pipeline=deploy-billing run_id=run-99077777 secret_source=config_file status=violation leaked_secret_key=aws_secret_key leaked_secret_value=SecretKey987")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecretsScanAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("entropy-watch","token-pattern-watch","config-scan-watch","credential-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "cred-" + ("{0:D8}" -f (88400000 + $i))
            severity = if (($i % 187) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine secret scanning telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T16:04:24Z"
        alert_id = "cred-88459999"
        severity = "critical"
        type = "cloud_secret_leak_detected"
        status = "open"
        repository = "billing-service"
        file = "deploy/config.json"
        exposed_key_name = "aws_secret_key"
        exposed_secret = "SecretKey987"
        detail = "hardcoded cloud secret detected in committed config file"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 253) -eq 0) { "secret-hygiene-review" } else { "normal-secrets-monitoring" }
        $sev = if ($evt -eq "secret-hygiene-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cloud-02,$sev,credential hygiene baseline telemetry")
    }

    $lines.Add("2026-03-08T16:04:25Z,cloud_credential_leak_confirmed,siem-cloud-02,high,correlated config/repo/pipeline/alert evidence confirms leaked cloud secret")
    $lines.Add("2026-03-08T16:04:28Z,exposed_secret_identified,siem-cloud-02,critical,exposed cloud secret identified as SecretKey987")
    $lines.Add("2026-03-08T16:04:35Z,incident_opened,siem-cloud-02,high,INC-2026-5802 leaked cloud credentials investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ConfigJson {
    param([string]$OutputPath)

    $content = @'
{
  "service": "billing-worker",
  "environment": "prod",
  "aws_access_key": "AKIA12345",
  "aws_secret_key": "SecretKey987",
  "region": "ap-south-1"
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Cloud Credentials Management Policy (Excerpt)

1) Cloud secrets must never be hardcoded in repository or deployment configs.
2) Secrets must be fetched from managed secret stores at runtime.
3) SOC/CloudSec must identify and report exposed secret values immediately.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Leaked Cloud Credentials Triage Runbook (Excerpt)

1) Pivot candidate leak indicators across config history and commit records.
2) Confirm value propagation in pipeline audits and secret scan alerts.
3) Validate normalized leaked secret in SIEM timeline.
4) Submit exposed secret value and trigger rotation workflow.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed incident pattern: hardcoded cloud credentials in deployment config.
Credential family targeted: aws_secret_key
Current incident normalized exposed secret: SecretKey987
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M8-02 Leaked Cloud Credentials (Real-World Investigation Pack)

Scenario:
Cloud security telemetry indicates a deployment configuration may contain hardcoded cloud credentials.

Task:
Analyze the investigation pack and identify the exposed secret key.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5802
Severity: High
Queue: SOC + CloudSec

Summary:
Potential cloud credential leak found in production deployment flow.

Scope:
- Service: billing-worker
- Repository: billing-service
- Objective: identify exposed cloud secret key value
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate config history, repo commit records, pipeline audit logs, secrets scanner alerts, SIEM timeline, and policy/runbook context.
- Determine the exposed cloud secret key value.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ConfigHistoryLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\config_history.log")
New-RepoCommitsLog -OutputPath (Join-Path $bundleRoot "evidence\dev\repo_commits.log")
New-PipelineAuditLog -OutputPath (Join-Path $bundleRoot "evidence\ci\pipeline_audit.log")
New-SecretsScanAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\secrets_scan_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-ConfigJson -OutputPath (Join-Path $bundleRoot "evidence\cloud\config.json")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\cloud_credentials_management_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\leaked_cloud_credentials_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
