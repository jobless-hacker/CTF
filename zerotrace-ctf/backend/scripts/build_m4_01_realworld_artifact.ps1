param()

$ErrorActionPreference = "Stop"

$bundleName = "m4-01-web-server-crash"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m4_01_realworld_build"
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

function New-NginxErrorLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $events = @(
        "upstream response buffered to temporary file",
        "client body buffer warning",
        "upstream keepalive reused",
        "epoll wait timeout",
        "temporary DNS lookup latency"
    )

    for ($i = 0; $i -lt 9800; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy/MM/dd HH:mm:ss")
        $procId = 13000 + ($i % 90)
        $wid = 200 + ($i % 16)
        $msg = $events[$i % $events.Count]
        $sev = if (($i % 121) -eq 0) { "warn" } else { "info" }
        $lines.Add("$ts [$sev] ${procId}#${wid}: *$((800000 + $i)) $msg, client: 10.22.$(30 + ($i % 40)).$((50 + $i) % 200), server: www.company.example, request: ""GET /health HTTP/1.1"", host: ""www.company.example""")
    }

    $lines.Add("2026/03/07 17:42:13 [error] 13791#224: *908120 worker_connections are not enough while connecting to upstream, client: 185.199.110.42, server: www.company.example, request: ""GET / HTTP/1.1"", host: ""www.company.example""")
    $lines.Add("2026/03/07 17:42:14 [error] 13791#224: *908121 server reached connection limit, client: 185.199.110.42, server: www.company.example, request: ""GET /products HTTP/1.1"", host: ""www.company.example""")
    $lines.Add("2026/03/07 17:42:15 [error] 13791#224: *908122 upstream prematurely closed connection while reading response header from upstream, client: 185.199.110.42, server: www.company.example, request: ""GET / HTTP/1.1"", upstream: ""http://127.0.0.1:9000/"", host: ""www.company.example"", final_status=503")
    $lines.Add("2026/03/07 17:42:16 [error] 13791#224: *908123 generated response ""503 Service Unavailable"" for request id req-908123")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WebStatusTimeseries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,total_requests,status_200,status_302,status_404,status_500,status_503")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 8600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $req = 100 + (($i * 5) % 1700)
        $s200 = [Math]::Max(0, $req - (10 + ($i % 20)))
        $s302 = 4 + ($i % 5)
        $s404 = 2 + ($i % 7)
        $s500 = if (($i % 103) -eq 0) { 6 } else { 0 }
        $s503 = 0
        $lines.Add("$ts,$req,$s200,$s302,$s404,$s500,$s503")
    }

    $lines.Add("2026-03-07T17:42:15Z,1890,430,3,7,22,1428")
    $lines.Add("2026-03-07T17:42:16Z,1760,400,2,5,18,1335")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LbHealthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,lb_node,target,status,http_code,response_ms,notes")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $targets = @("web-a","web-b","web-c")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $node = "lb-" + (1 + ($i % 2))
        $target = $targets[$i % $targets.Count]
        $status = if (($i % 149) -eq 0) { "degraded" } else { "healthy" }
        $code = if ($status -eq "degraded") { 500 } else { 200 }
        $lat = 5 + (($i * 7) % 140)
        $note = if ($status -eq "degraded") { "transient backend timeout" } else { "ok" }
        $lines.Add("$ts,$node,$target,$status,$code,$lat,$note")
    }

    $lines.Add("2026-03-07T17:42:15Z,lb-1,web-a,unhealthy,503,912,backend overloaded")
    $lines.Add("2026-03-07T17:42:16Z,lb-2,web-b,unhealthy,503,887,backend overloaded")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HostMetrics {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,cpu_pct,mem_pct,active_connections,open_fds,listen_queue,swap_pct")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $cpu = [Math]::Round(20 + (($i * 3) % 55) + (($i % 9) / 10.0), 1)
        $mem = [Math]::Round(42 + (($i * 5) % 45) + (($i % 7) / 10.0), 1)
        $conn = 120 + (($i * 11) % 2400)
        $fds = 500 + (($i * 13) % 8000)
        $queue = 1 + ($i % 40)
        $swap = [Math]::Round(($i % 9) / 2.0, 1)
        $lines.Add("$ts,web-prod-01,$cpu,$mem,$conn,$fds,$queue,$swap")
    }

    $lines.Add("2026-03-07T17:42:15Z,web-prod-01,97.8,94.1,10982,65534,512,18.4")
    $lines.Add("2026-03-07T17:42:16Z,web-prod-01,98.2,94.7,11101,65535,520,19.1")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AlertEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("latency_watch","error_budget_watch","cpu_watch","memory_watch")

    for ($i = 0; $i -lt 4400; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "ops-" + ("{0:D8}" -f (51000000 + $i))
            type = $types[$i % $types.Count]
            severity = if (($i % 133) -eq 0) { "medium" } else { "low" }
            status = "closed_noise"
            detail = "baseline fluctuation"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T17:42:15Z"
        alert_id = "ops-99900421"
        type = "web_outage_http_error"
        severity = "critical"
        status = "open"
        detail = "customer traffic receiving HTTP 503 from web service"
        http_error = 503
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $evt = if (($i % 311) -eq 0) { "availability_review" } else { "routine_service_monitoring" }
        $sev = if ($evt -eq "availability_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-ops-01,$sev,regular availability telemetry")
    }

    $lines.Add("2026-03-07T17:42:15Z,web_service_unavailable,siem-ops-01,critical,customer-facing web requests returned HTTP 503")
    $lines.Add("2026-03-07T17:42:16Z,lb_health_degraded,siem-ops-01,high,load balancer confirms unhealthy backend with HTTP 503")
    $lines.Add("2026-03-07T17:42:23Z,incident_opened,siem-ops-01,high,INC-2026-5301 web server crash investigation")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NginxConfig {
    param([string]$OutputPath)

    $content = @'
worker_processes auto;
events {
    worker_connections 1024;
    multi_accept on;
}
http {
    keepalive_timeout 15;
    server_tokens off;
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Web Availability Runbook (Excerpt)

1) Validate HTTP status impact from edge, LB, and application logs.
2) Confirm if outage status code is 5xx and identify exact returned code.
3) Cross-check host resource saturation and worker connection limits.
4) Open incident if customer traffic receives persistent 503 or 504 responses.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M4-01 Web Server Crash (Real-World Investigation Pack)

