param()

$ErrorActionPreference = "Stop"

$bundleName = "m4-09-load-balancer-failure"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m4_09_realworld_build"
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

function New-LbHealthChecks {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,lb_node,backend,status,http_code,response_ms,retries,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $backends = @("api01","api02","api03","auth01","billing01")

    for ($i = 0; $i -lt 9200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $node = "lb-" + (1 + ($i % 2))
        $be = $backends[$i % $backends.Count]
        $status = if (($i % 173) -eq 0) { "degraded" } else { "healthy" }
        $code = if ($status -eq "healthy") { 200 } else { 502 }
        $resp = 6 + (($i * 4) % 900)
        $retry = if ($status -eq "healthy") { 0 } else { 1 + ($i % 2) }
        $note = if ($status -eq "healthy") { "ok" } else { "transient backend slowness" }
        $lines.Add("$ts,$node,$be,$status,$code,$resp,$retry,$note")
    }

    $lines.Add("2026-03-08T00:28:11Z,lb-1,api01,unhealthy,503,0,3,backend server api01 unhealthy")
    $lines.Add("2026-03-08T00:28:12Z,lb-2,api01,unhealthy,503,0,3,backend server api01 unhealthy")
    $lines.Add("2026-03-08T00:28:13Z,lb-1,api02,unhealthy,503,0,2,backend server api02 unhealthy")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-UpstreamProxyLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $paths = @("/v1/orders","/v1/items","/v1/users","/v1/health")
    $upstreams = @("api01","api02","api03","auth01")

    for ($i = 0; $i -lt 8400; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $path = $paths[$i % $paths.Count]
        $up = $upstreams[$i % $upstreams.Count]
        $status = if (($i % 181) -eq 0) { 502 } else { 200 }
        $upStatus = if ($status -eq 200) { 200 } else { 503 }
        $lat = 4 + (($i * 5) % 1200)
        $lines.Add("$ts proxy request_id=req-$('{0:D8}' -f (88000000 + $i)) path=$path upstream=$up upstream_status=$upStatus response_status=$status latency_ms=$lat")
    }

    $lines.Add("2026-03-08T00:28:11.007Z proxy request_id=req-99922001 path=/v1/orders upstream=api01 upstream_status=503 response_status=502 latency_ms=0")
    $lines.Add("2026-03-08T00:28:12.052Z proxy request_id=req-99922002 path=/v1/items upstream=api01 upstream_status=503 response_status=502 latency_ms=0")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BackendPoolStats {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,backend,active_conns,max_conns,error_rate_pct,avg_latency_ms,state")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $backends = @("api01","api02","api03","auth01","billing01")

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $be = $backends[$i % $backends.Count]
        $active = 25 + (($i * 4) % 380)
        $max = 500
        $err = [Math]::Round((($i % 18) / 10.0), 1)
        $lat = 8 + (($i * 3) % 450)
        $state = "healthy"
        $lines.Add("$ts,$be,$active,$max,$err,$lat,$state")
    }

    $lines.Add("2026-03-08T00:28:11Z,api01,498,500,92.4,0,unhealthy")
    $lines.Add("2026-03-08T00:28:12Z,api01,500,500,94.1,0,unhealthy")
    $lines.Add("2026-03-08T00:28:13Z,api02,487,500,88.7,0,unhealthy")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ServiceProbeResults {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,backend,probe,result,http_code,error")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $backends = @("api01","api02","api03","auth01")

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $be = $backends[$i % $backends.Count]
        $res = if (($i % 171) -eq 0) { "fail" } else { "pass" }
        $code = if ($res -eq "pass") { 200 } else { 500 }
        $err = if ($res -eq "pass") { "-" } else { "transient_probe_failure" }
        $lines.Add("$ts,$be,/health,$res,$code,$err")
    }

    $lines.Add("2026-03-08T00:28:11Z,api01,/health,fail,503,backend_unreachable")
    $lines.Add("2026-03-08T00:28:12Z,api01,/health,fail,503,backend_unreachable")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TargetRegistrationLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $backends = @("api01","api02","api03","auth01","billing01")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 11).ToString("o")
        $be = $backends[$i % $backends.Count]
        $event = if (($i % 211) -eq 0) { "healthcheck-warning" } else { "heartbeat-ok" }
        $lines.Add("$ts target=$be event=$event target_group=tg-prod-api")
    }

    $lines.Add("2026-03-08T00:28:11Z target=api01 event=marked-unhealthy reason=consecutive_5xx")
    $lines.Add("2026-03-08T00:28:12Z target=api01 event=removed-from-rotation reason=healthcheck_failure")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AlertFeed {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("latency_watch","backend_error_watch","pool_watch","probe_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "lb-" + ("{0:D8}" -f (98000000 + $i))
            severity = if (($i % 177) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine edge fluctuation"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T00:28:11Z"
        alert_id = "lb-99955005"
        severity = "critical"
        type = "backend_service_down"
        status = "open"
        detail = "load balancer marked backend api01 unhealthy"
        affected_backend = "api01"
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
        $evt = if (($i % 313) -eq 0) { "lb_health_review" } else { "routine_lb_monitoring" }
        $sev = if ($evt -eq "lb_health_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-lb-01,$sev,background load balancer telemetry")
    }

    $lines.Add("2026-03-08T00:28:11Z,backend_unhealthy,siem-lb-01,critical,api01 reported unhealthy by both lb nodes")
    $lines.Add("2026-03-08T00:28:12Z,traffic_shifted,siem-lb-01,high,api01 removed from rotation")
    $lines.Add("2026-03-08T00:28:16Z,incident_opened,siem-lb-01,high,INC-2026-5416 load balancer failure incident")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LbConfigSnippet {
    param([string]$OutputPath)

    $content = @'
backend prod_api {
  server api01:8080 max_fails=3 fail_timeout=10s;
  server api02:8080 max_fails=3 fail_timeout=10s;
  server api03:8080 max_fails=3 fail_timeout=10s;
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Load Balancer Outage Runbook (Excerpt)

1) Correlate LB health checks with backend probe failures.
2) Validate which backend is repeatedly marked unhealthy.
3) Identify exact affected backend service name.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M4-09 Load Balancer Failure (Real-World Investigation Pack)

Scenario:
Load balancer health checks detected backend instability and service impact.

Task:
Analyze the investigation pack and identify the affected backend service.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5416
Severity: High
Queue: SOC + NOC + SRE

Summary:
Gateway errors increased sharply while LB nodes marked one backend unhealthy.

Scope:
- Window: 2026-03-08 00:28 UTC
- Goal: identify affected backend service name
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate LB health checks, proxy upstream logs, backend pool stats, service probes, target registration logs, alerts, config, runbook, and SIEM timeline.
- Determine exact backend service impacted.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-LbHealthChecks -OutputPath (Join-Path $bundleRoot "evidence\lb\lb_health_checks.csv")
New-UpstreamProxyLog -OutputPath (Join-Path $bundleRoot "evidence\proxy\upstream_proxy.log")
New-BackendPoolStats -OutputPath (Join-Path $bundleRoot "evidence\lb\backend_pool_stats.csv")
New-ServiceProbeResults -OutputPath (Join-Path $bundleRoot "evidence\service\backend_probe_results.csv")
New-TargetRegistrationLog -OutputPath (Join-Path $bundleRoot "evidence\lb\target_registration.log")
New-AlertFeed -OutputPath (Join-Path $bundleRoot "evidence\security\lb_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-LbConfigSnippet -OutputPath (Join-Path $bundleRoot "evidence\config\lb_backend_config.conf")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\lb_outage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
