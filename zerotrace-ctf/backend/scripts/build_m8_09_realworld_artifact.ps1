param()

$ErrorActionPreference = "Stop"

$bundleName = "m8-09-compromised-access-token"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m8_09_realworld_build"
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

function New-TokenAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("api-gateway","orders-api","billing-api","profile-api","support-api")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $svc = $services[$i % $services.Count]
        $tok = "tok_" + ("{0:x12}" -f (920000000 + $i))
        $lines.Add("$ts token-audit service=$svc token_ref=$tok scope=customer.read status=valid exposure=no")
    }

    $lines.Add("2026-03-08T20:14:11Z token-audit service=api-gateway token=abc123xyz scope=customer.read status=valid exposure=yes note=plaintext_token_leak")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ApiAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("10.1.10.11","10.1.10.22","10.1.10.33","10.1.10.44")
    $routes = @("/v1/profile","/v1/orders","/v1/history","/v1/support")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $route = $routes[$i % $routes.Count]
        $tok = "tok_" + ("{0:x12}" -f (920000000 + $i))
        $lines.Add("$ts api-access src_ip=$ip route=$route auth_token_ref=$tok status=200")
    }

    $lines.Add("2026-03-08T20:14:12Z api-access src_ip=185.99.42.17 route=/v1/profile auth_token=abc123xyz status=403 note=suspected_compromised_token_use")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TokenIntrospection {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5400; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            token_ref = "tok_" + ("{0:x12}" -f (920000000 + $i))
            active = $true
            scope = "customer.read"
            issuer = "auth-service"
            risk = "low"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T20:14:13Z"
        token = "abc123xyz"
        active = $true
        scope = "customer.read"
        issuer = "auth-service"
        risk = "critical"
        exposure = "public_log"
        exposed_token = "abc123xyz"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SessionActivityCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,user_id,session_id,src_ip,token_ref,action,result,risk")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $uid = "u" + ("{0:D6}" -f (300000 + ($i % 90000)))
        $sid = "sess-" + ("{0:x10}" -f (74000000 + $i))
        $ip = "10.1.20." + (($i % 200) + 10)
        $tok = "tok_" + ("{0:x12}" -f (920000000 + $i))
        $lines.Add("$ts,$uid,$sid,$ip,$tok,api_request,success,low")
    }

    $lines.Add("2026-03-08T20:14:14Z,u918271,sess-deadbeef01,185.99.42.17,abc123xyz,api_request,blocked,critical")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("token-hygiene-watch","credential-leak-watch","session-risk-watch","api-auth-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "tok-" + ("{0:D8}" -f (82400000 + $i))
            severity = if (($i % 189) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine access token posture monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T20:14:15Z"
        alert_id = "tok-82459999"
        severity = "critical"
        type = "access_token_compromise_detected"
        status = "open"
        leaked_token = "abc123xyz"
        source_ip = "185.99.42.17"
        detail = "token observed in plaintext logs and unauthorized request attempts"
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
        $evt = if (($i % 251) -eq 0) { "token-exposure-review" } else { "normal-cloud-monitoring" }
        $sev = if ($evt -eq "token-exposure-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cloud-09,$sev,access token baseline telemetry")
    }

    $lines.Add("2026-03-08T20:14:16Z,compromised_token_confirmed,siem-cloud-09,high,correlated token audit/api/session/alerts confirms compromised token")
    $lines.Add("2026-03-08T20:14:19Z,exposed_token_identified,siem-cloud-09,critical,exposed token identified as abc123xyz")
    $lines.Add("2026-03-08T20:14:25Z,incident_opened,siem-cloud-09,high,INC-2026-5809 compromised access token investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AccessLogTxt {
    param([string]$OutputPath)

    $content = @'
2026-03-08T20:14:12Z token=abc123xyz user=external_client endpoint=/v1/profile
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Access Token Protection Policy (Excerpt)

1) Access tokens must never appear in plaintext logs or config files.
2) Token-bearing requests from unknown sources require immediate containment.
3) SOC/CloudSec must identify and report exposed token values for revocation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Compromised Access Token Triage Runbook (Excerpt)

1) Pivot suspected token across token audit, API access, and introspection artifacts.
2) Validate abuse attempts via session activity and alert stream.
3) Confirm normalized exposed token in SIEM timeline.
4) Submit exposed token value and trigger token revocation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed abuse pattern: leaked access tokens reused from public log artifacts.
Current incident normalized exposed token: abc123xyz
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M8-09 Compromised Access Token (Real-World Investigation Pack)

Scenario:
Cloud API telemetry indicates an access token may have leaked and been reused by unauthorized clients.

Task:
Analyze the investigation pack and identify the exposed token.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5809
Severity: High
Queue: SOC + CloudSec

Summary:
Potential exposed access token observed in production telemetry.

Scope:
- Service: api-gateway
- Objective: identify exposed token value
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate token audit logs, API access logs, token introspection results, session activity, security alerts, SIEM timeline, and policy/runbook context.
- Determine the exposed token value.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-TokenAuditLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\token_audit.log")
New-ApiAccessLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\api_access.log")
New-TokenIntrospection -OutputPath (Join-Path $bundleRoot "evidence\cloud\token_introspection.jsonl")
New-SessionActivityCsv -OutputPath (Join-Path $bundleRoot "evidence\cloud\session_activity.csv")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\token_exposure_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-AccessLogTxt -OutputPath (Join-Path $bundleRoot "evidence\cloud\access_log.txt")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\access_token_protection_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\compromised_access_token_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
