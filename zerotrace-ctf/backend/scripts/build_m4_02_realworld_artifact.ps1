param()

$ErrorActionPreference = "Stop"

$bundleName = "m4-02-traffic-flood"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m4_02_realworld_build"
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

function New-FirewallEventLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 9800; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $src = "10.$(20 + ($i % 50)).$((40 + $i) % 220).$((11 + $i) % 230)"
        $dst = "172.16.$(10 + ($i % 10)).$((20 + $i) % 200)"
        $proto = if (($i % 4) -eq 0) { "TCP" } elseif (($i % 4) -eq 1) { "UDP" } elseif (($i % 4) -eq 2) { "TLS" } else { "ICMP" }
        $act = if (($i % 93) -eq 0) { "drop" } else { "allow" }
        $pps = 20 + (($i * 9) % 1400)
        $lines.Add("$ts firewall=fw-edge-01 action=$act src_ip=$src dst_ip=$dst proto=$proto packets_per_sec=$pps note=baseline_traffic")
    }

    $lines.Add("2026-03-07T18:11:03.000Z firewall=fw-edge-01 action=drop src_ip=185.199.110.42 dst_ip=172.16.10.20 proto=TCP packets_per_sec=42000 note=Inbound requests/sec: 42000")
    $lines.Add("2026-03-07T18:11:04.000Z firewall=fw-edge-01 action=drop src_ip=198.51.100.23 dst_ip=172.16.10.20 proto=TCP packets_per_sec=43800 note=Traffic source: multiple IP addresses")
    $lines.Add("2026-03-07T18:11:05.000Z firewall=fw-edge-01 action=drop src_ip=203.0.113.77 dst_ip=172.16.10.20 proto=TCP packets_per_sec=44210 note=Service unreachable under volumetric flood")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EdgeRateTimeseries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,requests_per_sec,packets_per_sec,unique_source_ips,drop_rate_pct")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 8600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $rps = 50 + (($i * 4) % 2300)
        $pps = 80 + (($i * 6) % 3500)
        $uniq = 10 + ($i % 95)
        $drop = [Math]::Round((($i % 15) / 10.0), 1)
        $lines.Add("$ts,$rps,$pps,$uniq,$drop")
    }

    $lines.Add("2026-03-07T18:11:03Z,28500,42000,3862,92.4")
    $lines.Add("2026-03-07T18:11:04Z,29820,43800,3950,93.1")
    $lines.Add("2026-03-07T18:11:05Z,30210,44210,4012,93.9")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NetflowSummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_asn,src_ip,dst_service,proto,dst_port,flows,bytes,packets,tcp_flags")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ports = @(80,443,8080,8443,53)

    for ($i = 0; $i -lt 7400; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $asn = 64000 + ($i % 90)
        $src = "10.$(50 + ($i % 100)).$((20 + $i) % 220).$((70 + $i) % 230)"
        $port = $ports[$i % $ports.Count]
        $proto = if (($i % 2) -eq 0) { "TCP" } else { "UDP" }
        $flows = 1 + ($i % 120)
        $bytes = 300 + (($i * 29) % 900000)
        $pkts = 3 + (($i * 31) % 1600)
        $flags = if ($proto -eq "TCP") { "SYN,ACK" } else { "-" }
        $lines.Add("$ts,$asn,$src,web-edge,$proto,$port,$flows,$bytes,$pkts,$flags")
    }

    $lines.Add("2026-03-07T18:11:03Z,64512,185.199.110.42,web-edge,TCP,443,9800,88122000,420000,SYN")
    $lines.Add("2026-03-07T18:11:03Z,64513,198.51.100.23,web-edge,TCP,443,10040,90211900,435800,SYN")
    $lines.Add("2026-03-07T18:11:03Z,64514,203.0.113.77,web-edge,TCP,443,10220,91552000,442100,SYN")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IdsAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("scanner_probe","anomalous_tls_handshake","http_header_anomaly","udp_spike")

    for ($i = 0; $i -lt 4500; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            sensor = "ids-edge-01"
            severity = if (($i % 157) -eq 0) { "medium" } else { "low" }
            alert_type = $types[$i % $types.Count]
            src_ip = "10.$(90 + ($i % 50)).$((30 + $i) % 220).$((50 + $i) % 230)"
            dst_service = "web-edge"
            action = "logged"
            status = "closed_noise"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T18:11:04Z"
        sensor = "ids-edge-01"
        severity = "critical"
        alert_type = "distributed_syn_flood"
        src_ip = "multiple"
        dst_service = "web-edge"
        action = "mitigate"
        status = "open"
        attack_class = "ddos"
        details = "high-volume distributed SYN flood from thousands of sources"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LbServiceHealth {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,lb_node,target,status,http_code,connection_attempts,failed_connections,notes")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $targets = @("web-a","web-b","web-c")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $node = "lb-" + (1 + ($i % 2))
        $target = $targets[$i % $targets.Count]
        $status = if (($i % 139) -eq 0) { "degraded" } else { "healthy" }
        $code = if ($status -eq "degraded") { 502 } else { 200 }
        $attempts = 50 + (($i * 4) % 2400)
        $failed = if ($status -eq "degraded") { 12 + ($i % 30) } else { 0 + ($i % 2) }
        $note = if ($status -eq "degraded") { "transient issue" } else { "ok" }
        $lines.Add("$ts,$node,$target,$status,$code,$attempts,$failed,$note")
    }

    $lines.Add("2026-03-07T18:11:04Z,lb-1,web-a,unhealthy,503,15400,14920,flood pressure - service unreachable")
    $lines.Add("2026-03-07T18:11:05Z,lb-2,web-b,unhealthy,503,15110,14602,flood pressure - service unreachable")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $evt = if (($i % 283) -eq 0) { "traffic_review" } else { "routine_edge_monitoring" }
        $sev = if ($evt -eq "traffic_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-edge-01,$sev,baseline traffic monitoring")
    }

    $lines.Add("2026-03-07T18:11:03Z,traffic_flood_detected,siem-edge-01,critical,inbound requests exceeded 42k/sec from distributed sources")
    $lines.Add("2026-03-07T18:11:04Z,service_unreachable,siem-edge-01,high,edge and lb report 503 during flood")
    $lines.Add("2026-03-07T18:11:08Z,attack_classified,siem-edge-01,high,classified as ddos attack")
    $lines.Add("2026-03-07T18:11:15Z,incident_opened,siem-edge-01,high,INC-2026-5312 traffic flood investigation")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-MitigationNotes {
    param([string]$OutputPath)

    $content = @'
Edge Mitigation Notes

- Temporary SYN rate-limit enabled at firewall and edge proxy.
- Source distribution exceeds blocklist capacity (thousands of IPs).
- Pattern aligns with volumetric distributed denial-of-service activity.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Network Availability Runbook (Excerpt)

1) Validate if spike is single-source or distributed.
2) Correlate edge firewall, netflow, IDS, and load balancer impact.
3) If service becomes unreachable under distributed volumetric flood, classify as DDoS.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M4-02 Traffic Flood (Real-World Investigation Pack)

Scenario:
The edge network experienced an intense traffic surge, and customer requests began failing.

Task:
Analyze the investigation pack and identify the attack type.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5312
Severity: High
Queue: SOC + NOC + SRE

Summary:
Edge firewall and load balancer reported abrupt request surge with service disruption.

Scope:
- Window: 2026-03-07 18:11 UTC
- Focus: classify the attack type accurately
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate firewall events, edge rate series, netflow summaries, IDS alerts, LB health, mitigation notes, runbook, and SIEM timeline.
- Determine the attack type causing outage.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-FirewallEventLog -OutputPath (Join-Path $bundleRoot "evidence\firewall\firewall_event.log")
New-EdgeRateTimeseries -OutputPath (Join-Path $bundleRoot "evidence\edge\edge_rate_timeseries.csv")
New-NetflowSummary -OutputPath (Join-Path $bundleRoot "evidence\network\netflow_summary.csv")
New-IdsAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\ids_alerts.jsonl")
New-LbServiceHealth -OutputPath (Join-Path $bundleRoot "evidence\loadbalancer\lb_service_health.csv")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-MitigationNotes -OutputPath (Join-Path $bundleRoot "evidence\ops\mitigation_notes.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\network_availability_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
