param()

$ErrorActionPreference = "Stop"

$bundleName = "m6-06-c2-communication"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m6_06_realworld_build"
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
    $lines.Add("# pseudo-pcap export")
    $lines.Add("# columns: frame,time_utc,src_ip,dst_ip,proto,dst_port,bytes,summary")

    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcIps = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.90")
    $dstIps = @("142.250.183.14","104.18.30.99","52.96.34.11","172.67.33.20")
    $ports = @(80,443)

    for ($i = 0; $i -lt 9800; $i++) {
        $frame = 500000 + $i
        $ts = $base.AddMilliseconds($i * 250).ToString("o")
        $src = $srcIps[$i % $srcIps.Count]
        $dst = $dstIps[$i % $dstIps.Count]
        $port = $ports[$i % $ports.Count]
        $bytes = 68 + (($i * 17) % 1300)
        $summary = if (($i % 133) -eq 0) { "TLS application data" } else { "normal web traffic" }
        $lines.Add("$frame,$ts,$src,$dst,TCP,$port,$bytes,$summary")
    }

    # C2 beacon from infected host with periodic heartbeat
    for ($j = 0; $j -lt 42; $j++) {
        $frame = 700000 + $j
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-08T10:00:00", [DateTimeKind]::Utc).AddSeconds($j * 60).ToString("o")
        $lines.Add("$frame,$ts,192.168.1.90,198.51.100.44,TCP,443,214,beacon heartbeat interval=60s")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $clients = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.90")
    $domains = @("cdn.office365.net","api.github.com","updates.windows.com","fonts.gstatic.com")

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $src = $clients[$i % $clients.Count]
        $domain = $domains[$i % $domains.Count]
        $lines.Add("$ts dns=node-dns-02 src=$src query=$domain type=A rcode=NOERROR")
    }

    $lines.Add("2026-03-08T09:59:59Z dns=node-dns-02 src=192.168.1.90 query=telemetry-sync.evilcontrol.net type=A rcode=NOERROR answer=198.51.100.44")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FlowRecords {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,dst_port,proto,packets,bytes,flow_tag,device")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcs = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.90")
    $dsts = @("142.250.183.14","104.18.30.99","52.96.34.11","172.67.33.20")
    $ports = @(80,443)

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $src = $srcs[$i % $srcs.Count]
        $dst = $dsts[$i % $dsts.Count]
        $port = $ports[$i % $ports.Count]
        $pkts = 2 + ($i % 14)
        $bytes = 120 + (($i * 31) % 15000)
        $tag = if (($i % 201) -eq 0) { "periodic-check" } else { "routine-web" }
        $lines.Add("$ts,$src,$dst,$port,TCP,$pkts,$bytes,$tag,flow-sensor-03")
    }

    for ($j = 0; $j -lt 42; $j++) {
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-08T10:00:00", [DateTimeKind]::Utc).AddSeconds($j * 60).ToString("o")
        $lines.Add("$ts,192.168.1.90,198.51.100.44,443,TCP,5,2140,c2-beacon,flow-sensor-03")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EndpointNetstat {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,hostname,user,process,pid,src_ip,dst_ip,dst_port,state,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hosts = @("WS-101","WS-104","WS-121","WS-190")
    $users = @("alice","bob","charlie","dev01")
    $procs = @("chrome.exe","teams.exe","onedrive.exe","python.exe")
    $dsts = @("142.250.183.14","104.18.30.99","52.96.34.11")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $endpointName = $hosts[$i % $hosts.Count]
        $user = $users[$i % $users.Count]
        $proc = $procs[$i % $procs.Count]
        $procId = 2000 + ($i % 5000)
        $src = "192.168.1." + (10 + ($i % 90))
        $dst = $dsts[$i % $dsts.Count]
        $lines.Add("$ts,$endpointName,$user,$proc,$procId,$src,$dst,443,ESTABLISHED,baseline")
    }

    $lines.Add("2026-03-08T10:00:00Z,WS-190,dev01,updater_service.exe,4884,192.168.1.90,198.51.100.44,443,ESTABLISHED,periodic outbound beacon")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-C2Alerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("periodic-traffic-watch","anomaly-score-watch","egress-pattern-watch","tls-frequency-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "c2-" + ("{0:D8}" -f (92200000 + $i))
            severity = if (($i % 177) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine encrypted traffic baseline"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T10:05:00Z"
        alert_id = "c2-92269991"
        severity = "critical"
        type = "c2_heartbeat_detected"
        status = "open"
        source_ip = "192.168.1.90"
        c2_server = "198.51.100.44"
        interval_seconds = 60
        detail = "host beaconed to external endpoint with fixed interval"
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
        $evt = if (($i % 257) -eq 0) { "beaconing-review" } else { "normal-egress-monitoring" }
        $sev = if ($evt -eq "beaconing-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-network-01,$sev,network egress baseline")
    }

    $lines.Add("2026-03-08T10:05:00Z,periodic_beacon_confirmed,siem-network-01,high,source 192.168.1.90 communicating every 60s to 198.51.100.44")
    $lines.Add("2026-03-08T10:05:10Z,c2_server_identified,siem-network-01,critical,confirmed command server 198.51.100.44")
    $lines.Add("2026-03-08T10:05:30Z,incident_opened,siem-network-01,high,INC-2026-5606 c2 communication investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Outbound C2 Detection Policy (Excerpt)

1) Fixed-interval outbound connections are treated as potential beaconing.
2) Correlate packet, flow, DNS, endpoint, and SIEM data for attribution.
3) SOC must identify and report the external C2 server IP.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
C2 Beacon Triage Runbook (Excerpt)

1) Identify periodic communication pattern in packet/flow logs.
2) Confirm destination mapping via DNS and endpoint process records.
3) Validate with detection alerts and SIEM timeline.
4) Submit external command-and-control server IP.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Intel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Campaign tag: silent-pulse
Observed C2 profile: low-byte TLS heartbeat every 60 seconds
Known destination cluster includes: 198.51.100.44
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M6-06 C2 Communication (Real-World Investigation Pack)

Scenario:
An infected endpoint is suspected of beaconing to an external command server.

Task:
Analyze the full investigation pack and identify the command-and-control server IP.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5606
Severity: High
Queue: SOC + Threat Hunting

Summary:
Periodic outbound encrypted traffic indicates possible command-and-control behavior.

Scope:
- Suspected host: 192.168.1.90
- Behavior: 60-second heartbeat
- Objective: identify external C2 server
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate packet export, DNS, flow records, endpoint netstat, detection alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the external C2 server IP.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-TrafficCapture -OutputPath (Join-Path $bundleRoot "evidence\network\traffic.pcap")
New-DnsLog -OutputPath (Join-Path $bundleRoot "evidence\network\dns_queries.log")
New-FlowRecords -OutputPath (Join-Path $bundleRoot "evidence\network\flow_records.csv")
New-EndpointNetstat -OutputPath (Join-Path $bundleRoot "evidence\endpoint\net_connections.csv")
New-C2Alerts -OutputPath (Join-Path $bundleRoot "evidence\security\c2_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\outbound_c2_detection_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\c2_beacon_triage_runbook.txt")
New-Intel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
