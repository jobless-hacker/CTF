param()

$ErrorActionPreference = "Stop"

$bundleName = "m6-04-port-scan"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m6_04_realworld_build"
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

function New-FirewallLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $destPorts = @(80,443,22,8080,8443,3306)
    $sources = @("203.0.113.15","198.51.100.71","104.18.32.10","45.12.44.201")

    for ($i = 0; $i -lt 9400; $i++) {
        $ts = $base.AddMilliseconds($i * 600).ToString("o")
        $src = $sources[$i % $sources.Count]
        $dst = "10.30.0.$(10 + ($i % 30))"
        $port = $destPorts[$i % $destPorts.Count]
        $action = if (($i % 157) -eq 0) { "DROP_WITH_NOTE" } else { "DROP" }
        $lines.Add("$ts firewall=node-fw-02 action=$action src=$src dst=$dst proto=TCP dport=$port reason=default_deny")
    }

    $scanPorts = @(21,22,23,25,53,80,110,135,139,143,443,445,993,995,1433,1521,3306,3389,5432,5900,6379,8080)
    $frame = 9401
    foreach ($p in $scanPorts) {
        $ts = $base.AddHours(12).AddSeconds($frame - 9401).ToString("o")
        $lines.Add("$ts firewall=node-fw-02 action=DROP_WITH_ALERT src=185.199.110.42 dst=10.30.0.12 proto=TCP dport=$p reason=possible_scan")
        $frame++
    }
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ConnectionAttemptSummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,target_host,unique_ports,attempts,window_seconds,scan_score,node")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $sources = @("203.0.113.15","198.51.100.71","104.18.32.10","45.12.44.201")

    for ($i = 0; $i -lt 6900; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $src = $sources[$i % $sources.Count]
        $targetHost = "10.30.0.$(10 + ($i % 30))"
        $ports = 1 + ($i % 4)
        $attempts = 2 + ($i % 15)
        $scan = [Math]::Round(0.02 + (($i % 20) / 100.0), 2)
        $lines.Add("$ts,$src,$targetHost,$ports,$attempts,60,$scan,sensor-scan-01")
    }

    $lines.Add("2026-03-08T12:00:18Z,185.199.110.42,10.30.0.12,22,157,60,0.99,sensor-scan-01")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IdsAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $src = if (($i % 2) -eq 0) { "203.0.113.15" } else { "198.51.100.71" }
        $sig = if (($i % 211) -eq 0) { "ET POLICY Suspicious inbound connection attempt" } else { "ET INFO Session keepalive" }
        $sev = if (($i % 211) -eq 0) { 2 } else { 4 }
        $lines.Add("$ts ids=node-ids-01 src=$src dst=10.30.0.12 sig=`"$sig`" severity=$sev category=network")
    }

    $lines.Add("2026-03-08T12:00:20Z ids=node-ids-01 src=185.199.110.42 dst=10.30.0.12 sig=`"ET SCAN NMAP -sS Portscan`" severity=1 category=attempted-recon")
    $lines.Add("2026-03-08T12:00:21Z ids=node-ids-01 src=185.199.110.42 dst=10.30.0.12 sig=`"ET SCAN Multiple service probe sweep`" severity=1 category=attempted-recon")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NetworkFlow {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,dst_port,proto,packets,bytes,flow_state,node")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $sources = @("203.0.113.15","198.51.100.71","104.18.32.10","45.12.44.201")
    $ports = @(80,443,22,8080,3306)

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $src = $sources[$i % $sources.Count]
        $dst = "10.30.0.$(10 + ($i % 30))"
        $port = $ports[$i % $ports.Count]
        $pkts = 1 + ($i % 6)
        $bytes = 60 + (($i * 9) % 900)
        $state = if (($i % 3) -eq 0) { "SYN" } else { "RST" }
        $lines.Add("$ts,$src,$dst,$port,TCP,$pkts,$bytes,$state,flow-sensor-01")
    }

    $lines.Add("2026-03-08T12:00:19Z,185.199.110.42,10.30.0.12,22,TCP,1,74,SYN,flow-sensor-01")
    $lines.Add("2026-03-08T12:00:19Z,185.199.110.42,10.30.0.12,80,TCP,1,74,SYN,flow-sensor-01")
    $lines.Add("2026-03-08T12:00:19Z,185.199.110.42,10.30.0.12,443,TCP,1,74,SYN,flow-sensor-01")
    $lines.Add("2026-03-08T12:00:20Z,185.199.110.42,10.30.0.12,3306,TCP,1,74,SYN,flow-sensor-01")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PortScanAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("scan_baseline_watch","connection_rate_watch","recon_profile_watch","firewall_pattern_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "scan-" + ("{0:D8}" -f (99700000 + $i))
            severity = if (($i % 171) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine connection telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T12:00:20Z"
        alert_id = "scan-99941044"
        severity = "critical"
        type = "port_scan_detected"
        status = "open"
        detail = "single source probed many TCP services in short window"
        scanning_ip = "185.199.110.42"
        target = "10.30.0.12"
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
        $evt = if (($i % 227) -eq 0) { "scan_behavior_review" } else { "routine_perimeter_monitoring" }
        $sev = if ($evt -eq "scan_behavior_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-perimeter-01,$sev,perimeter telemetry baseline")
    }

    $lines.Add("2026-03-08T12:00:20Z,multi_port_probe_detected,siem-perimeter-01,critical,source 185.199.110.42 attempted many service ports")
    $lines.Add("2026-03-08T12:00:22Z,scan_source_confirmed,siem-perimeter-01,high,correlated IDS/firewall/flow to 185.199.110.42")
    $lines.Add("2026-03-08T12:00:30Z,incident_opened,siem-perimeter-01,high,INC-2026-5604 port scan investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Perimeter Reconnaissance Policy (Excerpt)

1) Multi-port probing from a single source in short windows is high-risk.
2) Analysts must identify and report scanning source IP.
3) Correlation across firewall, IDS, and flow telemetry is mandatory.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Port Scan Triage Runbook (Excerpt)

1) Review firewall drops for source-to-many-port pattern.
2) Confirm source with IDS scan signatures.
3) Validate rapid service probing in flow data and scan summary.
4) Submit scanning source IP and trigger perimeter block workflow.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M6-04 Port Scan (Real-World Investigation Pack)

Scenario:
Perimeter monitoring detected rapid multi-port probing against internal services.

Task:
Analyze the investigation pack and identify the scanning source IP.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5604
Severity: High
Queue: SOC + Network Security

Summary:
Firewall and IDS telemetry indicate reconnaissance traffic from one external source.

Scope:
- Target host: 10.30.0.12
- Window: 2026-03-08 12:00 UTC
- Goal: identify scanning source IP
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate firewall log, connection-attempt summary, IDS alerts, flow records, scan alerts, SIEM timeline, and policy/runbook guidance.
- Determine the scanning source IP.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-FirewallLog -OutputPath (Join-Path $bundleRoot "evidence\network\firewall.log")
New-ConnectionAttemptSummary -OutputPath (Join-Path $bundleRoot "evidence\network\connection_attempt_summary.csv")
New-IdsAlerts -OutputPath (Join-Path $bundleRoot "evidence\network\ids_alerts.log")
New-NetworkFlow -OutputPath (Join-Path $bundleRoot "evidence\network\flow_records.csv")
New-PortScanAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\port_scan_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\perimeter_recon_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\port_scan_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
