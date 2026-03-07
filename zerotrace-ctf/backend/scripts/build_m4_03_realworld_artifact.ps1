param()

$ErrorActionPreference = "Stop"

$bundleName = "m4-03-disk-full"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m4_03_realworld_build"
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

function New-DiskUsageTimeseries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,mount,size_gb,used_gb,avail_gb,use_pct,inodes_pct")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 9200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $size = 50.0
        $used = [Math]::Round(28.0 + (($i * 0.013) % 17.0), 2)
        $avail = [Math]::Round($size - $used, 2)
        $usePct = [Math]::Round(($used / $size) * 100, 1)
        $inodePct = [Math]::Round(40 + (($i * 0.07) % 35), 1)
        $lines.Add("$ts,web-prod-02,/,${size},${used},${avail},${usePct},${inodePct}")
    }

    $lines.Add("2026-03-07T19:02:17Z,web-prod-02,/,50,49.98,0.02,100,97.8")
    $lines.Add("2026-03-07T19:02:18Z,web-prod-02,/,50,50.00,0.00,100,98.1")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SystemJournal {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("nginx","checkout-api","systemd-journald","rsyslogd","backup-agent")
    $hostName = "web-prod-02"

    for ($i = 0; $i -lt 7800; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("MMM dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $svc = $services[$i % $services.Count]
        $sev = if (($i % 121) -eq 0) { "warning" } else { "info" }
        $msg = if ($sev -eq "warning") { "temporary I/O slowdown observed" } else { "service health heartbeat" }
        $lines.Add("$ts $hostName $svc[$(1500 + ($i % 900))]: ${sev}: $msg")
    }

    $lines.Add("Mar 07 19:02:18 web-prod-02 nginx[2311]: error: writev() failed (28: No space left on device)")
    $lines.Add("Mar 07 19:02:18 web-prod-02 checkout-api[4123]: error: cannot persist order cache: No space left on device")
    $lines.Add("Mar 07 19:02:19 web-prod-02 systemd-journald[701]: warning: Failed to write entry, ignoring: No space left on device")
    $lines.Add("Mar 07 19:02:20 web-prod-02 kernel: EXT4-fs warning (device nvme0n1p1): ext4_end_bio: I/O error 10 writing to inode because disk is full")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AppWriteFailures {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,service,request_id,operation,status,error")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $rid = "req-" + ("{0:D8}" -f (73000000 + $i))
        $status = if (($i % 173) -eq 0) { "retry" } else { "ok" }
        $err = if ($status -eq "retry") { "transient_timeout" } else { "-" }
        $lines.Add("$ts,checkout-api,$rid,write_order_cache,$status,$err")
    }

    $lines.Add("2026-03-07T19:02:18Z,checkout-api,req-99900111,write_order_cache,failed,No space left on device")
    $lines.Add("2026-03-07T19:02:19Z,checkout-api,req-99900112,write_payment_log,failed,No space left on device")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TopDiskConsumers {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Disk usage snapshot from / (du -x --max-depth=2)")

    for ($i = 0; $i -lt 6400; $i++) {
        $sz = 20 + (($i * 11) % 900)
        $path = "/var/tmp/workload_$($i % 350)"
        $lines.Add("${sz}M`t$path")
    }

    $lines.Add("17200M`t/var/log")
    $lines.Add("15640M`t/var/log/nginx")
    $lines.Add("12400M`t/var/log/nginx/archive")
    $lines.Add("6400M`t/var/lib/docker")
    $lines.Add("2200M`t/opt/app/cache")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LogrotateRunLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4800; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $lines.Add("$ts INFO logrotate run_id=lr-$('{0:D7}' -f (5100000 + $i)) status=skip reason=no_rotation_needed")
    }

    $lines.Add("2026-03-07T19:02:15Z WARN logrotate run_id=lr-9999991 status=skip reason=rotation_disabled_for_nginx_logs")
    $lines.Add("2026-03-07T19:02:19Z ERROR logrotate run_id=lr-9999992 status=failed reason=No space left on device")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Alerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("cpu_watch","latency_watch","io_watch","error_rate_watch")

    for ($i = 0; $i -lt 4400; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "ops-" + ("{0:D8}" -f (83000000 + $i))
            severity = if (($i % 147) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "baseline fluctuation"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T19:02:18Z"
        alert_id = "ops-99955121"
        severity = "critical"
        type = "storage_exhaustion"
        status = "open"
        detail = "root filesystem reached 100% utilization; write failures observed"
        root_cause = "disk_full"
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
        $evt = if (($i % 271) -eq 0) { "storage_health_review" } else { "routine_host_monitoring" }
        $sev = if ($evt -eq "storage_health_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-storage-01,$sev,background host telemetry review")
    }

    $lines.Add("2026-03-07T19:02:18Z,root_filesystem_full,siem-storage-01,critical,/ at 100% utilization with 0GB available")
    $lines.Add("2026-03-07T19:02:19Z,service_write_failures,siem-storage-01,high,multiple 'No space left on device' errors")
    $lines.Add("2026-03-07T19:02:24Z,root_cause_classified,siem-storage-01,high,classified outage root cause as disk_full")
    $lines.Add("2026-03-07T19:02:30Z,incident_opened,siem-storage-01,high,INC-2026-5328 disk exhaustion incident")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Config {
    param([string]$OutputPath)

    $content = @'
/var/log/nginx/*.log {
    daily
    rotate 0
    compress
    missingok
    notifempty
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Storage Outage Runbook (Excerpt)

1) Validate filesystem usage and free space on root mount.
2) Correlate service write failures with system journal errors.
3) If root filesystem reaches 100% with write failures, classify root cause as disk_full.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M4-03 Disk Full (Real-World Investigation Pack)

Scenario:
A production node became unavailable and storage telemetry indicated severe disk pressure.

Task:
Analyze the investigation pack and identify the outage root cause.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5328
Severity: High
Queue: SOC + SRE + Platform

Summary:
Application writes began failing during peak traffic and host storage alerts fired.

Scope:
- Host: web-prod-02
- Window: 2026-03-07 19:02 UTC
- Goal: identify root cause classification
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate disk usage telemetry, system journal, application write failures, top disk consumers, logrotate run logs, alerts, runbook, and SIEM timeline.
- Determine the root cause label.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-DiskUsageTimeseries -OutputPath (Join-Path $bundleRoot "evidence\storage\disk_usage_timeseries.csv")
New-SystemJournal -OutputPath (Join-Path $bundleRoot "evidence\system\journal_errors.log")
New-AppWriteFailures -OutputPath (Join-Path $bundleRoot "evidence\app\app_write_failures.csv")
New-TopDiskConsumers -OutputPath (Join-Path $bundleRoot "evidence\storage\top_disk_consumers.txt")
New-LogrotateRunLog -OutputPath (Join-Path $bundleRoot "evidence\ops\logrotate_run.log")
New-Alerts -OutputPath (Join-Path $bundleRoot "evidence\security\storage_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Config -OutputPath (Join-Path $bundleRoot "evidence\config\logrotate_nginx.conf")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\storage_outage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
