param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-20-dns-amplification-attack"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m1_20_realworld_build"
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

function New-ResolverQueryLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T06:00:00", [DateTimeKind]::Utc)
    $qtypes = @("A","AAAA","MX","TXT","SRV","NS")
    $zones = @("example.com","company.local","payments.company.com","cdn.partner.net","updates.vendor.io")

    for ($i = 0; $i -lt 11800; $i++) {
        $ts = $base.AddMilliseconds($i * 820).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $srcIp = if (($i % 4) -eq 0) { "10.44.8.$(20 + ($i % 150))" } else { "10.55.6.$(10 + ($i % 180))" }
        $qtype = $qtypes[$i % $qtypes.Count]
        $zone = $zones[$i % $zones.Count]
        $rcode = if (($i % 97) -eq 0) { "SERVFAIL" } else { "NOERROR" }
        $latency = 7 + (($i * 3) % 85)
        $bytes = 120 + (($i * 11) % 1300)
        $lines.Add("$ts resolver query src=$srcIp qname=$zone qtype=$qtype rcode=$rcode latency_ms=$latency resp_bytes=$bytes")
    }

    for ($j = 0; $j -lt 420; $j++) {
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-06T09:44:10", [DateTimeKind]::Utc).AddMilliseconds($j * 210).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $spoofedSrc = "198.51.100.$(10 + ($j % 40))"
        $lines.Add("$ts resolver query src=$spoofedSrc qname=ripe.net qtype=ANY rcode=NOERROR latency_ms=$((320 + ($j % 180))) resp_bytes=$((3800 + ($j % 1300))) note=amplification-pattern")
    }

    $lines.Add("2026-03-06T09:44:41.442Z resolver query src=203.0.113.77 qname=ripe.net qtype=ANY rcode=NOERROR latency_ms=511 resp_bytes=4096 note=amplification-pattern")
    $lines.Add("2026-03-06T09:44:42.018Z resolver query src=203.0.113.77 qname=ripe.net qtype=ANY rcode=NOERROR latency_ms=522 resp_bytes=4096 note=amplification-pattern")
    $lines.Add("2026-03-06T09:44:42.663Z resolver query src=203.0.113.77 qname=ripe.net qtype=ANY rcode=NOERROR latency_ms=544 resp_bytes=4096 note=amplification-pattern")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NetflowTelemetry {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,dst_port,proto,packets,bytes,direction,class")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T06:00:00", [DateTimeKind]::Utc)
    $resolverIp = "10.44.8.53"

    for ($i = 0; $i -lt 9200; $i++) {
        $ts = $base.AddMilliseconds($i * 640).ToString("o")
        $src = if (($i % 2) -eq 0) { "10.44.8.$(20 + ($i % 120))" } else { $resolverIp }
        $dst = if ($src -eq $resolverIp) { "10.55.6.$(10 + ($i % 160))" } else { $resolverIp }
        $direction = if ($src -eq $resolverIp) { "outbound" } else { "inbound" }
        $packets = 4 + ($i % 90)
        $bytes = 340 + (($i * 31) % 9800)
        $class = if (($i % 211) -eq 0) { "cache-miss-burst" } else { "normal-dns-flow" }
        $lines.Add("$ts,$src,$dst,53,udp,$packets,$bytes,$direction,$class")
    }

    for ($j = 0; $j -lt 380; $j++) {
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-06T09:44:12", [DateTimeKind]::Utc).AddMilliseconds($j * 220).ToString("o")
        $src = "203.0.113.$(40 + ($j % 60))"
        $packets = 240 + ($j % 180)
        $bytes = 98000 + (($j * 370) % 250000)
        $lines.Add("$ts,$src,$resolverIp,53,udp,$packets,$bytes,inbound,dns-amplification-suspected")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FirewallAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T06:00:00", [DateTimeKind]::Utc)
    $rules = @("DNS_RATE_LIMIT_WARN","DNS_ANOMALOUS_QTYPE","UDP_FLOOD_EARLY")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 6).ToString("o")
            device = "fw-edge-02"
            rule = $rules[$i % $rules.Count]
            severity = if (($i % 113) -eq 0) { "medium" } else { "low" }
            action = "allow"
            src_ip = "10.55.6.$(10 + ($i % 180))"
            dst_ip = "10.44.8.53"
            dst_port = 53
            note = if (($i % 113) -eq 0) { "short-lived spike, auto-recovered" } else { "baseline anomaly noise" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T09:44:16Z"
        device = "fw-edge-02"
        rule = "DNS_AMP_FLOOD_DETECTED"
        severity = "critical"
        action = "rate_limited"
        src_ip = "203.0.113.77"
        dst_ip = "10.44.8.53"
        dst_port = 53
        note = "high-rate ANY queries from distributed spoofed sources"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ResolverHealth {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,resolver,qps,success_rate,servfail_rate,p95_latency_ms,timeout_rate,cpu_pct,dropped_packets")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T06:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $qps = 380 + (($i * 5) % 410)
        $success = 99.7
        $servfail = 0.2
        $p95 = 22 + (($i * 2) % 20)
        $timeouts = 0.1
        $cpu = 28 + (($i * 3) % 38)
        $drop = 0
        if (($i % 190) -eq 0) {
            $servfail = 1.1
            $timeouts = 0.7
        }
        $lines.Add("$ts,dns-recursive-01,$qps,$success,$servfail,$p95,$timeouts,$cpu,$drop")
    }

    $lines.Add("2026-03-06T09:44:14Z,dns-recursive-01,24890,42.3,31.8,1840,28.4,99,22741")
    $lines.Add("2026-03-06T09:44:22Z,dns-recursive-01,27120,38.9,35.6,2012,31.2,100,25803")
    $lines.Add("2026-03-06T09:44:31Z,dns-recursive-01,28931,34.4,39.1,2333,36.7,100,29411")
    $lines.Add("2026-03-06T09:45:04Z,dns-recursive-01,30111,31.8,42.5,2604,40.2,100,33122")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ServiceProbes {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,probe_site,target,result,response_ms,error")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T06:00:00", [DateTimeKind]::Utc)
    $sites = @("hyd","mum","blr","del")

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddMilliseconds($i * 830).ToString("o")
        $site = $sites[$i % $sites.Count]
        $ms = 14 + (($i * 2) % 58)
        $result = "ok"
        $err = ""
        if (($i % 420) -eq 0) {
            $result = "degraded"
            $ms = 980
            $err = "high-latency"
        }
        $lines.Add("$ts,$site,dns-recursive-01,$result,$ms,$err")
    }

    $lines.Add("2026-03-06T09:44:15Z,hyd,dns-recursive-01,failed,10000,timeout")
    $lines.Add("2026-03-06T09:44:17Z,mum,dns-recursive-01,failed,10000,timeout")
    $lines.Add("2026-03-06T09:44:19Z,blr,dns-recursive-01,failed,10000,timeout")
    $lines.Add("2026-03-06T09:44:22Z,del,dns-recursive-01,failed,10000,timeout")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ChangeRecords {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("change_id,opened_utc,service,requested_by,approved_by,status,summary")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 1900; $i++) {
        $ts = $base.AddMinutes($i * 17).ToString("o")
        $svc = if (($i % 2) -eq 0) { "dns-recursive" } else { "edge-fw" }
        $lines.Add("CHG-$((73000 + $i)),$ts,$svc,netops,change-advisory,approved,routine ruleset and resolver maintenance")
    }

    $lines.Add("CHG-75121,2026-03-06T09:40:00Z,dns-recursive,netops,change-advisory,pending,proposed temporary any-query throttling")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-20 DNS Traffic Surge Investigation (Real-World Investigation Pack)

