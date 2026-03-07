param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-13-siem-alert-investigation"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_13_realworld_build"
$bundleRoot = Join-Path $buildRoot $bundleName

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

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
    param(
        [string]$Path,
        [System.Collections.Generic.List[string]]$Lines
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    [System.IO.File]::WriteAllLines($Path, $Lines, [System.Text.Encoding]::UTF8)
}

function New-SiemAlertsStream {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:30:00", [DateTimeKind]::Utc)
    $hosts = @("server01","server02","server03","api-01","db-01")
    $rules = @("linux_auth_failure_volume","suspicious_sudo_pattern","endpoint_process_chain")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 2).ToString("o")
        $hostName = $hosts[$i % $hosts.Count]
        $rule = $rules[$i % $rules.Count]
        $sev = if (($i % 11) -eq 0) { "medium" } else { "low" }
        $status = if (($i % 13) -eq 0) { "closed_false_positive" } else { "resolved" }
        $entry = [ordered]@{
            timestamp = $ts
            alert_id = "ALRT-$((400000 + $i))"
            host = $hostName
            rule = $rule
            severity = $sev
            status = $status
            reason = if ($status -eq "closed_false_positive") { "known maintenance window behavior" } else { "normal triage closure" }
            source = "siem-core-01"
        }
        $lines.Add(($entry | ConvertTo-Json -Depth 6 -Compress))
    }

    $incidentAlert = [ordered]@{
        timestamp = "2026-03-06T12:41:18Z"
        alert_id = "ALRT-INC-1301"
        host = "server01"
        rule = "linux_security_log_anomaly"
        severity = "high"
        status = "open"
        reason = "auth.log size dropped by 100 percent within 3 seconds of privileged shell activity"
        source = "siem-core-01"
        correlated_events = @(
            "root_login_10.40.8.19",
            "process_tail_auth_log",
            "process_truncate_auth_log"
        )
    }
    $lines.Add(($incidentAlert | ConvertTo-Json -Depth 8 -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,event_type,details,source,severity")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:30:00", [DateTimeKind]::Utc)
    $hosts = @("server01","server02","server03","api-01","db-01")

    for ($i = 0; $i -lt 9100; $i++) {
        $ts = $base.AddMilliseconds($i * 500).ToString("o")
        $hostName = $hosts[$i % $hosts.Count]
        $etype = if (($i % 9) -eq 0) { "auth_failed" } elseif (($i % 17) -eq 0) { "sudo_command" } else { "session_activity" }
        $detail = if ($etype -eq "auth_failed") { "failed ssh for invalid user test from 203.0.113.$(20 + ($i % 120))" } elseif ($etype -eq "sudo_command") { "/usr/bin/systemctl status app-api" } else { "interactive shell activity observed" }
        $sev = if ($etype -eq "auth_failed") { "low" } else { "info" }
        $lines.Add("$ts,$hostName,$etype,$detail,host-collector,$sev")
    }

    $lines.Add("2026-03-06T12:41:09Z,server01,sshd_login,root login from 10.40.8.19,authd,medium")
    $lines.Add("2026-03-06T12:41:11Z,server01,process_start,/usr/bin/tail -n 50 /var/log/auth.log,auditd,medium")
    $lines.Add("2026-03-06T12:41:13Z,server01,process_start,/usr/bin/truncate -s 0 /var/log/auth.log,auditd,high")
    $lines.Add("2026-03-06T12:41:18Z,server01,siem_alert,linux_security_log_anomaly,siem-core-01,high")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuditdFullLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $baseTs = 1772800000.120

    for ($i = 0; $i -lt 12400; $i++) {
        $ts = "{0:N3}" -f ($baseTs + ($i * 0.45))
        $eid = 83000 + $i
        $uid = if (($i % 7) -eq 0) { 1002 } else { 1001 }
        $comm = if (($i % 10) -eq 0) { "grep" } elseif (($i % 13) -eq 0) { "cat" } else { "tail" }
        $exe = "/usr/bin/$comm"
        $file = if (($i % 9) -eq 0) { "/var/log/nginx/access.log" } else { "/var/log/auth.log" }
        $lines.Add("type=SYSCALL msg=audit(${ts}:${eid}): arch=c000003e syscall=2 success=yes exit=3 a0=7ff a1=0 a2=0 a3=0 items=1 ppid=2200 pid=$(3000 + ($i % 4000)) auid=$uid uid=0 gid=0 euid=0 tty=pts0 ses=104 comm=""$comm"" exe=""$exe"" key=""log_watch""")
        $lines.Add("type=PATH msg=audit(${ts}:${eid}): item=0 name=""$file"" inode=$(540000 + ($i % 9000)) dev=fd:00 mode=0100640 ouid=0 ogid=4 rdev=00:00 nametype=NORMAL")
    }

    # Benign logrotate event
    $lines.Add("type=SYSCALL msg=audit(1772804060.201:99000): arch=c000003e syscall=76 success=yes exit=0 a0=7ff a1=7ff a2=0 a3=0 items=1 ppid=1 pid=4411 auid=0 uid=0 gid=0 euid=0 tty=(none) ses=1 comm=""logrotate"" exe=""/usr/sbin/logrotate"" key=""logrotate""")
    $lines.Add("type=PATH msg=audit(1772804060.201:99000): item=0 name=""/var/log/nginx/access.log"" inode=445511 dev=fd:00 mode=0100640 ouid=0 ogid=4 rdev=00:00 nametype=NORMAL")

    # Incident sequence
    $lines.Add("type=SYSCALL msg=audit(1772804471.108:99439): arch=c000003e syscall=2 success=yes exit=3 a0=7ffc18d1d490 a1=0 a2=0 items=1 ppid=2210 pid=2231 auid=0 uid=0 gid=0 euid=0 tty=pts0 comm=""tail"" exe=""/usr/bin/tail"" key=""log_read""")
    $lines.Add("type=PATH msg=audit(1772804471.108:99439): item=0 name=""/var/log/auth.log"" inode=942018 dev=fd:00 mode=0100640 ouid=0 ogid=4 rdev=00:00 nametype=NORMAL")
    $lines.Add("type=SYSCALL msg=audit(1772804473.412:99441): arch=c000003e syscall=2 success=yes exit=3 a0=7ffc18d1d521 a1=241 a2=1b6 items=1 ppid=2210 pid=2236 auid=0 uid=0 gid=0 euid=0 tty=pts0 comm=""truncate"" exe=""/usr/bin/truncate"" key=""log_clear""")
    $lines.Add("type=PATH msg=audit(1772804473.412:99441): item=0 name=""/var/log/auth.log"" inode=942018 dev=fd:00 mode=0100640 ouid=0 ogid=4 rdev=00:00 nametype=NORMAL")
    $lines.Add("type=PROCTITLE msg=audit(1772804473.412:99441): proctitle=7472756E63617465002D730030002F7661722F6C6F672F617574682E6C6F67")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthLogSizeSeries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,file,size_bytes,delta_bytes,event_tag")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T12:30:00", [DateTimeKind]::Utc)

    $size = 188000
    for ($i = 0; $i -lt 6200; $i++) {
        $tsObj = $base.AddMilliseconds($i * 300)
        $ts = $tsObj.ToString("o")
        $delta = (($i % 7) * 48) - 80
        $size = [Math]::Max(0, $size + $delta)
        $tag = "steady-write"

        # benign compaction pattern
        if (($i % 900) -eq 0) {
            $size = [Math]::Max(10000, $size - 3000)
            $tag = "rotation-near-threshold"
        }

        # incident absolute drop
        if ($tsObj -ge [datetime]::SpecifyKind([datetime]"2026-03-06T12:41:13", [DateTimeKind]::Utc) -and
            $tsObj -le [datetime]::SpecifyKind([datetime]"2026-03-06T12:41:14", [DateTimeKind]::Utc)) {
            $delta = -1 * $size
            $size = 0
            $tag = "sudden-truncate"
        }

        if ($tsObj -gt [datetime]::SpecifyKind([datetime]"2026-03-06T12:41:14", [DateTimeKind]::Utc) -and
            $tsObj -lt [datetime]::SpecifyKind([datetime]"2026-03-06T12:42:00", [DateTimeKind]::Utc)) {
            $delta = 140 + (($i * 5) % 340)
            $size += $delta
            $tag = "post-truncate-rewrite"
        }

        $lines.Add("$ts,server01,/var/log/auth.log,$size,$delta,$tag")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SudoAndSessionLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T12:20:00", [DateTimeKind]::Utc)
    $users = @("deploy","svc_api","backup","analyst","root")

    for ($i = 0; $i -lt 5800; $i++) {
        $ts = $base.AddMilliseconds($i * 420)
        $stamp = $ts.ToString("MMM dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $user = $users[$i % $users.Count]
        $cmd = if (($i % 12) -eq 0) { "/usr/bin/systemctl status app-api" } elseif (($i % 17) -eq 0) { "/usr/bin/journalctl -u app-api -n 50" } else { "/usr/bin/less /var/log/syslog" }
        $lines.Add("$stamp server01 sudo: $user : TTY=pts/0 ; PWD=/home/$user ; USER=root ; COMMAND=$cmd")
    }

    $lines.Add("Mar 06 12:41:09 server01 sshd[9911]: Accepted password for root from 10.40.8.19 port 51244 ssh2")
    $lines.Add("Mar 06 12:41:11 server01 sudo: root : TTY=pts/1 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/tail -n 50 /var/log/auth.log")
    $lines.Add("Mar 06 12:41:13 server01 sudo: root : TTY=pts/1 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/truncate -s 0 /var/log/auth.log")
    $lines.Add("Mar 06 12:41:15 server01 sshd[9911]: pam_unix(sshd:session): session closed for user root")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RuleEngineMetrics {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,rule_name,host,event_rate_per_min,baseline_rate_per_min,deviation_pct,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T12:20:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4300; $i++) {
        $ts = $base.AddSeconds($i * 3).ToString("o")
        $eventRate = 80 + (($i * 2) % 70)
        $baseline = 92 + (($i * 2) % 40)
        $deviation = "{0:N2}" -f ((($eventRate - $baseline) / [double]$baseline) * 100.0)
        $status = if ([double]$deviation -lt -40) { "review" } else { "normal" }
        $lines.Add("$ts,linux_security_log_anomaly,server01,$eventRate,$baseline,$deviation,$status")
    }

    $lines.Add("2026-03-06T12:41:18Z,linux_security_log_anomaly,server01,2,118,-98.31,critical")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-13 Unusual SIEM Event Sequence (Real-World Investigation Pack)

Scenario:
A SIEM rule triggered after abrupt changes in host security-log behavior.
The evidence includes large SIEM alert streams, event timelines, auditd telemetry,
auth-log size monitoring, and privileged command/session logs.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4492
Severity: High
Queue: Security Monitoring + DFIR

Summary:
SIEM detected a sharp anomaly in auth-log event volume on server01.
Alert context indicates privileged shell activity immediately before log-size collapse.

Scope:
- Host: server01
- Log file: /var/log/auth.log
- Window: 2026-03-06 12:41 UTC

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Not all host alerts are malicious; expected maintenance and logrotate noise exists.
- Correlate SIEM timeline with auditd syscall/path events and auth-log-size telemetry.
- Focus on evidence of unauthorized log-content alteration.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$triage = @'
Triage starter notes:
1. Pivot on host=server01 and timestamp around 12:41:13Z.
2. Compare process activity against auth-log size drop.
3. Determine whether event reflects confidentiality, integrity, or availability impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\analysis\triage_notes.txt") -Content $triage

New-SiemAlertsStream -OutputPath (Join-Path $bundleRoot "evidence\siem\alerts_stream.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline.csv")
New-AuditdFullLog -OutputPath (Join-Path $bundleRoot "evidence\host\auditd_full.log")
New-AuthLogSizeSeries -OutputPath (Join-Path $bundleRoot "evidence\host\auth_log_size_timeseries.csv")
New-SudoAndSessionLog -OutputPath (Join-Path $bundleRoot "evidence\host\sudo_session.log")
New-RuleEngineMetrics -OutputPath (Join-Path $bundleRoot "evidence\siem\rule_engine_metrics.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
