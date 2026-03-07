param()

$ErrorActionPreference = "Stop"

$bundleName = "m5-07-strange-process"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m5_07_realworld_build"
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

function New-ProcessInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,node,pid,user,process_name,cmdline,cpu_pct,mem_mb,start_time,risk_label")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $processes = @("sshd","nginx","python3","systemd","journald","rsyslogd","cron","node","java")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $node = "lin-prod-{0:D2}" -f (1 + ($i % 5))
        $procId = 1200 + ($i % 12000)
        $procName = $processes[$i % $processes.Count]
        $usr = if ($procName -eq "nginx") { "www-data" } elseif ($procName -eq "systemd") { "root" } else { "appsvc" }
        $cmd = if ($procName -eq "python3") { "/usr/bin/python3 /opt/app/worker.py --queue default" } else { "/usr/bin/$procName" }
        $cpu = [Math]::Round(1.2 + (($i * 3) % 37) / 10.0, 1)
        $mem = 16 + (($i * 5) % 512)
        $start = $base.AddSeconds(($i * 8) - 900).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $lines.Add("$ts,$node,$procId,$usr,$procName,""$cmd"",$cpu,$mem,$start,baseline")
    }

    $lines.Add("2026-03-08T06:25:30Z,lin-prod-03,8421,deploy,cryptominer,""/tmp/.cache/cryptominer --pool pool.example.invalid:4444 --wallet 45Af... --threads 8"",96.8,214,2026-03-08T06:24:59Z,critical")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PsAuxSnapshot {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND")

    for ($i = 0; $i -lt 7400; $i++) {
        $usr = if (($i % 9) -eq 0) { "root" } else { "appsvc" }
        $procId = 2200 + ($i % 24000)
        $cpu = [Math]::Round(0.1 + (($i * 2) % 41) / 10.0, 1)
        $mem = [Math]::Round(0.2 + (($i * 3) % 29) / 10.0, 1)
        $vsz = 15000 + (($i * 17) % 380000)
        $rss = 3000 + (($i * 11) % 220000)
        $stat = if (($i % 21) -eq 0) { "Ssl" } else { "Sl" }
        $cmd = if (($i % 15) -eq 0) { "/usr/bin/python3 /opt/app/api.py" } else { "/usr/sbin/sshd -D" }
        $lines.Add(("{0,-10} {1,5} {2,4} {3,4} {4,6} {5,5} ?        {6,-3} 06:1{7}   00:{8} {9}" -f $usr, $procId, $cpu, $mem, $vsz, $rss, $stat, ($i % 10), ($i % 60), $cmd))
    }

    $lines.Add("deploy     8421 96.8  8.1 488920 214312 ?     Rl   06:24   01:42 /tmp/.cache/cryptominer --pool pool.example.invalid:4444 --wallet 45Af... --threads 8")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CpuTimeseries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,node,cpu_total_pct,user_pct,system_pct,iowait_pct,top_process")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6300; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $cpu = [Math]::Round(18 + (($i * 2) % 45) + (($i % 7) / 10.0), 1)
        $userPct = [Math]::Round($cpu * 0.61, 1)
        $sysPct = [Math]::Round($cpu * 0.27, 1)
        $io = [Math]::Round($cpu * 0.05, 1)
        $top = if (($i % 13) -eq 0) { "python3" } else { "nginx" }
        $lines.Add("$ts,lin-prod-03,$cpu,$userPct,$sysPct,$io,$top")
    }

    $lines.Add("2026-03-08T06:25:30Z,lin-prod-03,98.4,91.2,5.1,0.3,cryptominer")
    $lines.Add("2026-03-08T06:25:39Z,lin-prod-03,99.1,92.4,5.4,0.2,cryptominer")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NetworkConnections {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $destinations = @("10.10.0.14:5432","10.10.0.8:6379","198.51.100.15:443","93.184.216.34:443")

    for ($i = 0; $i -lt 5700; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $procId = 2000 + ($i % 20000)
        $dest = $destinations[$i % $destinations.Count]
        $local = "10.62.3.$((20 + $i) % 230):$((30000 + $i) % 65000)"
        $state = if (($i % 5) -eq 0) { "ESTABLISHED" } else { "TIME_WAIT" }
        $lines.Add("$ts conntrack node=lin-prod-03 pid=$procId process=worker local=$local remote=$dest state=$state")
    }

    $lines.Add("2026-03-08T06:25:31Z conntrack node=lin-prod-03 pid=8421 process=cryptominer local=10.62.3.44:49532 remote=203.0.113.66:4444 state=ESTABLISHED")
    $lines.Add("2026-03-08T06:25:40Z conntrack node=lin-prod-03 pid=8421 process=cryptominer local=10.62.3.44:49533 remote=203.0.113.66:4444 state=ESTABLISHED")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProcessAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("cpu_spike_watch","process_baseline_drift","new_binary_execution","egress_anomaly_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "proc-" + ("{0:D8}" -f (93000000 + $i))
            severity = if (($i % 191) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine process telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T06:25:30Z"
        alert_id = "proc-99961270"
        severity = "critical"
        type = "suspected_crypto_mining_process"
        status = "open"
        detail = "unknown process consuming extreme CPU with mining-like network traffic"
        suspicious_process = "cryptominer"
        node = "lin-prod-03"
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
        $evt = if (($i % 271) -eq 0) { "process_review" } else { "routine_host_monitoring" }
        $sev = if ($evt -eq "process_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-host-01,$sev,host process telemetry baseline")
    }

    $lines.Add("2026-03-08T06:25:30Z,high_cpu_unknown_process,siem-host-01,critical,unknown process cryptominer dominates CPU on lin-prod-03")
    $lines.Add("2026-03-08T06:25:31Z,suspicious_egress_process,siem-host-01,high,cryptominer maintains outbound sessions on tcp/4444")
    $lines.Add("2026-03-08T06:25:42Z,incident_opened,siem-host-01,high,INC-2026-5507 strange process investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Linux Process Monitoring Policy (Excerpt)

1) Unknown high-CPU processes must be investigated immediately.
2) Processes with persistent outbound sessions to suspicious ports require escalation.
3) SOC must identify exact suspicious process name during triage.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Strange Process Triage Runbook (Excerpt)

