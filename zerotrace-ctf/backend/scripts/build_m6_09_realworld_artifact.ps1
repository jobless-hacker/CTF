param()

$ErrorActionPreference = "Stop"

$bundleName = "m6-09-infected-host"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m6_09_realworld_build"
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

function New-ArpLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcIps = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.60","192.168.1.72")
    $targetIps = @("192.168.1.1","192.168.1.254","192.168.1.33","192.168.1.44")
    $macs = @("ac:1f:6b:2a:10:01","ac:1f:6b:2a:10:02","ac:1f:6b:2a:10:03","ac:1f:6b:2a:10:04","ac:1f:6b:2a:10:05")

    for ($i = 0; $i -lt 9400; $i++) {
        $ts = $base.AddMilliseconds($i * 310).ToString("o")
        $src = $srcIps[$i % $srcIps.Count]
        $dst = $targetIps[$i % $targetIps.Count]
        $mac = $macs[$i % $macs.Count]
        $op = if (($i % 4) -eq 0) { "who-has" } else { "is-at" }
        $note = if (($i % 211) -eq 0) { "normal_arp_cache_refresh" } else { "baseline_l2_activity" }
        $lines.Add("$ts arp-sensor=node-arp-01 src_ip=$src dst_ip=$dst src_mac=$mac op=$op note=$note")
    }

    for ($j = 0; $j -lt 30; $j++) {
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-08T09:10:00", [DateTimeKind]::Utc).AddSeconds($j * 4).ToString("o")
        $spoofMac = if (($j % 2) -eq 0) { "de:ad:be:ef:90:aa" } else { "de:ad:be:ef:90:bb" }
        $lines.Add("$ts arp-sensor=node-arp-01 src_ip=192.168.1.90 dst_ip=192.168.1.1 src_mac=$spoofMac op=is-at note=arp_spoof_suspected")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-MacConflictSummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,ip_address,unique_mac_count,last_seen_macs,conflict_score,classification,sensor")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.60","192.168.1.72")
    $macSets = @(
        "ac:1f:6b:2a:10:01",
        "ac:1f:6b:2a:10:02",
        "ac:1f:6b:2a:10:03",
        "ac:1f:6b:2a:10:04",
        "ac:1f:6b:2a:10:05"
    )

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $mac = $macSets[$i % $macSets.Count]
        $score = [Math]::Round(0.08 + (($i % 12) / 100.0), 2)
        $lines.Add("$ts,$ip,1,$mac,$score,baseline,l2-analytics-01")
    }

    $lines.Add("2026-03-08T09:11:58Z,192.168.1.90,2,de:ad:be:ef:90:aa|de:ad:be:ef:90:bb,0.99,suspected_compromise,l2-analytics-01")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DhcpLeases {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.60","192.168.1.72")
    $macs = @("ac:1f:6b:2a:10:01","ac:1f:6b:2a:10:02","ac:1f:6b:2a:10:03","ac:1f:6b:2a:10:04","ac:1f:6b:2a:10:05")
    $hosts = @("WS-101","WS-121","WS-145","WS-160","WS-172")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $idx = $i % $ips.Count
        $leaseEnd = $base.AddHours(8).AddSeconds($i * 7).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $lines.Add("$ts dhcpd lease_granted ip=${ips[$idx]} mac=${macs[$idx]} hostname=${hosts[$idx]} lease_end=$leaseEnd")
    }

    $lines.Add("2026-03-08T09:10:05Z dhcpd lease_renewed ip=192.168.1.90 mac=de:ad:be:ef:90:aa hostname=WS-190 lease_end=2026-03-08T17:10:05Z note=rapid_renewal_pattern")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EndpointL2Behavior {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,endpoint,user,process,pid,arp_replies_sent,gateway_claims,mac_changes,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $endpoints = @("WS-101","WS-121","WS-145","WS-160","WS-172")
    $users = @("alice","bob","charlie","dev01","ops01")
    $processes = @("svchost.exe","chrome.exe","teams.exe","onedrive.exe","agent.exe")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $ep = $endpoints[$i % $endpoints.Count]
        $user = $users[$i % $users.Count]
        $proc = $processes[$i % $processes.Count]
        $procId = 2500 + ($i % 4000)
        $replies = 1 + ($i % 8)
        $claims = 0 + ($i % 2)
        $changes = if (($i % 53) -eq 0) { 1 } else { 0 }
        $lines.Add("$ts,$ep,$user,$proc,$procId,$replies,$claims,$changes,baseline")
    }

    $lines.Add("2026-03-08T09:11:59Z,WS-190,dev01,dns_tunnel_agent.exe,5012,240,32,2,suspected_compromise")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-L2Alerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("arp-rate-watch","mac-conflict-watch","gateway-claim-watch","l2-anomaly-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "l2-" + ("{0:D8}" -f (96600000 + $i))
            severity = if (($i % 173) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine layer2 anomaly monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T09:12:00Z"
        alert_id = "l2-96669995"
        severity = "critical"
        type = "infected_host_detected"
        status = "open"
        compromised_host = "192.168.1.90"
        symptom = "arp spoofing and mac conflict anomalies"
        detail = "host generated repeated forged gateway arp replies"
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
        $evt = if (($i % 257) -eq 0) { "l2-behavior-review" } else { "normal-l2-monitoring" }
        $sev = if ($evt -eq "l2-behavior-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-l2-01,$sev,layer2 baseline telemetry")
    }

    $lines.Add("2026-03-08T09:12:00Z,arp_spoof_pattern_confirmed,siem-l2-01,high,host 192.168.1.90 sent forged gateway ARP replies")
    $lines.Add("2026-03-08T09:12:08Z,compromised_host_confirmed,siem-l2-01,critical,infected host identified as 192.168.1.90")
    $lines.Add("2026-03-08T09:12:20Z,incident_opened,siem-l2-01,high,INC-2026-5609 infected host investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Layer2 Compromise Detection Policy (Excerpt)

1) Repeated forged ARP gateway claims are high-risk compromise indicators.
2) Correlate ARP sensor logs, MAC conflict analytics, DHCP, endpoint, and SIEM data.
3) SOC must identify and report the compromised host IP.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Infected Host Triage Runbook (Excerpt)