Scenario:
Customers reported the website was down and monitoring detected a major availability degradation.

Task:
Analyze the investigation pack and identify the HTTP error code returned by the web service during outage.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5301
Severity: High
Queue: SOC + SRE + Platform

Summary:
Website availability dropped abruptly and upstream requests started failing.

Scope:
- Service: www.company.example
- Outage window: 2026-03-07 17:42 UTC
- Goal: identify exact HTTP error code seen by users
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate nginx error logs, status timeseries, LB health checks, host metrics, alert feed, runbook, and SIEM timeline.
- Determine the exact outage HTTP code returned to users.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-NginxErrorLog -OutputPath (Join-Path $bundleRoot "evidence\web\nginx_error.log")
New-WebStatusTimeseries -OutputPath (Join-Path $bundleRoot "evidence\web\web_status_timeseries.csv")
New-LbHealthLog -OutputPath (Join-Path $bundleRoot "evidence\loadbalancer\lb_health_checks.csv")
New-HostMetrics -OutputPath (Join-Path $bundleRoot "evidence\host\host_resource_metrics.csv")
New-AlertEvents -OutputPath (Join-Path $bundleRoot "evidence\security\ops_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-NginxConfig -OutputPath (Join-Path $bundleRoot "evidence\config\nginx_runtime.conf")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\web_availability_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
