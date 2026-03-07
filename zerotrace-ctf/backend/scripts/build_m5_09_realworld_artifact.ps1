param()

$ErrorActionPreference = "Stop"

$bundleName = "m5-09-log-tampering"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m5_09_realworld_build"
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

function New-SyslogTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("systemd","sshd","kernel","cron","dockerd","rsyslogd","nginx")

    for ($i = 0; $i -lt 9100; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("MMM dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $svc = $services[$i % $services.Count]
        $procId = 1200 + ($i % 20000)
        $msg = if (($i % 173) -eq 0) { "healthcheck completed" } else { "service status heartbeat ok" }
        $lines.Add("$ts lin-log-04 $svc[$procId]: $msg")
    }

    $lines.Add("Mar 08 08:12:07 lin-log-04 sshd[23811]: Accepted password for root from 203.0.113.72 port 49102 ssh2")
    $lines.Add("Mar 08 08:12:09 lin-log-04 sudo: root : TTY=pts/0 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/truncate -s 0 /var/log/syslog")
    $lines.Add("Mar 08 08:12:10 lin-log-04 rsyslogd[947]: imuxsock begins to drop messages due to stream reset")
    $lines.Add("Mar 08 08:12:11 lin-log-04 kernel: *** log truncated ***")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("opsadmin","deploy","appsvc","backup")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("MMM dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $acct = $users[$i % $users.Count]
        $src = "10.$(30 + ($i % 20)).$((10 + $i) % 220).$((30 + $i) % 220)"
        $lines.Add("$ts lin-log-04 sshd[$(16000 + ($i % 900))]: Accepted publickey for $acct from $src port $((30000 + $i) % 65000) ssh2")
    }

    $lines.Add("Mar 08 08:12:07 lin-log-04 sshd[23811]: Accepted password for root from 203.0.113.72 port 49102 ssh2")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LogRotateAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $action = if (($i % 23) -eq 0) { "rotate" } else { "compress" }
        $file = if (($i % 2) -eq 0) { "/var/log/nginx/access.log" } else { "/var/log/auth.log" }
        $lines.Add("$ts logrotate node=lin-log-04 action=$action file=$file result=success")
    }

    $lines.Add('2026-03-08T08:12:09Z auditd node=lin-log-04 user=root command="truncate -s 0 /var/log/syslog" result=success')
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HashBaseline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,node,path,expected_sha256,current_sha256,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 11).ToString("o")
        $path = if (($i % 2) -eq 0) { "/var/log/auth.log" } else { "/var/log/nginx/error.log" }
        $hash = "{0:x64}" -f (8000000000000000 + $i)
        $lines.Add("$ts,lin-log-04,$path,$hash,$hash,ok")
    }

    $lines.Add("2026-03-08T08:12:12Z,lin-log-04,/var/log/syslog,2f8e0f96f194f5a25a7b3b7ec6b78af44ab7a9a0e1ec89de77992ad917b77f12,0000000000000000000000000000000000000000000000000000000000000000,mismatch")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LogIntegrityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("log_integrity_watch","sequence_gap_watch","audit_policy_watch","auth_review")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "log-" + ("{0:D8}" -f (97000000 + $i))
            severity = if (($i % 181) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine log pipeline monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T08:12:11Z"
        alert_id = "log-99990119"
        severity = "critical"
        type = "log_tampering_detected"
        status = "open"
        detail = "security log stream indicates forced truncation event"
        altered_indicator = "log_truncated"
        node = "lin-log-04"
    }) | ConvertTo-Json -Compress))
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $evt = if (($i % 257) -eq 0) { "log_integrity_review" } else { "routine_log_ingestion" }
        $sev = if ($evt -eq "log_integrity_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-log-01,$sev,log pipeline baseline telemetry")
    }

    $lines.Add("2026-03-08T08:12:09Z,unauthorized_log_command,siem-log-01,high,truncate command targeted /var/log/syslog")
    $lines.Add("2026-03-08T08:12:11Z,log_tamper_marker,siem-log-01,critical,altered indicator observed: log_truncated")
    $lines.Add("2026-03-08T08:12:20Z,incident_opened,siem-log-01,high,INC-2026-5509 log tampering investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Security Log Integrity Policy (Excerpt)

1) Manual truncation/deletion of system logs is prohibited.
2) Incident triage must capture altered-log indicator value.
3) Any log truncation marker is treated as critical tampering evidence.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Log Tampering Investigation Runbook (Excerpt)

1) Correlate auth access with log-management commands.
2) Validate marker evidence in syslog and SIEM timeline.
3) Confirm integrity mismatch via file-hash baseline.
4) Extract altered indicator and escalate containment.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M5-09 Log Tampering (Real-World Investigation Pack)

Scenario:
SOC analysts suspect an attacker attempted to erase traces by tampering with Linux system logs.

Task:
Analyze the investigation pack and identify the altered log indicator.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5509
Severity: High
Queue: SOC + DFIR + Linux Ops

Summary:
A privileged session executed suspicious log-management commands during active incident window.

Scope:
- Node: lin-log-04
- Window: 2026-03-08 08:12 UTC
- Goal: identify altered log indicator
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate syslog timeline, auth records, logrotate/audit commands, hash mismatch evidence, integrity alerts, SIEM timeline, and policy/runbook context.
- Determine the altered log indicator value.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-SyslogTimeline -OutputPath (Join-Path $bundleRoot "evidence\logs\syslog_timeline.log")
New-AuthLog -OutputPath (Join-Path $bundleRoot "evidence\logs\auth.log")
New-LogRotateAudit -OutputPath (Join-Path $bundleRoot "evidence\logs\logrotate_audit.log")
New-HashBaseline -OutputPath (Join-Path $bundleRoot "evidence\logs\log_hash_baseline.csv")
New-LogIntegrityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\log_integrity_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\security_log_integrity_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\log_tampering_investigation_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
