param()

$ErrorActionPreference = "Stop"

$bundleName = "m6-08-data-exfiltration"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m6_08_realworld_build"
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

function New-NetflowLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,dst_port,proto,bytes,packets,duration_sec,flow_tag,sensor")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcIps = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.90")
    $dstIps = @("142.250.183.14","104.18.30.99","52.96.34.11","172.67.33.20","151.101.1.69")
    $ports = @(443,80,8443)

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $src = $srcIps[$i % $srcIps.Count]
        $dst = $dstIps[$i % $dstIps.Count]
        $port = $ports[$i % $ports.Count]
        $bytes = 1200 + (($i * 83) % 920000)
        $pkts = 8 + ($i % 120)
        $duration = 3 + ($i % 40)
        $tag = if (($i % 211) -eq 0) { "large_transfer_review" } else { "routine_egress" }
        $lines.Add("$ts,$src,$dst,$port,TCP,$bytes,$pkts,$duration,$tag,flow-sensor-08")
    }

    $lines.Add("2026-03-08T15:42:18Z,192.168.1.45,203.0.113.200,443,TCP,80000000,91234,1140,suspected_exfiltration,flow-sensor-08")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EgressFirewallLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcIps = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.90")
    $dstIps = @("142.250.183.14","104.18.30.99","52.96.34.11","172.67.33.20")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $src = $srcIps[$i % $srcIps.Count]
        $dst = $dstIps[$i % $dstIps.Count]
        $bytes = 500 + (($i * 67) % 310000)
        $action = if (($i % 199) -eq 0) { "ALLOW_MONITOR" } else { "ALLOW" }
        $lines.Add("$ts egress-fw=node-eg-fw-01 action=$action src=$src dst=$dst proto=TCP dport=443 bytes=$bytes reason=business_traffic")
    }

    $lines.Add("2026-03-08T15:42:18Z egress-fw=node-eg-fw-01 action=ALLOW_ALERT src=192.168.1.45 dst=203.0.113.200 proto=TCP dport=443 bytes=80000000 reason=unusual_outbound_volume")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProxyTransferLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("alice","bob","charlie","dev01")
    $srcIps = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.90")
    $domains = @("upload.office365.net","sync.safevendor.net","storage.companycdn.com","api.github.com")
    $objects = @("sync.bin","report.zip","media.tar","blob.dat")

    for ($i = 0; $i -lt 5900; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $user = $users[$i % $users.Count]
        $src = $srcIps[$i % $srcIps.Count]
        $domain = $domains[$i % $domains.Count]
        $obj = $objects[$i % $objects.Count]
        $size = 3000 + (($i * 73) % 12000000)
        $status = if (($i % 187) -eq 0) { 206 } else { 200 }
        $lines.Add("$ts proxy=node-proxy-08 user=$user src=$src method=POST url=https://$domain/upload/$obj status=$status bytes_out=$size classification=normal_transfer")
    }

    $lines.Add("2026-03-08T15:42:19Z proxy=node-proxy-08 user=charlie src=192.168.1.45 method=POST url=https://203.0.113.200/upload/archive_20260308.tar status=200 bytes_out=80000000 classification=suspicious_bulk_upload")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EndpointTransferSummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,endpoint,user,process,pid,destination,bytes_sent,file_set,verdict")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $endpoints = @("WS-101","WS-104","WS-121","WS-145")
    $users = @("alice","bob","charlie","dev01")
    $procs = @("onedrive.exe","chrome.exe","teams.exe","backup_sync.exe")
    $dests = @("upload.office365.net","sync.safevendor.net","storage.companycdn.com")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $ep = $endpoints[$i % $endpoints.Count]
        $user = $users[$i % $users.Count]
        $proc = $procs[$i % $procs.Count]
        $procId = 3000 + ($i % 5000)
        $dst = $dests[$i % $dests.Count]
        $bytes = 1200 + (($i * 59) % 1400000)
        $files = 1 + ($i % 22)
        $verdict = if (($i % 233) -eq 0) { "review" } else { "normal" }
        $lines.Add("$ts,$ep,$user,$proc,$procId,$dst,$bytes,$files,$verdict")
    }

    $lines.Add("2026-03-08T15:42:19Z,WS-145,charlie,backup_sync.exe,6110,203.0.113.200,80000000,482,suspected_exfiltration")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DlpAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("egress-volume-watch","bulk-upload-watch","archive-transfer-watch","destination-reputation-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "dlp-" + ("{0:D8}" -f (95500000 + $i))
            severity = if (($i % 167) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine outbound data transfer monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T15:42:20Z"
        alert_id = "dlp-95569995"
        severity = "critical"
        type = "data_exfiltration_detected"
        status = "open"
        source_ip = "192.168.1.45"
        exfil_destination = "203.0.113.200"
        bytes_sent = 80000000
        detail = "high-volume outbound transfer to unmanaged external destination"
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
        $evt = if (($i % 251) -eq 0) { "large-transfer-review" } else { "normal-egress-monitoring" }
        $sev = if ($evt -eq "large-transfer-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-dlp-01,$sev,outbound transfer baseline")
    }

    $lines.Add("2026-03-08T15:42:20Z,exfiltration_pattern_confirmed,siem-dlp-01,high,source 192.168.1.45 transferred abnormal volume to 203.0.113.200")
    $lines.Add("2026-03-08T15:42:28Z,destination_confirmed,siem-dlp-01,critical,external exfiltration destination identified as 203.0.113.200")
    $lines.Add("2026-03-08T15:42:40Z,incident_opened,siem-dlp-01,high,INC-2026-5608 data exfiltration investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Outbound Data Exfiltration Policy (Excerpt)

1) Abnormal high-volume uploads to unmanaged destinations are high-risk.
2) Correlate flow, firewall, proxy, endpoint, and SIEM telemetry.
3) SOC must identify and report the exfiltration destination IP.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Data Exfiltration Triage Runbook (Excerpt)

1) Confirm large outbound volume in NetFlow.
2) Validate destination with firewall and proxy transfer logs.
3) Correlate endpoint process/file transfer context.
4) Confirm IOC through DLP alerts and SIEM timeline.
5) Submit exfiltration destination and trigger containment.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Intel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Pattern: opportunistic exfiltration via direct external upload endpoint
Known suspicious destination in current campaign: 203.0.113.200
Recommended action: immediate block and host isolation
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M6-08 Data Exfiltration (Real-World Investigation Pack)

Scenario:
Monitoring indicates a high-volume outbound transfer from an internal endpoint.

Task:
Analyze the investigation pack and identify the exfiltration destination IP.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5608
Severity: High
Queue: SOC + DLP Team

Summary:
A host appears to have transferred an abnormal amount of data to an external destination.

Scope:
- Source host: 192.168.1.45 (WS-145)
- Transfer size: 80,000,000 bytes
- Objective: identify exfiltration destination IP
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate netflow, egress firewall, proxy transfer, endpoint transfer summary, DLP alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the external exfiltration destination IP.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-NetflowLog -OutputPath (Join-Path $bundleRoot "evidence\network\netflow.log")
New-EgressFirewallLog -OutputPath (Join-Path $bundleRoot "evidence\network\egress_firewall.log")
New-ProxyTransferLog -OutputPath (Join-Path $bundleRoot "evidence\network\proxy_transfer.log")
New-EndpointTransferSummary -OutputPath (Join-Path $bundleRoot "evidence\endpoint\transfer_summary.csv")
New-DlpAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\outbound_data_exfiltration_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\data_exfiltration_triage_runbook.txt")
New-Intel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
