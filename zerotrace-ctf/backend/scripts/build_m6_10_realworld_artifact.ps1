param()

$ErrorActionPreference = "Stop"

$bundleName = "m6-10-lateral-movement"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m6_10_realworld_build"
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

function New-SmbTrafficCapture {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# pseudo-pcap export")
    $lines.Add("# columns: frame,time_utc,src_ip,dst_ip,proto,dst_port,smb_command,status,bytes,note")

    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcIps = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.60","192.168.1.72")
    $dstIps = @("192.168.1.31","192.168.1.33","192.168.1.44","192.168.1.52","192.168.1.63")
    $commands = @("NEGOTIATE","SESSION_SETUP","TREE_CONNECT","CREATE","READ","WRITE")

    for ($i = 0; $i -lt 9800; $i++) {
        $frame = 910000 + $i
        $ts = $base.AddMilliseconds($i * 260).ToString("o")
        $src = $srcIps[$i % $srcIps.Count]
        $dst = $dstIps[$i % $dstIps.Count]
        $cmd = $commands[$i % $commands.Count]
        $status = if (($i % 173) -eq 0) { "STATUS_SUCCESS_WITH_RETRY" } else { "STATUS_SUCCESS" }
        $bytes = 120 + (($i * 27) % 24000)
        $note = if (($i % 229) -eq 0) { "normal file share access" } else { "baseline east-west smb traffic" }
        $lines.Add("$frame,$ts,$src,$dst,TCP,445,$cmd,$status,$bytes,$note")
    }

    # Lateral movement attempts from compromised source to attacked host
    for ($j = 0; $j -lt 36; $j++) {
        $frame = 980000 + $j
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-08T12:24:00", [DateTimeKind]::Utc).AddSeconds($j * 5).ToString("o")
        $cmd = if (($j % 3) -eq 0) { "SESSION_SETUP" } elseif (($j % 3) -eq 1) { "TREE_CONNECT" } else { "CREATE" }
        $status = if (($j % 4) -eq 0) { "STATUS_LOGON_FAILURE" } else { "STATUS_ACCESS_DENIED" }
        $lines.Add("$frame,$ts,192.168.1.90,192.168.1.12,TCP,445,$cmd,$status,388,suspicious lateral movement attempt")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EastWestFlow {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,dst_port,proto,packets,bytes,flow_label,sensor")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcIps = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.60","192.168.1.72")
    $dstIps = @("192.168.1.31","192.168.1.33","192.168.1.44","192.168.1.52","192.168.1.63")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $src = $srcIps[$i % $srcIps.Count]
        $dst = $dstIps[$i % $dstIps.Count]
        $pkts = 5 + ($i % 80)
        $bytes = 320 + (($i * 47) % 150000)
        $label = if (($i % 203) -eq 0) { "share-sync-review" } else { "routine-smb" }
        $lines.Add("$ts,$src,$dst,445,TCP,$pkts,$bytes,$label,eastwest-flow-01")
    }

    for ($j = 0; $j -lt 36; $j++) {
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-08T12:24:00", [DateTimeKind]::Utc).AddSeconds($j * 5).ToString("o")
        $lines.Add("$ts,192.168.1.90,192.168.1.12,445,TCP,22,11040,lateral-movement-suspected,eastwest-flow-01")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WindowsSecurityEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hosts = @("WS-101","WS-121","WS-145","WS-160","WS-172")
    $accounts = @("alice","bob","charlie","dev01","ops01")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $event = if (($i % 5) -eq 0) { "4624" } else { "5140" }
        $endpoint = $hosts[$i % $hosts.Count]
        $acct = $accounts[$i % $accounts.Count]
        $src = "192.168.1." + (11 + ($i % 80))
        $lines.Add("$ts host=$endpoint event_id=$event account=$acct src_ip=$src status=success note=baseline auth/share event")
    }

    $lines.Add("2026-03-08T12:24:55Z host=WS-112 event_id=4625 account=svc_backup src_ip=192.168.1.90 status=failure target_ip=192.168.1.12 note=suspicious remote auth failure burst")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EndpointSmbActivity {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,endpoint,user,process,pid,target_ip,attempts,share_paths,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $endpoints = @("WS-101","WS-121","WS-145","WS-160","WS-172")
    $users = @("alice","bob","charlie","dev01","ops01")
    $processes = @("explorer.exe","onedrive.exe","backupagent.exe","teams.exe","svchost.exe")
    $targets = @("192.168.1.31","192.168.1.33","192.168.1.44","192.168.1.52")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $endpoint = $endpoints[$i % $endpoints.Count]
        $user = $users[$i % $users.Count]
        $proc = $processes[$i % $processes.Count]
        $procId = 2800 + ($i % 5000)
        $target = $targets[$i % $targets.Count]
        $attempts = 1 + ($i % 6)
        $paths = 1 + ($i % 12)
        $lines.Add("$ts,$endpoint,$user,$proc,$procId,$target,$attempts,$paths,baseline")
    }

    $lines.Add("2026-03-08T12:25:00Z,WS-190,dev01,dns_tunnel_agent.exe,5012,192.168.1.12,36,18,suspected_lateral_movement")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LateralMovementAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("smb-auth-failure-watch","eastwest-volume-watch","share-enumeration-watch","lateral-pattern-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "lat-" + ("{0:D8}" -f (97700000 + $i))
            severity = if (($i % 169) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine east-west smb monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T12:25:02Z"
        alert_id = "lat-97769995"
        severity = "critical"
        type = "lateral_movement_detected"
        status = "open"
        source_host = "192.168.1.90"
        attacked_host = "192.168.1.12"
        protocol = "SMB"
        detail = "repeated denied SMB auth/share attempts indicate lateral movement"
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
        $evt = if (($i % 253) -eq 0) { "eastwest-smb-review" } else { "normal-eastwest-monitoring" }
        $sev = if ($evt -eq "eastwest-smb-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-eastwest-01,$sev,east-west smb baseline")
    }

    $lines.Add("2026-03-08T12:25:02Z,lateral_movement_pattern_confirmed,siem-eastwest-01,high,source 192.168.1.90 attempted SMB movement toward 192.168.1.12")
    $lines.Add("2026-03-08T12:25:08Z,attacked_host_identified,siem-eastwest-01,critical,attacked internal host identified as 192.168.1.12")
    $lines.Add("2026-03-08T12:25:20Z,incident_opened,siem-eastwest-01,high,INC-2026-5610 lateral movement investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Internal Lateral Movement Detection Policy (Excerpt)

1) Repeated denied SMB access attempts across internal hosts are high-risk.
2) Correlate packet, flow, endpoint, and Windows security telemetry.
3) SOC must identify and report the attacked internal target host.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Lateral Movement Triage Runbook (Excerpt)

