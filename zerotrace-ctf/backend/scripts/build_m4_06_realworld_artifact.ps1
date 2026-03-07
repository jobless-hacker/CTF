param()

$ErrorActionPreference = "Stop"

$bundleName = "m4-06-container-crash"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m4_06_realworld_build"
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

function New-DockerDaemonLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $engineHost = "container-node-02"
    $containers = @("auth-api","billing-worker","report-queue","metrics-sidecar","catalog-api")

    for ($i = 0; $i -lt 9200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $ctr = $containers[$i % $containers.Count]
        $sev = if (($i % 177) -eq 0) { "WARN" } else { "INFO" }
        $msg = if ($sev -eq "WARN") { "healthcheck retry for container $ctr" } else { "container heartbeat: $ctr running" }
        $lines.Add("$ts dockerd[$(6000 + ($i % 900))] $engineHost $sev $msg")
    }

    $lines.Add("2026-03-07T22:06:41.118Z dockerd[6781] container-node-02 ERROR Error response from daemon: container web-app exited unexpectedly")
    $lines.Add("2026-03-07T22:06:41.221Z dockerd[6781] container-node-02 ERROR container web-app restart failed: OCI runtime create failed")
    $lines.Add("2026-03-07T22:06:42.004Z dockerd[6781] container-node-02 WARN service endpoint / returned 502 after container exit")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ContainerEventStream {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $containers = @("auth-api","billing-worker","report-queue","metrics-sidecar","catalog-api")
    $statuses = @("start","health_status: healthy","exec_start","exec_die","health_status: healthy")

    for ($i = 0; $i -lt 7600; $i++) {
        $entry = [ordered]@{
            time = $base.AddSeconds($i * 8).ToString("o")
            type = "container"
            actor = $containers[$i % $containers.Count]
            status = $statuses[$i % $statuses.Count]
            node = "container-node-02"
            image = "registry.local/" + $containers[$i % $containers.Count] + ":stable"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        time = "2026-03-07T22:06:41Z"
        type = "container"
        actor = "web-app"
        status = "die"
        node = "container-node-02"
        image = "registry.local/web-app:2026.03.07"
        exitCode = 137
        error = "container web-app exited unexpectedly"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        time = "2026-03-07T22:06:41Z"
        type = "container"
        actor = "web-app"
        status = "restart"
        node = "container-node-02"
        image = "registry.local/web-app:2026.03.07"
        result = "failed"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ContainerInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,container_name,image,node,state,restarts,uptime_minutes")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $names = @("auth-api","billing-worker","report-queue","metrics-sidecar","catalog-api")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $name = $names[$i % $names.Count]
        $img = "registry.local/$name:stable"
        $rst = $i % 4
        $up = 30 + (($i * 5) % 8000)
        $lines.Add("$ts,$name,$img,container-node-02,running,$rst,$up")
    }

    $lines.Add("2026-03-07T22:06:41Z,web-app,registry.local/web-app:2026.03.07,container-node-02,exited,9,0")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ServiceProbeResults {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,service,endpoint,status_code,latency_ms,result,error")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $status = if (($i % 141) -eq 0) { 500 } else { 200 }
        $res = if ($status -eq 200) { "pass" } else { "retry" }
        $err = if ($status -eq 200) { "-" } else { "transient_backend_error" }
        $lat = 5 + (($i * 7) % 600)
        $lines.Add("$ts,web-gateway,/,${status},$lat,$res,$err")
    }

    $lines.Add("2026-03-07T22:06:41Z,web-gateway,/,502,0,fail,upstream_container_down")
    $lines.Add("2026-03-07T22:06:42Z,web-gateway,/,502,0,fail,upstream_container_down")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ContainerResourceMetrics {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,container_name,cpu_pct,mem_mb,mem_limit_mb,restarts_last_1h,oom_kills")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $containers = @("auth-api","billing-worker","report-queue","metrics-sidecar","catalog-api")

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $name = $containers[$i % $containers.Count]
        $cpu = [Math]::Round(3 + (($i * 0.8) % 75), 1)
        $mem = 60 + (($i * 5) % 1300)
        $memLimit = 2048
        $rst = $i % 5
        $oom = 0
        $lines.Add("$ts,$name,$cpu,$mem,$memLimit,$rst,$oom")
    }

    $lines.Add("2026-03-07T22:06:41Z,web-app,0.0,0,2048,9,1")
    $lines.Add("2026-03-07T22:06:42Z,web-app,0.0,0,2048,10,1")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AlertFeed {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("latency_watch","cpu_watch","mem_watch","restart_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "ctr-" + ("{0:D8}" -f (94000000 + $i))
            severity = if (($i % 163) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine platform fluctuation"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T22:06:41Z"
        alert_id = "ctr-99977011"
        severity = "critical"
        type = "container_crash"
        status = "open"
        detail = "container web-app exited unexpectedly"
        crashed_container = "web-app"
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
        $evt = if (($i % 301) -eq 0) { "container_health_review" } else { "routine_container_monitoring" }
        $sev = if ($evt -eq "container_health_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-container-01,$sev,background container telemetry")
    }

    $lines.Add("2026-03-07T22:06:41Z,container_died,siem-container-01,critical,web-app container died on container-node-02")
    $lines.Add("2026-03-07T22:06:42Z,service_degraded,siem-container-01,high,web-gateway probes returning 502 due to upstream container failure")
    $lines.Add("2026-03-07T22:06:46Z,incident_opened,siem-container-01,high,INC-2026-5375 container crash outage")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ComposeSnippet {
    param([string]$OutputPath)

    $content = @'
services:
  web-app:
    image: registry.local/web-app:2026.03.07
    restart: always
    mem_limit: 2g
    ports:
      - "8080:8080"
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Container Crash Runbook (Excerpt)

1) Identify container die events from runtime logs/events.
2) Correlate with probe failures and restart attempts.
3) Report exact crashed container name as primary outage unit.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M4-06 Container Crash (Real-World Investigation Pack)

Scenario:
A production service degraded when one application container abruptly exited.

Task:
Analyze the investigation pack and identify which container crashed.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5375
Severity: High
Queue: SOC + SRE + Platform

Summary:
Runtime alerts indicate container instability on container-node-02 and customer-facing impact.

Scope:
- Node: container-node-02
- Window: 2026-03-07 22:06 UTC
- Goal: identify exact crashed container name
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate docker daemon logs, event stream, inventory, probes, resource metrics, alerts, compose snippet, runbook, and SIEM timeline.
- Determine the crashed container name.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-DockerDaemonLog -OutputPath (Join-Path $bundleRoot "evidence\runtime\dockerd.log")
New-ContainerEventStream -OutputPath (Join-Path $bundleRoot "evidence\runtime\container_events.jsonl")
New-ContainerInventory -OutputPath (Join-Path $bundleRoot "evidence\runtime\container_inventory.csv")
New-ServiceProbeResults -OutputPath (Join-Path $bundleRoot "evidence\service\probe_results.csv")
New-ContainerResourceMetrics -OutputPath (Join-Path $bundleRoot "evidence\metrics\container_resource_metrics.csv")
New-AlertFeed -OutputPath (Join-Path $bundleRoot "evidence\security\container_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-ComposeSnippet -OutputPath (Join-Path $bundleRoot "evidence\config\docker-compose-snippet.yml")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\container_crash_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