1) Validate process identity using ps snapshots and process inventory.
2) Correlate CPU saturation metrics with top process records.
3) Correlate suspicious process with network connections and alerts.
4) Isolate host and terminate malicious process after evidence capture.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M5-07 Strange Process (Real-World Investigation Pack)

Scenario:
SOC monitoring detected an unknown process consuming excessive CPU and maintaining suspicious outbound connections.

Task:
Analyze the investigation pack and identify the suspicious process.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5507
Severity: High
Queue: SOC + DFIR + Linux Ops

Summary:
A production Linux node shows sustained CPU exhaustion linked to an unrecognized process and unusual network behavior.

Scope:
- Node: lin-prod-03
- Window: 2026-03-08 06:25 UTC
- Goal: identify suspicious process name
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate process inventory, ps snapshots, CPU timeline, network connection logs, process alerts, SIEM timeline, and policy/runbook guidance.
- Determine the suspicious process name.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ProcessInventory -OutputPath (Join-Path $bundleRoot "evidence\process\process_inventory.csv")
New-PsAuxSnapshot -OutputPath (Join-Path $bundleRoot "evidence\process\ps_aux_snapshot.txt")
New-CpuTimeseries -OutputPath (Join-Path $bundleRoot "evidence\host\cpu_usage_timeseries.csv")
New-NetworkConnections -OutputPath (Join-Path $bundleRoot "evidence\network\network_connections.log")
New-ProcessAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\process_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\linux_process_monitoring_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\strange_process_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
