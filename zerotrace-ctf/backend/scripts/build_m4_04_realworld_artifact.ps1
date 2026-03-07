param()

$ErrorActionPreference = "Stop"

$bundleName = "m4-04-service-failure"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m4_04_realworld_build"
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

function New-SystemctlSnapshotLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("ssh","cron","docker","redis","postgresql","node-exporter")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $svc = $services[$i % $services.Count]
        $state = if (($i % 181) -eq 0) { "degraded" } else { "active (running)" }
        $lines.Add("$ts systemctl status ${svc}.service -> Active: $state")
    }

    $lines.Add("2026-03-07T20:14:11Z systemctl status nginx.service -> Active: failed (Result: exit-code)")
    $lines.Add("2026-03-07T20:14:11Z systemctl status nginx.service -> Main PID: 0 (code=exited, status=1/FAILURE)")
    $lines.Add("2026-03-07T20:14:12Z systemctl status nginx.service -> Unit entered failed state")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-JournalLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hostName = "web-prod-03"
    $services = @("systemd","docker","redis-server","postgres","sshd","telegraf")

    for ($i = 0; $i -lt 8400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("MMM dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $svc = $services[$i % $services.Count]
        $procId = 2000 + ($i % 1200)
        $sev = if (($i % 133) -eq 0) { "warning" } else { "info" }
        $msg = if ($sev -eq "warning") { "minor transient restart detected" } else { "health heartbeat" }
        $lines.Add("$ts $hostName $svc[$procId]: ${sev}: $msg")
    }

    $lines.Add("Mar 07 20:14:10 web-prod-03 systemd[1]: Starting A high performance web server and a reverse proxy server...")
    $lines.Add("Mar 07 20:14:11 web-prod-03 nginx[4217]: nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)")
    $lines.Add("Mar 07 20:14:11 web-prod-03 systemd[1]: nginx.service: Main process exited, code=exited, status=1/FAILURE")
    $lines.Add("Mar 07 20:14:11 web-prod-03 systemd[1]: nginx.service: Failed with result 'exit-code'.")
    $lines.Add("Mar 07 20:14:11 web-prod-03 systemd[1]: Failed to start A high performance web server and a reverse proxy server.")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ServiceHealthMatrix {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,service,state,cpu_pct,mem_mb,restarts_last_1h,last_exit_code")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("redis","postgresql","sshd","docker","node-exporter")

    for ($i = 0; $i -lt 6900; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $svc = $services[$i % $services.Count]
        $state = "running"
        $cpu = [Math]::Round(2 + (($i * 0.9) % 34), 1)
        $mem = 60 + (($i * 7) % 1800)
        $rst = ($i % 3)
        $exit = 0
        $lines.Add("$ts,$svc,$state,$cpu,$mem,$rst,$exit")
    }

    $lines.Add("2026-03-07T20:14:11Z,nginx,failed,0.0,0,6,1")
    $lines.Add("2026-03-07T20:14:12Z,nginx,failed,0.0,0,7,1")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PortProbeLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,target,port,protocol,result,latency_ms,error")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $port = if (($i % 2) -eq 0) { 443 } else { 22 }
        $proto = if ($port -eq 443) { "tcp" } else { "ssh" }
        $res = "ok"
        $lat = 2 + (($i * 3) % 160)
        $err = "-"
        $lines.Add("$ts,web-prod-03,$port,$proto,$res,$lat,$err")
    }

    $lines.Add("2026-03-07T20:14:11Z,web-prod-03,80,tcp,failed,0,connection_refused")
    $lines.Add("2026-03-07T20:14:11Z,web-prod-03,443,tcp,failed,0,connection_refused")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AlertFeed {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("latency_watch","cpu_watch","memory_watch","transient_restart")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "svc-" + ("{0:D8}" -f (72000000 + $i))
            severity = if (($i % 151) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine service fluctuation"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T20:14:11Z"
        alert_id = "svc-99988123"
        severity = "critical"
        type = "service_down"
        status = "open"
        detail = "systemd reports nginx.service in failed state"
        failed_service = "nginx"
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
        $evt = if (($i % 297) -eq 0) { "service_state_review" } else { "routine_service_monitoring" }
        $sev = if ($evt -eq "service_state_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-service-01,$sev,background service telemetry")
    }

    $lines.Add("2026-03-07T20:14:11Z,service_failed,siem-service-01,critical,nginx.service reported failed by systemd")
    $lines.Add("2026-03-07T20:14:12Z,web_unreachable,siem-service-01,high,http probes failed on ports 80 and 443")
    $lines.Add("2026-03-07T20:14:16Z,incident_opened,siem-service-01,high,INC-2026-5344 service failure investigation")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SystemdUnit {
    param([string]$OutputPath)

    $content = @'
[Unit]
Description=A high performance web server and a reverse proxy server
After=network-online.target

[Service]
Type=forking
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Service Failure Runbook (Excerpt)

1) Check systemd status for failed units.
2) Correlate journal errors with probe failures.
3) Identify exact service unit in failed state as outage root service.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M4-04 Service Failure (Real-World Investigation Pack)

Scenario:
A web outage was detected and service-state telemetry was collected from the affected node.

Task:
Analyze the investigation pack and identify which service failed.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5344
Severity: High
Queue: SOC + SRE + Platform

Summary:
Web endpoint checks failed, and system service telemetry indicates unit failure on web-prod-03.

Scope:
- Host: web-prod-03
- Window: 2026-03-07 20:14 UTC
- Goal: identify failed service name
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate systemctl snapshots, journal logs, service health matrix, probe results, alert feed, unit file context, runbook, and SIEM timeline.
- Determine the exact failed service.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-SystemctlSnapshotLog -OutputPath (Join-Path $bundleRoot "evidence\systemd\systemctl_snapshot.log")
New-JournalLog -OutputPath (Join-Path $bundleRoot "evidence\system\journal_service.log")
New-ServiceHealthMatrix -OutputPath (Join-Path $bundleRoot "evidence\service\service_health_matrix.csv")
New-PortProbeLog -OutputPath (Join-Path $bundleRoot "evidence\network\port_probe_results.csv")
New-AlertFeed -OutputPath (Join-Path $bundleRoot "evidence\security\service_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-SystemdUnit -OutputPath (Join-Path $bundleRoot "evidence\config\nginx.service")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\service_failure_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
