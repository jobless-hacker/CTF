param()

$ErrorActionPreference = "Stop"

$bundleName = "m6-01-suspicious-connection"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m6_01_realworld_build"
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

function New-TrafficCapture {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# pseudo packet capture export (tshark-style)")
    $lines.Add("# columns: frame,time_utc,src_ip,dst_ip,protocol,src_port,dst_port,flags,bytes,info")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $dsts = @("10.10.0.21","10.10.0.22","198.51.100.41","93.184.216.34")
    $protos = @("TCP","UDP")

    for ($i = 1; $i -le 9600; $i++) {
        $ts = $base.AddMilliseconds($i * 350).ToString("o")
        $src = "192.168.1.$(10 + ($i % 90))"
        $dst = $dsts[$i % $dsts.Count]
        $proto = $protos[$i % $protos.Count]
        $sport = 20000 + ($i % 30000)
        $dport = if ($proto -eq "TCP") { 443 } else { 53 }
        $flags = if ($proto -eq "TCP") { "ACK,PSH" } else { "-" }
        $bytes = 100 + (($i * 7) % 1400)
        $info = if ($proto -eq "TCP") { "TLS application data" } else { "DNS query/response" }
        $lines.Add("$i,$ts,$src,$dst,$proto,$sport,$dport,$flags,$bytes,$info")
    }

    $lines.Add("9601,2026-03-08T10:22:10.1000000Z,192.168.1.25,203.0.113.77,TCP,49612,443,SYN,74,TLS Client Hello")
    $lines.Add("9602,2026-03-08T10:22:10.1820000Z,192.168.1.25,203.0.113.77,TCP,49612,443,ACK,66,TLS session established")
    $lines.Add("9603,2026-03-08T10:22:11.0610000Z,192.168.1.25,203.0.113.77,TCP,49612,443,ACK,1298,TLS application data")
    $lines.Add("9604,2026-03-08T10:22:12.0240000Z,192.168.1.25,203.0.113.77,TCP,49612,443,ACK,1312,TLS application data")
    $lines.Add("9605,2026-03-08T10:22:13.4080000Z,192.168.1.25,203.0.113.77,TCP,49612,443,ACK,1188,TLS application data")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NetflowRecords {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,src_port,dst_port,proto,packets,bytes,flow_duration_ms,node")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $dsts = @("10.10.0.21","10.10.0.22","198.51.100.41","104.18.10.12")

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("o")
        $src = "192.168.1.$(12 + ($i % 80))"
        $dst = $dsts[$i % $dsts.Count]
        $sport = 30000 + ($i % 20000)
        $pkt = 6 + (($i * 2) % 200)
        $bytes = 800 + (($i * 73) % 90000)
        $dur = 40 + (($i * 13) % 30000)
        $lines.Add("$ts,$src,$dst,$sport,443,TCP,$pkt,$bytes,$dur,sensor-netflow-01")
    }

    $lines.Add("2026-03-08T10:22:10Z,192.168.1.25,203.0.113.77,49612,443,TCP,48,46217,18204,sensor-netflow-01")
    $lines.Add("2026-03-08T10:24:44Z,192.168.1.25,203.0.113.77,49654,443,TCP,52,50102,19441,sensor-netflow-01")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FirewallEgress {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $src = "192.168.1.$(20 + ($i % 70))"
        $dst = if (($i % 2) -eq 0) { "10.10.0.$(20 + ($i % 20))" } else { "198.51.100.$(30 + ($i % 70))" }
        $action = if (($i % 211) -eq 0) { "ALLOW_WITH_ALERT" } else { "ALLOW" }
        $lines.Add("$ts fw-egress node=fw-01 action=$action src=$src dst=$dst dport=443 proto=TCP policy=default-outbound")
    }

    $lines.Add("2026-03-08T10:22:10Z fw-egress node=fw-01 action=ALLOW_WITH_ALERT src=192.168.1.25 dst=203.0.113.77 dport=443 proto=TCP policy=default-outbound")
    $lines.Add("2026-03-08T10:24:44Z fw-egress node=fw-01 action=ALLOW_WITH_ALERT src=192.168.1.25 dst=203.0.113.77 dport=443 proto=TCP policy=default-outbound")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsTelemetry {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $domains = @("api.github.com","packages.ubuntu.com","pypi.org","repo.mysql.com","updates.internal.local")

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $src = "192.168.1.$(12 + ($i % 80))"
        $q = $domains[$i % $domains.Count]
        $rcode = if (($i % 197) -eq 0) { "SERVFAIL" } else { "NOERROR" }
        $lines.Add("$ts dns sensor=dns-01 src=$src qname=$q qtype=A rcode=$rcode")
    }

    $lines.Add("2026-03-08T10:22:09Z dns sensor=dns-01 src=192.168.1.25 qname=sync-gateway.security-checks.net qtype=A rcode=NOERROR")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NetworkAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("egress_baseline_watch","rare_external_ip_watch","host_behavior_profile","tls_pattern_monitor")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "net-" + ("{0:D8}" -f (99000000 + $i))
            severity = if (($i % 179) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine outbound traffic telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T10:22:10Z"
        alert_id = "net-99900811"
        severity = "critical"
        type = "suspicious_repeated_external_connection"
        status = "open"
        detail = "internal host repeatedly connected to unknown external endpoint"
        suspicious_external_ip = "203.0.113.77"
        source_host = "192.168.1.25"
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
        $evt = if (($i % 241) -eq 0) { "network_review" } else { "routine_egress_monitoring" }
        $sev = if ($evt -eq "network_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-net-01,$sev,network telemetry baseline")
    }

    $lines.Add("2026-03-08T10:22:10Z,unknown_external_tls_session,siem-net-01,critical,192.168.1.25 repeatedly contacted 203.0.113.77 over tcp/443")
    $lines.Add("2026-03-08T10:24:44Z,repeat_connection_pattern,siem-net-01,high,reconfirmed suspicious external endpoint 203.0.113.77")
    $lines.Add("2026-03-08T10:25:01Z,incident_opened,siem-net-01,high,INC-2026-5601 suspicious connection investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Outbound Connection Monitoring Policy (Excerpt)

1) Repeated traffic from internal hosts to unknown external IPs must be escalated.
2) Analysts must identify and report the suspicious external IP.
3) TLS sessions to unclassified endpoints require host isolation review.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Suspicious Connection Triage Runbook (Excerpt)

