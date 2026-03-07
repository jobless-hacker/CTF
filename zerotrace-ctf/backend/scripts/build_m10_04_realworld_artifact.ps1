param()

$ErrorActionPreference = "Stop"

$bundleName = "m10-04-timeline-event"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m10_04_realworld_build"
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

function New-TimelineLog {
    param([string]$OutputPath)

    $content = @'
10:02 user login
10:04 file accessed
10:05 admin password changed
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-SessionTimelineCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,session_id,user,event_type,source_host,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("alex","john","maria","svc-backup","ops-bot","admin")
    $events = @("login","file_open","file_close","dashboard_view","token_refresh","logout")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $sid = "SESS-" + ("{0:D9}" -f (500000000 + $i))
        $user = $users[$i % $users.Count]
        $evt = $events[$i % $events.Count]
        $srcHost = "endpoint-" + ("{0:D3}" -f (($i % 95) + 1))
        $sev = if (($i % 193) -eq 0) { "medium" } else { "low" }
        $details = if ($sev -eq "medium") { "out_of_pattern_timing" } else { "normal_activity" }
        $lines.Add("$ts,$sid,$user,$evt,$srcHost,$sev,$details")
    }

    $lines.Add("2026-03-08T01:45:10Z,SESS-599999901,admin,admin_password_changed,endpoint-007,high,action=password_changed initiated_via_admin_portal")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthEventsLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("10.8.21.10","10.8.21.11","10.8.21.12","10.8.21.13","10.8.21.14")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $user = if (($i % 14) -eq 0) { "admin" } else { "user" + ($i % 120) }
        $ip = $ips[$i % $ips.Count]
        $result = if (($i % 177) -eq 0) { "failed" } else { "success" }
        $lines.Add("$ts auth_event user=$user src_ip=$ip method=portal result=$result")
    }

    $lines.Add("2026-03-08T01:45:12Z auth_event user=admin src_ip=10.8.21.13 method=portal result=success action=password_changed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ChangeAuditJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            change_id = "CHG-" + ("{0:D10}" -f (9400000000 + $i))
            actor = if (($i % 29) -eq 0) { "ops-bot" } else { "user" + ($i % 85) }
            system = "identity-core"
            target = "account-" + ("{0:D5}" -f (($i % 9200) + 1))
            action = if (($i % 241) -eq 0) { "role_update" } else { "profile_update" }
            status = "applied"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T01:45:14Z"
        change_id = "CHG-9999999910"
        actor = "admin"
        system = "identity-core"
        target = "account-admin"
        action = "password_changed"
        status = "applied"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ShellAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $cmds = @("ls -la","cat /etc/issue","df -h","top -bn1","journalctl -n 20","id")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $srcHost = "srv-" + ("{0:D3}" -f (($i % 55) + 1))
        $user = if (($i % 19) -eq 0) { "admin" } else { "ops" + ($i % 40) }
        $cmd = $cmds[$i % $cmds.Count]
        $lines.Add("$ts host=$srcHost user=$user tty=pts/$($i % 7) cmd=`"$cmd`"")
    }

    $lines.Add("2026-03-08T01:45:16Z host=srv-007 user=admin tty=pts/3 cmd=`"passwd admin`" normalized_action=password_changed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEventsCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 257) -eq 0) { "timeline-anomaly-check" } else { "forensics-pipeline-heartbeat" }
        $sev = if ($evt -eq "timeline-anomaly-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,dfir-timeline-siem-01,$sev,forensic timeline aggregation running")
    }

    $lines.Add("2026-03-08T01:45:18Z,suspicious_action_confirmed,dfir-timeline-siem-01,high,action=password_changed confidence=0.99")
    $lines.Add("2026-03-08T01:45:24Z,ctf_answer_ready,dfir-timeline-siem-01,high,submit password_changed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelinePreview {
    param([string]$OutputPath)

    $content = @'
Timeline Preview:
10:02 user login
10:04 file accessed
10:05 admin password changed
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
Forensics Case Notes (Extract)

Objective:
Identify the suspicious action in the reconstructed timeline.

Validation rule:
Correlate session timeline, auth events, change audit, shell audit, and SIEM confirmation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Intel Snapshot

Observed privileged account manipulation in identity workflows.
Likely suspicious action token: password_changed
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M10-04 Timeline Event (Real-World Investigation Pack)

Scenario:
A reconstructed activity timeline contains a suspicious administrative action.

Task:
Analyze the evidence pack and identify the suspicious action.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-6004
Severity: Medium
Queue: DFIR

Summary:
Investigate timeline reconstruction outputs and identify suspicious action.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate session timeline, auth logs, change audit records,
  shell audit traces, SIEM events, and intel summary.
- Determine suspicious action token for flag submission.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-TimelineLog -OutputPath (Join-Path $bundleRoot "evidence\timeline.log")
New-TimelinePreview -OutputPath (Join-Path $bundleRoot "evidence\forensics\timeline_preview.txt")
New-SessionTimelineCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\session_timeline.csv")
New-AuthEventsLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\auth_events.log")
New-ChangeAuditJsonl -OutputPath (Join-Path $bundleRoot "evidence\forensics\change_audit.jsonl")
New-ShellAuditLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\shell_audit.log")
New-TimelineEventsCsv -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CaseNotes -OutputPath (Join-Path $bundleRoot "evidence\forensics\case_notes.txt")
New-IntelSnapshot -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
