param()

$ErrorActionPreference = "Stop"

$bundleName = "m6-05-malware-download"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m6_05_realworld_build"
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

function New-ProxyHttpLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("employee01","employee02","employee03","intern01","support01")
    $hosts = @("192.168.20.31","192.168.20.32","192.168.20.33","192.168.20.34")
    $domains = @("cdn.office-suite.com","updates.safevendor.net","static.docs-portal.org","media.learninghub.io")
    $files = @("guide.pdf","installer.msi","slides.pptx","manual.docx","report.csv")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $user = $users[$i % $users.Count]
        $sourceHost = $hosts[$i % $hosts.Count]
        $domain = $domains[$i % $domains.Count]
        $file = $files[$i % $files.Count]
        $status = if (($i % 41) -eq 0) { 304 } else { 200 }
        $bytes = 900 + (($i * 37) % 60000)
        $mime = if ($file.EndsWith(".msi")) { "application/x-msi" } else { "application/octet-stream" }
        $lines.Add("$ts proxy=node-proxy-02 user=$user src=$sourceHost method=GET url=http://$domain/downloads/$file status=$status bytes=$bytes mime=$mime category=allowed")
    }

    $lines.Add("2026-03-08T14:20:11Z proxy=node-proxy-02 user=employee02 src=192.168.20.32 method=GET url=http://malicious-domain.ru/trojan.exe status=200 bytes=731244 mime=application/octet-stream category=suspicious_download")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $clients = @("192.168.20.31","192.168.20.32","192.168.20.33","192.168.20.34")
    $domains = @("cdn.office-suite.com","updates.safevendor.net","static.docs-portal.org","media.learninghub.io")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $src = $clients[$i % $clients.Count]
        $domain = $domains[$i % $domains.Count]
        $rcode = if (($i % 173) -eq 0) { "NOERROR cached" } else { "NOERROR" }
        $lines.Add("$ts dns=node-dns-01 src=$src query=$domain type=A rcode=$rcode")
    }

    $lines.Add("2026-03-08T14:20:08Z dns=node-dns-01 src=192.168.20.32 query=malicious-domain.ru type=A rcode=NOERROR")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EndpointDownloads {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,user,source_domain,file_name,file_sha256,file_size,verdict")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("employee01","employee02","employee03","intern01")
    $hosts = @("WKSTN-431","WKSTN-432","WKSTN-433","WKSTN-434")
    $domains = @("cdn.office-suite.com","updates.safevendor.net","static.docs-portal.org")
    $files = @("guide.pdf","setup.msi","report.csv","training.mp4")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $user = $users[$i % $users.Count]
        $endpointHost = $hosts[$i % $hosts.Count]
        $domain = $domains[$i % $domains.Count]
        $file = $files[$i % $files.Count]
        $hashBytes = [System.Text.Encoding]::UTF8.GetBytes("safe-$i")
        $hashHex = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
        $hash = $hashHex.PadRight(64, '0').Substring(0,64)
        $size = 1024 + (($i * 113) % 900000)
        $verdict = if (($i % 300) -eq 0) { "review" } else { "clean" }
        $lines.Add("$ts,$endpointHost,$user,$domain,$file,$hash,$size,$verdict")
    }

    $lines.Add("2026-03-08T14:20:12Z,WKSTN-432,employee02,malicious-domain.ru,trojan.exe,9f1d1d8ea1f6113fb8e8c3f5cc0cdbf92db02698574b94866f18d54dd6a11627,731244,malicious")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EgressFlow {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,dst_port,proto,bytes,action,device")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcs = @("192.168.20.31","192.168.20.32","192.168.20.33","192.168.20.34")
    $dsts = @("104.26.3.44","203.0.113.13","198.51.100.7","172.67.8.90")
    $ports = @(80,443)

    for ($i = 0; $i -lt 6000; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $src = $srcs[$i % $srcs.Count]
        $dst = $dsts[$i % $dsts.Count]
        $port = $ports[$i % $ports.Count]
        $bytes = 350 + (($i * 61) % 200000)
        $lines.Add("$ts,$src,$dst,$port,TCP,$bytes,allow,egress-fw-01")
    }

    $lines.Add("2026-03-08T14:20:11Z,192.168.20.32,185.199.111.55,80,TCP,731244,allow,egress-fw-01")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DownloadAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("download_reputation_watch","proxy_file_anomaly","dns_file_pattern_watch","endpoint_download_review")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "dl-" + ("{0:D8}" -f (86600000 + $i))
            severity = if (($i % 163) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine web download monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T14:20:12Z"
        alert_id = "dl-86659995"
        severity = "critical"
        type = "malware_download_detected"
        status = "open"
        source_host = "WKSTN-432"
        source_ip = "192.168.20.32"
        domain = "malicious-domain.ru"
        suspicious_file = "trojan.exe"
        detail = "proxy, endpoint, and dns correlation indicates executable malware download"
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
        $evt = if (($i % 241) -eq 0) { "web_download_watch" } else { "routine_proxy_monitoring" }
        $sev = if ($evt -eq "web_download_watch") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-web-01,$sev,web content transfer baseline")
    }

    $lines.Add("2026-03-08T14:20:11Z,suspicious_executable_download,siem-web-01,high,host 192.168.20.32 fetched executable from malicious-domain.ru")
    $lines.Add("2026-03-08T14:20:12Z,malware_file_identified,siem-web-01,critical,downloaded file identified as trojan.exe")
    $lines.Add("2026-03-08T14:20:20Z,incident_opened,siem-web-01,high,INC-2026-5605 malware download investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Web Download Protection Policy (Excerpt)

1) Executable downloads from low-reputation domains are high-risk.
2) Correlate proxy, DNS, endpoint, and SIEM telemetry before containment.
3) SOC must identify and report the downloaded suspicious file name.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Malware Download Triage Runbook (Excerpt)

1) Review proxy URL and response metadata.
2) Confirm domain in DNS query history.
3) Validate endpoint download artifact and hash.
4) Confirm with SIEM and alert pipeline.
5) Submit malicious file name and isolate endpoint.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed domain: malicious-domain.ru
Associated executable naming pattern: trojan.exe, updater_patch.exe, service_update.exe
Confidence: medium-high
Recommendation: treat downloaded executable as malicious until proven otherwise.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M6-05 Malware Download (Real-World Investigation Pack)

Scenario:
Proxy telemetry indicates an employee downloaded an executable from a suspicious domain.

Task:
Analyze the full investigation pack and identify the malicious file name.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5605
Severity: High
Queue: SOC + Endpoint Security

Summary:
Web proxy and endpoint telemetry suggest a malware executable was downloaded.

Scope:
- User: employee02
- Host: WKSTN-432 / 192.168.20.32
- Suspect domain: malicious-domain.ru
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate proxy logs, DNS queries, endpoint downloads, egress flow, alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the malicious downloaded file name for case closure.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ProxyHttpLog -OutputPath (Join-Path $bundleRoot "evidence\network\proxy_http.log")
New-DnsLog -OutputPath (Join-Path $bundleRoot "evidence\network\dns_queries.log")
New-EndpointDownloads -OutputPath (Join-Path $bundleRoot "evidence\endpoint\download_history.csv")
New-EgressFlow -OutputPath (Join-Path $bundleRoot "evidence\network\egress_flow.csv")
New-DownloadAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\download_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\web_download_protection_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\malware_download_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
