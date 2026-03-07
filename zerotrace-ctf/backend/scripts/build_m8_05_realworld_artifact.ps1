param()

$ErrorActionPreference = "Stop"

$bundleName = "m8-05-exposed-api-key"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m8_05_realworld_build"
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

function New-AppConfigHistory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("checkout-api","orders-api","billing-gateway","subscription-worker","receipt-service")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $svc = $services[$i % $services.Count]
        $rev = "cfg-" + ("{0:D8}" -f (88100000 + $i))
        $lines.Add("$ts app-config service=$svc env=prod revision=$rev key=PAYMENT_API_KEY value=vault://payment/key source=secret-manager status=ok")
    }

    $lines.Add("2026-03-08T18:01:21Z app-config service=billing-gateway env=prod revision=cfg-88189999 key=PAYMENT_API_KEY value=pk_live_9a82d2 source=local-env-file status=violation note=plaintext_key_detected")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RepoScanLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $authors = @("anil","karthik","meena","sowmya","ravi")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $hash = ("{0:x8}" -f (177000000 + $i))
        $author = $authors[$i % $authors.Count]
        $lines.Add("$ts repo-scan commit=$hash author=$author file=.env.production result=clean detected_key=none")
    }

    $lines.Add("2026-03-08T18:01:22Z repo-scan commit=0ab9c7d1 author=anil file=.env.production result=failed detected_key_name=PAYMENT_API_KEY detected_key_value=pk_live_9a82d2")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CiPipelineAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $pipelines = @("build-checkout","deploy-orders","deploy-billing","deploy-receipts")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $run = "run-" + ("{0:D8}" -f (77100000 + $i))
        $pipe = $pipelines[$i % $pipelines.Count]
        $lines.Add("$ts ci-audit pipeline=$pipe run_id=$run secret_source=vault policy=pass")
    }

    $lines.Add("2026-03-08T18:01:23Z ci-audit pipeline=deploy-billing run_id=run-77177777 secret_source=dotenv policy=violation leaked_api_key=pk_live_9a82d2")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PaymentApiUsageLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.58.21.15","49.205.72.34","125.16.22.90","110.227.81.44")

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $req = "pay-" + ("{0:D8}" -f (66400000 + $i))
        $lines.Add("$ts payment-api request_id=$req src_ip=$ip endpoint=/v1/charges api_key_ref=vault-managed status=200")
    }

    $lines.Add("2026-03-08T18:01:24Z payment-api request_id=pay-66459999 src_ip=185.248.64.31 endpoint=/v1/charges api_key=pk_live_9a82d2 status=401 note=suspected_exposed_key_use")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("api-key-watch","secret-entropy-watch","dotenv-leak-watch","payment-credential-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "api-" + ("{0:D8}" -f (91500000 + $i))
            severity = if (($i % 193) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine api key hygiene monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T18:01:25Z"
        alert_id = "api-91559999"
        severity = "critical"
        type = "production_api_key_exposed"
        status = "open"
        key_name = "PAYMENT_API_KEY"
        leaked_api_key = "pk_live_9a82d2"
        detail = "live payment key exposed in plaintext configuration"
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
        $evt = if (($i % 257) -eq 0) { "api-key-hygiene-review" } else { "normal-cloud-monitoring" }
        $sev = if ($evt -eq "api-key-hygiene-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cloud-05,$sev,api key exposure baseline telemetry")
    }

    $lines.Add("2026-03-08T18:01:26Z,api_key_leak_confirmed,siem-cloud-05,high,correlated config/repo/ci/api logs confirm exposed payment api key")
    $lines.Add("2026-03-08T18:01:29Z,leaked_api_key_identified,siem-cloud-05,critical,leaked api key identified as pk_live_9a82d2")
    $lines.Add("2026-03-08T18:01:35Z,incident_opened,siem-cloud-05,high,INC-2026-5805 exposed api key investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ApiConfigTxt {
    param([string]$OutputPath)

    $content = @'
APP_ENV=production
PAYMENT_PROVIDER=PayFlow
PAYMENT_API_KEY=pk_live_9a82d2
PAYMENT_API_TIMEOUT_MS=8000
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
API Credential Management Policy (Excerpt)

1) Production API keys must never be committed or stored in plaintext files.
2) Runtime secret injection must use managed secret stores.
3) SOC/CloudSec must identify and report leaked API key values for immediate rotation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Exposed API Key Triage Runbook (Excerpt)

1) Pivot leaked key indicators across config history and repository scans.
2) Validate propagation through CI pipeline and downstream API usage logs.
3) Confirm normalized key value in security alerts and SIEM timeline.
4) Submit leaked key value and trigger emergency key rotation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed payment abuse pattern: plaintext live API keys leaked in deployment env files.
Common leaked key prefix in campaign: pk_live_
Current incident normalized leaked key: pk_live_9a82d2
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M8-05 Exposed API Key (Real-World Investigation Pack)

Scenario:
Cloud and AppSec telemetry indicates a live payment API key may be exposed in plaintext config.

Task:
Analyze the investigation pack and identify the leaked API key.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5805
Severity: High
Queue: SOC + CloudSec

Summary:
Potential production payment API key exposure in deployment workflow.

Scope:
- Service: billing-gateway
- Objective: identify leaked API key value
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate app config history, repository scan logs, CI pipeline audits, payment API usage logs, security alerts, SIEM timeline, and policy/runbook context.
- Determine the leaked API key value.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-AppConfigHistory -OutputPath (Join-Path $bundleRoot "evidence\cloud\app_config_history.log")
New-RepoScanLog -OutputPath (Join-Path $bundleRoot "evidence\dev\repo_scan.log")
New-CiPipelineAudit -OutputPath (Join-Path $bundleRoot "evidence\ci\pipeline_audit.log")
New-PaymentApiUsageLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\payment_api_usage.log")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\api_key_exposure_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-ApiConfigTxt -OutputPath (Join-Path $bundleRoot "evidence\cloud\api_config.txt")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\api_credential_management_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\exposed_api_key_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