1) Inspect packet capture export for repeated src->dst patterns.
2) Correlate with netflow, firewall, and alert telemetry.
3) Validate suspicious endpoint in SIEM timeline.
4) Submit suspicious external IP and start containment.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M6-01 Suspicious Connection (Real-World Investigation Pack)

Scenario:
A network analyst observed repeated outbound sessions from an internal workstation to an unknown external endpoint.

Task:
Analyze the investigation pack and identify the suspicious external IP.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5601
Severity: High
Queue: SOC + Network Security

Summary:
Internal workstation activity indicates unusual repeated TLS sessions to an unknown external IP.

Scope:
- Source host: 192.168.1.25
- Window: 2026-03-08 10:22 UTC
- Goal: identify suspicious external IP
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate packet capture export, netflow records, firewall egress logs, DNS telemetry, network alerts, SIEM timeline, and policy/runbook guidance.
- Determine the suspicious external destination IP.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-TrafficCapture -OutputPath (Join-Path $bundleRoot "evidence\network\traffic.pcap")
New-NetflowRecords -OutputPath (Join-Path $bundleRoot "evidence\network\netflow_records.csv")
New-FirewallEgress -OutputPath (Join-Path $bundleRoot "evidence\network\firewall_egress.log")
New-DnsTelemetry -OutputPath (Join-Path $bundleRoot "evidence\network\dns_telemetry.log")
New-NetworkAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\network_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\outbound_connection_monitoring_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\suspicious_connection_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
