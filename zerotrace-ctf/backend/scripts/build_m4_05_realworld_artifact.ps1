param()

$ErrorActionPreference = "Stop"

$bundleName = "m4-05-database-overload"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m4_05_realworld_build"
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

function New-PostgresLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $dbUsers = @("api_user","report_user","etl_user","admin_readonly","worker_user")
    $dbNames = @("orders","analytics","inventory","users")
    $hostName = "db-prod-01"

    for ($i = 0; $i -lt 9200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-dd HH:mm:ss.fff UTC")
        $procId = 30000 + ($i % 600)
        $user = $dbUsers[$i % $dbUsers.Count]
        $db = $dbNames[$i % $dbNames.Count]
        $dur = 2 + (($i * 3) % 2400)
        $sev = if (($i % 167) -eq 0) { "WARNING" } else { "LOG" }
        $msg = if ($sev -eq "WARNING") { "duration ${dur} ms exceeds threshold for query class=reporting" } else { "connection authorized: user=$user database=$db application=app-gateway" }
        $lines.Add("$ts $hostName postgres[$procId]: [$sev] $msg")
    }

    $lines.Add("2026-03-07 21:08:14.001 UTC db-prod-01 postgres[41222]: [FATAL] sorry, too many clients already")
    $lines.Add("2026-03-07 21:08:14.112 UTC db-prod-01 postgres[41223]: [ERROR] remaining connection slots are reserved for non-replication superuser connections")
    $lines.Add("2026-03-07 21:08:14.278 UTC db-prod-01 postgres[41224]: [FATAL] connection limit exceeded for role api_user")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ConnectionTimeseries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,total_connections,active_connections,idle_connections,max_connections,connection_rejects")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 8800; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $max = 300
        $active = 30 + (($i * 4) % 210)
        $idle = 8 + (($i * 3) % 90)
        $total = $active + $idle
        if ($total -gt $max) {
            $total = $max - 2
            $active = $max - 20
            $idle = 18
        }
        $rej = if (($i % 211) -eq 0) { 3 + ($i % 5) } else { 0 }
        $lines.Add("$ts,$total,$active,$idle,$max,$rej")
    }

    $lines.Add("2026-03-07T21:08:14Z,300,298,2,300,147")
    $lines.Add("2026-03-07T21:08:15Z,300,299,1,300,153")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PoolStats {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,pool_name,app_name,pool_size,checked_out,waiting_clients,acquire_timeout_ms")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $pools = @("primary-write","read-replica","analytics-read")
    $apps = @("web-api","order-worker","reporting")

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $pool = $pools[$i % $pools.Count]
        $app = $apps[$i % $apps.Count]
        $size = 100
        $checked = 10 + (($i * 5) % 88)
        $waiting = ($i % 8)
        $timeout = 500 + (($i * 11) % 7000)
        $lines.Add("$ts,$pool,$app,$size,$checked,$waiting,$timeout")
    }

    $lines.Add("2026-03-07T21:08:14Z,primary-write,web-api,100,100,212,30000")
    $lines.Add("2026-03-07T21:08:15Z,primary-write,web-api,100,100,227,30000")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AppDbErrorLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $components = @("orders-api","billing-api","auth-api","report-api")

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $comp = $components[$i % $components.Count]
        $rid = "req-" + ("{0:D8}" -f (82000000 + $i))
        $sev = if (($i % 143) -eq 0) { "WARN" } else { "INFO" }
        $msg = if ($sev -eq "WARN") { "retrying DB call due to transient timeout" } else { "db query completed" }
        $lines.Add("$ts [$sev] component=$comp request_id=$rid $msg")
    }

    $lines.Add("2026-03-07T21:08:14.019Z [ERROR] component=orders-api request_id=req-99912001 DB connection failed: too many clients already")
    $lines.Add("2026-03-07T21:08:14.117Z [ERROR] component=billing-api request_id=req-99912002 DB pool exhausted: connection limit reached")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SlowQuerySummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,query_hash,avg_ms,p95_ms,calls,rows,db")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $dbNames = @("orders","analytics","inventory")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $hash = "qh_" + ("{0:x10}" -f (1400000000 + $i))
        $avg = 8 + (($i * 2) % 400)
        $p95 = $avg + (20 + ($i % 200))
        $calls = 1 + ($i % 1200)
        $rows = 5 + (($i * 19) % 25000)
        $db = $dbNames[$i % $dbNames.Count]
        $lines.Add("$ts,$hash,$avg,$p95,$calls,$rows,$db")
    }

    $lines.Add("2026-03-07T21:08:14Z,qh_hotspot_01,1850,7020,8821,120034,orders")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AlertFeed {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("latency_watch","query_time_watch","cpu_watch","cache_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "db-" + ("{0:D8}" -f (93000000 + $i))
            severity = if (($i % 173) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine fluctuation"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T21:08:14Z"
        alert_id = "db-99944210"
        severity = "critical"
        type = "db_connection_exhaustion"
        status = "open"
        detail = "database max connections reached; clients rejected"
        root_problem = "connection_limit"
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
        $evt = if (($i % 289) -eq 0) { "db_health_review" } else { "routine_db_monitoring" }
        $sev = if ($evt -eq "db_health_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-db-01,$sev,background database monitoring")
    }

    $lines.Add("2026-03-07T21:08:14Z,db_clients_rejected,siem-db-01,critical,too many clients already observed")
    $lines.Add("2026-03-07T21:08:15Z,pool_exhaustion,siem-db-01,high,app pool waiting clients rising above threshold")
    $lines.Add("2026-03-07T21:08:18Z,root_problem_classified,siem-db-01,high,classified underlying problem as connection_limit")
    $lines.Add("2026-03-07T21:08:22Z,incident_opened,siem-db-01,high,INC-2026-5361 database overload outage")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PostgresConfig {
    param([string]$OutputPath)

    $content = @'
max_connections = 300
shared_buffers = 4GB
work_mem = 16MB
maintenance_work_mem = 256MB
log_connections = on
log_disconnections = on
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Database Outage Runbook (Excerpt)

1) Verify if application errors match "too many clients already".
2) Check max_connections against total active/idle clients.
3) If database rejects clients at max limit, classify problem as connection_limit.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M4-05 Database Overload (Real-World Investigation Pack)

Scenario:
A production outage occurred while database traffic surged and connection handling degraded.

Task:
Analyze the investigation pack and identify the underlying problem.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5361
Severity: High
Queue: SOC + SRE + DBA

Summary:
Applications reported DB connection errors, and the service became intermittently unavailable.

Scope:
- Host: db-prod-01
- Window: 2026-03-07 21:08 UTC
- Goal: identify root underlying problem
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate postgres logs, connection metrics, pool stats, app DB errors, slow-query summaries, alerts, config, runbook, and SIEM timeline.
- Determine the underlying outage problem classification.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-PostgresLog -OutputPath (Join-Path $bundleRoot "evidence\db\postgres.log")
New-ConnectionTimeseries -OutputPath (Join-Path $bundleRoot "evidence\db\db_connection_timeseries.csv")
New-PoolStats -OutputPath (Join-Path $bundleRoot "evidence\app\pool_stats.csv")
New-AppDbErrorLog -OutputPath (Join-Path $bundleRoot "evidence\app\app_db_error.log")
New-SlowQuerySummary -OutputPath (Join-Path $bundleRoot "evidence\db\slow_query_summary.csv")
New-AlertFeed -OutputPath (Join-Path $bundleRoot "evidence\security\db_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-PostgresConfig -OutputPath (Join-Path $bundleRoot "evidence\config\postgresql.conf")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\db_outage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