1) Review SMB traffic for repeated auth failures and denied share access.
2) Confirm source-target pairs in east-west flow telemetry.
3) Correlate with endpoint SMB process activity and Windows events.
4) Validate through security alerts and SIEM timeline.
5) Submit attacked host IP and trigger host isolation workflow.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Intel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Campaign behavior: SMB-based lateral movement after initial foothold
Known attacker source in environment: 192.168.1.90
Current attacked target observed: 192.168.1.12
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M6-10 Lateral Movement (Real-World Investigation Pack)

Scenario:
A compromised endpoint appears to be moving laterally over SMB inside the network.

Task:
Analyze the investigation pack and identify the attacked internal host IP.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5610
Severity: High
Queue: SOC + Incident Response

Summary:
East-west SMB traffic suggests lateral movement from compromised host.

Scope:
- Suspected source: 192.168.1.90
- Protocol: SMB (TCP/445)
- Objective: identify attacked internal host IP
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate SMB packet export, east-west flow logs, Windows security events, endpoint SMB activity, security alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the attacked internal host IP for containment planning.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-SmbTrafficCapture -OutputPath (Join-Path $bundleRoot "evidence\network\smb_traffic.pcap")
New-EastWestFlow -OutputPath (Join-Path $bundleRoot "evidence\network\east_west_flow.csv")
New-WindowsSecurityEvents -OutputPath (Join-Path $bundleRoot "evidence\network\windows_security_events.log")
New-EndpointSmbActivity -OutputPath (Join-Path $bundleRoot "evidence\endpoint\smb_activity.csv")
New-LateralMovementAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\lateral_movement_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\internal_lateral_movement_detection_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\lateral_movement_triage_runbook.txt")
New-Intel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