1) Review ARP logs for spoofing and repeated forged replies.
2) Validate MAC conflict severity for suspect IP.
3) Correlate DHCP and endpoint process telemetry.
4) Confirm with security alerts and SIEM timeline.
5) Submit compromised host IP and isolate endpoint.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Intel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Campaign behavior: ARP spoofing to stage credential capture and lateral movement
Known compromised host observed in current incident: 192.168.1.90
Recommended action: network isolation and credential reset workflow
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M6-09 Infected Host (Real-World Investigation Pack)

Scenario:
Layer2 monitoring indicates ARP spoofing behavior from one internal device.

Task:
Analyze the investigation pack and identify the compromised host IP.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5609
Severity: High
Queue: SOC + Network Security

Summary:
ARP and MAC conflict analytics suggest one endpoint is compromised.

Scope:
- Suspicion: forged gateway ARP replies
- Segment: 192.168.1.0/24
- Objective: identify compromised host IP
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate ARP logs, MAC conflict summary, DHCP leases, endpoint L2 behavior, security alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the compromised host IP for immediate containment.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ArpLog -OutputPath (Join-Path $bundleRoot "evidence\network\arp.log")
New-MacConflictSummary -OutputPath (Join-Path $bundleRoot "evidence\network\mac_conflict_summary.csv")
New-DhcpLeases -OutputPath (Join-Path $bundleRoot "evidence\network\dhcp_leases.log")
New-EndpointL2Behavior -OutputPath (Join-Path $bundleRoot "evidence\endpoint\l2_behavior.csv")
New-L2Alerts -OutputPath (Join-Path $bundleRoot "evidence\security\l2_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\layer2_compromise_detection_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\infected_host_triage_runbook.txt")
New-Intel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
