param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-09-firewall-ddos-alert"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_09_realworld_build"
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

function New-FirewallLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T10:55:00", [DateTimeKind]::Utc)
    $target = "203.0.113.40"

    $incidentStart = [datetime]::SpecifyKind([datetime]"2026-03-06T11:16:12", [DateTimeKind]::Utc)
    $incidentEnd = [datetime]::SpecifyKind([datetime]"2026-03-06T11:18:40", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 15400; $i++) {
        $ts = $base.AddMilliseconds($i * 280)
        $stamp = $ts.ToString("o")
        $src = "$((61 + ($i % 130))).$((11 + ($i % 220))).$((3 + ($i % 240))).$((2 + ($i % 250)))"
        $action = "allow"
        $sev = "notice"
        $cps = 320 + (($i * 17) % 2200)
        $synRatio = "{0:N2}" -f (0.42 + (($i % 15) / 50.0))
        $bps = 1200000 + (($i * 1400) % 6400000)
        $note = "normal-edge-traffic"

        # benign burst from internal load test range
        if (($i % 701) -eq 0) {
            $src = "10.250.20.$(10 + ($i % 40))"
            $cps = 5200
            $synRatio = "0.51"
            $bps = 12500000
            $note = "scheduled-load-test"
        }

        if ($ts -ge $incidentStart -and $ts -le $incidentEnd) {
            $action = if (($i % 4) -eq 0) { "drop" } else { "rate-limit" }
            $sev = "alert"
            $cps = 25000 + (($i * 37) % 18000)
            $synRatio = "{0:N2}" -f (0.90 + (($i % 8) / 100.0))
            $bps = 60000000 + (($i * 3000) % 140000000)
            $note = "syn-heavy-distributed-burst"
        }

        $lines.Add("$stamp edge-fw-01 $sev src=$src dst=$target dport=443 proto=tcp action=$action conn_per_sec=$cps syn_ratio=$synRatio bytes_per_sec=$bps note=$note")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NetflowTimeseries {
    param(
        [string]$SummaryPath,
        [string]$DetailedPath
    )

    $summary = New-Object System.Collections.Generic.List[string]
    $summary.Add("NetFlow Summary")
    $summary.Add("")
    $summary.Add("Destination: 203.0.113.40:443")
    $summary.Add("Peak new TCP sessions/sec: 41,882")
    $summary.Add("Unique source IPs in 60s window: 7,214")
    $summary.Add("Dominant pattern in incident window: SYN-heavy distributed short-lived flows")
    $summary.Add("Benign noise observed: scheduled internal load test from 10.250.20.0/24")
    Write-LinesFile -Path $SummaryPath -Lines $summary

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,dst_ip,dst_port,new_tcp_sessions_per_sec,unique_src_ip,syn_packets,ack_packets,udp_packets,avg_flow_duration_ms")

    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:05:00", [DateTimeKind]::Utc)
    $incidentStart = [datetime]::SpecifyKind([datetime]"2026-03-06T11:16:12", [DateTimeKind]::Utc)
    $incidentEnd = [datetime]::SpecifyKind([datetime]"2026-03-06T11:18:40", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 9100; $i++) {
        $tsObj = $base.AddMilliseconds($i * 300)
        $ts = $tsObj.ToString("o")
        $sessions = 450 + (($i * 11) % 1800)
        $uniq = 120 + (($i * 3) % 440)
        $syn = 900 + (($i * 17) % 6000)
        $ack = 830 + (($i * 15) % 5600)
        $udp = 120 + (($i * 7) % 1000)
        $dur = 140 + (($i * 5) % 260)

        if (($i % 809) -eq 0) {
            # benign internal load test has balanced SYN/ACK and longer durations
            $sessions = 5600
            $uniq = 34
            $syn = 6400
            $ack = 6200
            $udp = 60
            $dur = 890
        }

        if ($tsObj -ge $incidentStart -and $tsObj -le $incidentEnd) {
            $sessions = 26000 + (($i * 29) % 17000)
            $uniq = 3800 + (($i * 7) % 4200)
            $syn = 85000 + (($i * 31) % 120000)
            $ack = 4500 + (($i * 9) % 7200)
            $udp = 400 + (($i * 4) % 1300)
            $dur = 45 + (($i * 3) % 70)
        }

        $lines.Add("$ts,203.0.113.40,443,$sessions,$uniq,$syn,$ack,$udp,$dur")
    }

    Write-LinesFile -Path $DetailedPath -Lines $lines
}

function New-LbHealthAndUptime {
    param(
        [string]$LbPath,
        [string]$UptimePath
    )

    $lb = New-Object System.Collections.Generic.List[string]
    $lb.Add("timestamp_utc,service,healthy_backend_pct,request_rate_per_sec,http_5xx_pct,p95_latency_ms")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:05:00", [DateTimeKind]::Utc)
    $incidentStart = [datetime]::SpecifyKind([datetime]"2026-03-06T11:16:15", [DateTimeKind]::Utc)
    $incidentEnd = [datetime]::SpecifyKind([datetime]"2026-03-06T11:18:50", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6200; $i++) {
        $tsObj = $base.AddMilliseconds($i * 450)
        $ts = $tsObj.ToString("o")
        $healthy = 100
        $rps = 420 + (($i * 5) % 900)
        $err = "{0:N2}" -f (0.10 + (($i % 7) / 100.0))
        $p95 = 120 + (($i * 2) % 180)

        if ($tsObj -ge $incidentStart -and $tsObj -le $incidentEnd) {
            $healthy = [Math]::Max(0, 18 - (($i % 20)))
            $rps = 90 + (($i * 3) % 260)
            $err = "{0:N2}" -f (31.0 + (($i % 17) / 2.5))
            $p95 = 2800 + (($i * 7) % 1600)
        }

        $lb.Add("$ts,customer-portal,$healthy,$rps,$err,$p95")
    }
    Write-LinesFile -Path $LbPath -Lines $lb

    $up = New-Object System.Collections.Generic.List[string]
    $up.Add("timestamp_utc,probe_region,http_status,response_time_ms,result")
    $probeBase = [datetime]::SpecifyKind([datetime]"2026-03-06T11:10:00", [DateTimeKind]::Utc)
    $regions = @("hyd","mum","blr","del")

    for ($i = 0; $i -lt 3500; $i++) {
        $tsObj = $probeBase.AddMilliseconds($i * 700)
        $ts = $tsObj.ToString("o")
        $region = $regions[$i % $regions.Count]
        $status = 200
        $resp = 320 + (($i * 4) % 220)
        $res = "ok"

        if ($tsObj -ge [datetime]::SpecifyKind([datetime]"2026-03-06T11:16:20", [DateTimeKind]::Utc) -and
            $tsObj -le [datetime]::SpecifyKind([datetime]"2026-03-06T11:18:45", [DateTimeKind]::Utc)) {
            if (($i % 3) -eq 0) {
                $status = 503
                $resp = 4200 + (($i * 3) % 2500)
                $res = "degraded"
            } else {
                $status = 0
                $resp = 10000
                $res = "timeout"
            }
        }

        $up.Add("$ts,$region,$status,$resp,$res")
    }
    Write-LinesFile -Path $UptimePath -Lines $up
}

function New-TopTalkers {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("rank,src_ip,country,peak_conn_per_sec,total_bytes,blocked_pct,profile")

    for ($i = 1; $i -le 220; $i++) {
        $ip = "$((40 + ($i % 170))).$((20 + ($i % 200))).$((10 + ($i % 230))).$((5 + ($i % 240)))"
        $country = @("US","DE","NL","RU","SG","BR","IN","VN","UA","FR")[$i % 10]
        $peak = 900 + (($i * 87) % 42000)
        $bytes = 12000000 + (($i * 200000) % 920000000)
        $blocked = "{0:N2}" -f (12 + (($i % 57) / 1.5))
        $profile = if ($i -le 20) { "burst-syn-heavy" } else { "background-noise" }
        $lines.Add("$i,$ip,$country,$peak,$bytes,$blocked,$profile")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WafAndSiem {
    param(
        [string]$WafPath,
        [string]$SiemPath
    )

    $waf = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:08:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddMilliseconds($i * 500).ToString("o")
        $rule = if (($i % 13) -eq 0) { "SQLI_PATTERN" } else { "BOT_SCORE" }
        $action = if ($rule -eq "SQLI_PATTERN") { "block" } else { "allow" }
        $entry = [ordered]@{
            timestamp = $ts
            waf = "edge-waf-01"
            src_ip = "$((73 + ($i % 120))).$((12 + ($i % 200))).$((9 + ($i % 220))).$((2 + ($i % 250)))"
            path = if (($i % 4) -eq 0) { "/login" } else { "/api/profile" }
            rule = $rule
            action = $action
            score = 20 + ($i % 80)
            note = if ($rule -eq "SQLI_PATTERN") { "likely automated probe" } else { "generic automated traffic" }
        }
        $waf.Add(($entry | ConvertTo-Json -Depth 6 -Compress))
    }
    Write-LinesFile -Path $WafPath -Lines $waf

    $siem = New-Object System.Collections.Generic.List[string]
    $siem.Add("timestamp_utc,source,event_type,severity,asset,status,note")
    $siemBase = [datetime]::SpecifyKind([datetime]"2026-03-06T11:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6900; $i++) {
        $ts = $siemBase.AddSeconds($i * 5).ToString("o")
        $etype = if (($i % 17) -eq 0) { "waf_probe_cluster" } else { "normal_edge_health" }
        $sev = if ($etype -eq "waf_probe_cluster") { 28 } else { 6 }
        $status = if ($etype -eq "waf_probe_cluster") { "closed_false_positive" } else { "informational" }
        $note = if ($etype -eq "waf_probe_cluster") { "common internet scanning baseline" } else { "steady-state traffic" }
        $siem.Add("$ts,siem,$etype,$sev,customer-portal,$status,$note")
    }

    $siem.Add("2026-03-06T11:16:18Z,siem,ddos_l3_l4_surge_detected,95,203.0.113.40,open,connection surge above threshold with high SYN ratio")
    $siem.Add("2026-03-06T11:16:35Z,siem,service_availability_degraded,93,customer-portal,open,health checks failing and timeout rate increasing")
    $siem.Add("2026-03-06T11:17:10Z,siem,distributed_source_amplification,91,edge-fw-01,open,source diversity spike indicates distributed attack")

    Write-LinesFile -Path $SiemPath -Lines $siem
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-09 Firewall DDoS Alert (Real-World Investigation Pack)

Scenario:
The perimeter firewall reported a major inbound surge against the customer portal.
Shortly after, load balancer health dropped and external uptime monitors showed 503/timeouts.
Evidence includes firewall telemetry, NetFlow timeseries, top talkers, WAF events,
service health data, and SIEM-normalized alerts.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4461
Severity: Critical
Queue: Network Defense + SRE

Summary:
Edge firewall triggered high-volume inbound surge alerts on portal VIP 203.0.113.40:443.
Service health degraded across regions during the same window.
Initial containment included rate limiting and temporary upstream filtering.

Scope:
- Target: 203.0.113.40:443 (customer-portal)
- Suspected window: 2026-03-06 11:16 UTC to 11:19 UTC

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Internet-facing services receive constant scanner noise; not all alerts indicate outage.
- Correlate firewall surge metrics with NetFlow SYN/ACK imbalance and uptime failures.
- Use top talkers and source diversity context to separate load-test traffic from attack traffic.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$mitigation = @'
Mitigation notes:
1. Enabled edge firewall rate-limiting profile at 11:16:20Z.
2. Activated temporary upstream traffic scrubbing at 11:18:05Z.
3. Relaxed controls after traffic normalized and health checks recovered.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\response\mitigation_actions.txt") -Content $mitigation

New-FirewallLog -OutputPath (Join-Path $bundleRoot "evidence\firewall\edge_firewall.log")
New-NetflowTimeseries -SummaryPath (Join-Path $bundleRoot "evidence\network\netflow_summary.txt") -DetailedPath (Join-Path $bundleRoot "evidence\network\netflow_timeseries.csv")
New-LbHealthAndUptime -LbPath (Join-Path $bundleRoot "evidence\service\load_balancer_health.csv") -UptimePath (Join-Path $bundleRoot "evidence\service\uptime_monitor.csv")
New-TopTalkers -OutputPath (Join-Path $bundleRoot "evidence\firewall\top_talkers.csv")
New-WafAndSiem -WafPath (Join-Path $bundleRoot "evidence\network\waf_events.jsonl") -SiemPath (Join-Path $bundleRoot "evidence\siem\normalized_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
