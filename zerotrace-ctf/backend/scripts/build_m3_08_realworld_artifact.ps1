param()

$ErrorActionPreference = "Stop"

$bundleName = "m3-08-log-file-exposure"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m3_08_realworld_build"
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

function New-AppServerLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $paths = @("/api/v1/catalog","/api/v1/orders","/api/v1/profile","/healthz","/api/v1/cart")
    $users = @("svc-api","rahul","anita","maria","kartik","guest")

    for ($i = 0; $i -lt 9400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $path = $paths[$i % $paths.Count]
        $user = $users[$i % $users.Count]
        $status = if (($i % 67) -eq 0) { 500 } elseif (($i % 13) -eq 0) { 404 } else { 200 }
        $lat = 20 + (($i * 9) % 410)
        $rid = "req-{0:D8}" -f (61000000 + $i)
        $line = "$ts INFO app=checkout-api request_id=$rid user=$user method=GET path=$path status=$status latency_ms=$lat"
        $lines.Add($line)

        if (($i % 211) -eq 0) {
            $dbg = "$ts DEBUG app=checkout-api request_id=$rid debug_context=""cache_key=item_$($i % 80) trace=trc-$('{0:x6}' -f $i)"""
            $lines.Add($dbg)
        }

        if (($i % 997) -eq 0) {
            $noiseToken = "{0:x8}" -f (330000000 + $i)
            $noise = "$ts WARN app=checkout-api request_id=$rid trace=trc-$('{0:x8}' -f (92000000 + $i)) message=""debug payload contains token=$noiseToken (masked downstream)"""
            $lines.Add($noise)
        }
    }

    $lines.Add("2026-03-07T14:22:17.412Z WARN app=checkout-api request_id=req-77889910 logger=raw-request-dump path=/api/v1/orders message=""request headers captured Authorization: Bearer 9f8a7b6c""")
    $lines.Add("2026-03-07T14:22:18.019Z INFO app=checkout-api request_id=req-77889911 mitigation=disable_raw_request_dump status=applied")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GatewayRequests {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,request_id,client_ip,user_agent,route,http_status,response_bytes,auth_token_hint")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $routes = @("/checkout","/catalog","/profile","/cart","/orders")

    for ($i = 0; $i -lt 7800; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $rid = "gw-{0:D8}" -f (51000000 + $i)
        $ip = "10.26.$(40 + ($i % 30)).$((2 + $i) % 240)"
        $ua = if (($i % 3) -eq 0) { "Mozilla/5.0" } elseif (($i % 3) -eq 1) { "okhttp/4.12.0" } else { "curl/8.6.0" }
        $route = $routes[$i % $routes.Count]
        $status = if (($i % 71) -eq 0) { 502 } else { 200 }
        $bytes = 240 + (($i * 13) % 7000)
        $hint = if (($i % 401) -eq 0) { "masked" } else { "none" }
        $lines.Add("$ts,$rid,$ip,$ua,$route,$status,$bytes,$hint")
    }

    $lines.Add("2026-03-07T14:22:17Z,gw-77889910,185.199.110.42,Mozilla/5.0,/orders,200,612,9f8a7b6c")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TraceEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("checkout-api","auth-gateway","inventory","payments")

    for ($i = 0; $i -lt 5200; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 9).ToString("o")
            trace_id = ("trc-{0:x10}" -f (1800000000 + $i))
            span_id = ("spn-{0:x8}" -f (91000000 + $i))
            service = $services[$i % $services.Count]
            severity = if (($i % 119) -eq 0) { "warn" } else { "info" }
            message = if (($i % 119) -eq 0) { "transient parse issue in request metadata" } else { "request completed" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T14:22:17Z"
        trace_id = "trc-9ac001f09a"
        span_id = "spn-4455abcd"
        service = "checkout-api"
        severity = "error"
        message = "sensitive token persisted in raw request log buffer"
        exposed_token = "9f8a7b6c"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WafAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,alert_id,severity,rule,src_ip,uri,action,notes")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $rules = @("sql_keyword_detected","suspicious_header_pattern","token_format_anomaly","path_probe")

    for ($i = 0; $i -lt 4300; $i++) {
        $ts = $base.AddSeconds($i * 11).ToString("o")
        $rule = $rules[$i % $rules.Count]
        $sev = if (($i % 137) -eq 0) { "medium" } else { "low" }
        $ip = "10.44.$(10 + ($i % 40)).$((20 + $i) % 220)"
        $uri = "/api/v1/$(@('catalog','orders','profile','cart')[$i % 4])"
        $lines.Add("$ts,waf-$('{0:D7}' -f (9200000 + $i)),$sev,$rule,$ip,$uri,allow,noise-alert")
    }

    $lines.Add("2026-03-07T14:22:19Z,waf-0999901,high,sensitive_token_logged,185.199.110.42,/api/v1/orders,block,token observed in upstream logs token=9f8a7b6c")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 263) -eq 0) { "logging_review" } else { "routine_app_monitoring" }
        $sev = if ($event -eq "logging_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,siem-app-01,$sev,continuous telemetry review")
    }

    $lines.Add("2026-03-07T14:22:17Z,token_exposed_in_logs,siem-app-01,high,raw request logging captured bearer token")
    $lines.Add("2026-03-07T14:22:19Z,waf_correlated_token_event,siem-app-01,high,waf alert references same token value")
    $lines.Add("2026-03-07T14:22:31Z,incident_opened,siem-app-01,high,INC-2026-5211 sensitive token exposure")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LoggingConfig {
    param([string]$OutputPath)

    $content = @'
[logging]
level=INFO
structured=true
enable_raw_request_dump=true
token_redaction=partial
destination=central-log-cluster
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-TokenPolicy {
    param([string]$OutputPath)

    $content = @'
Token Handling Policy (Excerpt)

1) Full authentication tokens must never be written to application or gateway logs.
2) Any token exposure in logs must trigger immediate invalidation and incident response.
3) Raw request logging is prohibited in production unless approved break-glass workflow is active.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M3-08 Log File Exposure (Real-World Investigation Pack)

Scenario:
A production logging misconfiguration exposed sensitive authentication material across centralized logs.

Task:
Analyze the investigation pack and identify the exposed token value.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5211
Severity: High
Queue: SOC + AppSec + Platform

Summary:
SIEM reported sensitive token data in raw request logs. WAF telemetry indicates correlated suspicious activity.

Scope:
- Service: checkout-api
- Window: 2026-03-07 14:22-14:23 UTC
- Focus: determine exact exposed token value
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate app server logs, API gateway telemetry, trace events, WAF alerts, and SIEM timeline.
- Validate the logging misconfiguration and extract the exact exposed token.
- Do not submit masked/noise tokens.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-AppServerLog -OutputPath (Join-Path $bundleRoot "evidence\app\app_server.log")
New-GatewayRequests -OutputPath (Join-Path $bundleRoot "evidence\gateway\api_gateway_requests.csv")
New-TraceEvents -OutputPath (Join-Path $bundleRoot "evidence\observability\trace_events.jsonl")
New-WafAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\waf_alerts.csv")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-LoggingConfig -OutputPath (Join-Path $bundleRoot "evidence\config\logging_runtime.conf")
New-TokenPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\token_handling_policy.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