Scenario:
A recursive DNS service experienced a sudden high-volume surge consistent with amplification activity.
Evidence includes resolver query logs, DNS netflow telemetry, firewall alerts, resolver health metrics,
service probe outcomes, and operational change records.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4544
Severity: Critical
Queue: NetSec + SRE

Summary:
DNS resolver reliability dropped sharply during a traffic spike.
Initial indicators point to DNS amplification-style abuse against recursive service.

Scope:
- Service: dns-recursive-01
- Protocol: UDP/53
- Incident window: 2026-03-06 09:44 UTC onward

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate unusual query patterns (`ANY`, large response size) with flow amplification signals.
- Validate service degradation through health/availability metrics, not only traffic volume.
- Rule out planned maintenance as primary cause.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ResolverQueryLog -OutputPath (Join-Path $bundleRoot "evidence\dns\resolver_query.log")
New-NetflowTelemetry -OutputPath (Join-Path $bundleRoot "evidence\network\dns_netflow.csv")
New-FirewallAlerts -OutputPath (Join-Path $bundleRoot "evidence\network\firewall_alerts.jsonl")
New-ResolverHealth -OutputPath (Join-Path $bundleRoot "evidence\service\resolver_health_timeseries.csv")
New-ServiceProbes -OutputPath (Join-Path $bundleRoot "evidence\service\service_probes.csv")
New-ChangeRecords -OutputPath (Join-Path $bundleRoot "evidence\operations\change_records.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
