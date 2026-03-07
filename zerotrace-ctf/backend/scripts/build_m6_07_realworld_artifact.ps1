param()

$ErrorActionPreference = "Stop"

$bundleName = "m6-07-suspicious-dns-query"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m6_07_realworld_build"
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

function New-DnsCapture {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# pseudo-pcap export")
    $lines.Add("# columns: frame,time_utc,src_ip,dst_ip,query_type,query_name,rcode,bytes,note")

    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcIps = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.90")
    $resolvers = @("10.30.0.53","10.30.0.54")
    $domains = @("cdn.office365.net","api.github.com","updates.windows.com","fonts.gstatic.com","login.microsoftonline.com")

    for ($i = 0; $i -lt 9600; $i++) {
        $frame = 820000 + $i
        $ts = $base.AddMilliseconds($i * 280).ToString("o")
        $src = $srcIps[$i % $srcIps.Count]
        $dst = $resolvers[$i % $resolvers.Count]
        $qname = $domains[$i % $domains.Count]
        $qtype = if (($i % 7) -eq 0) { "AAAA" } else { "A" }
        $rcode = "NOERROR"
        $bytes = 74 + (($i * 11) % 420)
        $note = if (($i % 217) -eq 0) { "cache miss" } else { "baseline dns traffic" }
        $lines.Add("$frame,$ts,$src,$dst,$qtype,$qname,$rcode,$bytes,$note")
    }

    # Exfiltration-like beaconing with encoded labels to subdomains under evil.com
    for ($j = 0; $j -lt 60; $j++) {
        $frame = 930000 + $j
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-08T11:30:00", [DateTimeKind]::Utc).AddSeconds($j * 3).ToString("o")
        $chunk = ("chunk{0:d3}" -f $j)
        $qname = "$chunk.data.exfiltration.evil.com"
        $lines.Add("$frame,$ts,192.168.1.90,10.30.0.53,TXT,$qname,NOERROR,188,suspicious high-entropy label")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsQuerySummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,query_name,query_type,count_5m,avg_label_len,entropy_score,classification,sensor")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcIps = @("192.168.1.11","192.168.1.21","192.168.1.45")
    $domains = @("cdn.office365.net","api.github.com","updates.windows.com","fonts.gstatic.com")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $src = $srcIps[$i % $srcIps.Count]
        $domain = $domains[$i % $domains.Count]
        $type = if (($i % 6) -eq 0) { "AAAA" } else { "A" }
        $count = 1 + ($i % 15)
        $labelLen = 4 + ($i % 12)
        $entropy = [Math]::Round(1.3 + (($i % 9) / 10.0), 2)
        $lines.Add("$ts,$src,$domain,$type,$count,$labelLen,$entropy,baseline,dns-analytics-01")
    }

    $lines.Add("2026-03-08T11:30:59Z,192.168.1.90,data.exfiltration.evil.com,TXT,60,24,4.92,suspected_exfil,dns-analytics-01")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ResolverLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $clients = @("192.168.1.11","192.168.1.21","192.168.1.45","192.168.1.90")
    $domains = @("cdn.office365.net","api.github.com","updates.windows.com","fonts.gstatic.com")

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $client = $clients[$i % $clients.Count]
        $domain = $domains[$i % $domains.Count]
        $lines.Add("$ts resolver=node-resolver-01 client=$client qname=$domain qtype=A rcode=NOERROR latency_ms=$(4 + ($i % 20))")
    }

    $lines.Add("2026-03-08T11:30:59Z resolver=node-resolver-01 client=192.168.1.90 qname=data.exfiltration.evil.com qtype=TXT rcode=NOERROR latency_ms=39 note=burst suspicious")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EndpointDnsActivity {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,endpoint,user,process,pid,queried_domain,query_type,query_count,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $endpoints = @("WS-101","WS-104","WS-121","WS-190")
    $users = @("alice","bob","charlie","dev01")
    $procs = @("chrome.exe","teams.exe","svchost.exe","onedrive.exe")
    $domains = @("cdn.office365.net","api.github.com","updates.windows.com")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $endpoint = $endpoints[$i % $endpoints.Count]
        $user = $users[$i % $users.Count]
        $proc = $procs[$i % $procs.Count]
        $procId = 2100 + ($i % 4000)
        $domain = $domains[$i % $domains.Count]
        $qType = if (($i % 8) -eq 0) { "AAAA" } else { "A" }
        $qCount = 1 + ($i % 8)
        $lines.Add("$ts,$endpoint,$user,$proc,$procId,$domain,$qType,$qCount,baseline")
    }

    $lines.Add("2026-03-08T11:30:59Z,WS-190,dev01,dns_tunnel_agent.exe,5012,data.exfiltration.evil.com,TXT,60,suspected_exfil")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsExfilAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("dns-volume-watch","entropy-watch","txt-query-watch","domain-reputation-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "dnsx-" + ("{0:D8}" -f (94400000 + $i))
            severity = if (($i % 171) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine dns anomaly monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T11:31:00Z"
        alert_id = "dnsx-94469990"
        severity = "critical"
        type = "dns_exfiltration_detected"
        status = "open"
        source_ip = "192.168.1.90"
        suspicious_fqdn = "data.exfiltration.evil.com"
        registered_domain = "evil.com"
        detail = "high entropy TXT query burst consistent with DNS tunneling"
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
        $evt = if (($i % 249) -eq 0) { "dns-anomaly-review" } else { "normal-dns-monitoring" }
        $sev = if ($evt -eq "dns-anomaly-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-dns-01,$sev,dns baseline behavior tracking")
    }

    $lines.Add("2026-03-08T11:31:00Z,dns_tunnel_pattern_confirmed,siem-dns-01,high,host 192.168.1.90 generated suspicious TXT burst to data.exfiltration.evil.com")
    $lines.Add("2026-03-08T11:31:10Z,registered_domain_identified,siem-dns-01,critical,exfiltration domain identified as evil.com")
    $lines.Add("2026-03-08T11:31:20Z,incident_opened,siem-dns-01,high,INC-2026-5607 dns exfiltration investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
DNS Exfiltration Monitoring Policy (Excerpt)

1) High-entropy TXT bursts are treated as potential DNS tunneling.
2) Correlate packet, resolver, endpoint, and SIEM telemetry before response.
3) SOC must identify the registered exfiltration domain for containment.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
DNS Exfiltration Triage Runbook (Excerpt)

1) Inspect DNS capture for repetitive encoded labels and TXT bursts.
2) Confirm suspicious query in resolver and endpoint telemetry.
3) Use alerts/SIEM to derive and validate registered domain.
4) Submit exfiltration domain and initiate DNS sinkhole workflow.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Intel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed tactic: DNS tunneling for staged exfiltration
Known cluster domain: evil.com
Common pattern: <chunk>.data.exfiltration.evil.com TXT bursts
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M6-07 Suspicious DNS Query (Real-World Investigation Pack)

Scenario:
DNS telemetry suggests exfiltration through tunneling-like query patterns.

Task:
Analyze the investigation pack and identify the exfiltration domain.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5607
Severity: High
Queue: SOC + Threat Hunting

Summary:
Monitoring detected high-entropy DNS TXT query bursts from an internal host.

Scope:
- Source host: 192.168.1.90
- Suspicious FQDN pattern: *.data.exfiltration.evil.com
- Objective: identify registered exfiltration domain
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate DNS packet export, query summary, resolver logs, endpoint DNS process activity, detection alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the exfiltration domain for the incident report.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-DnsCapture -OutputPath (Join-Path $bundleRoot "evidence\network\dns_capture.pcap")
New-DnsQuerySummary -OutputPath (Join-Path $bundleRoot "evidence\network\dns_query_summary.csv")
New-ResolverLog -OutputPath (Join-Path $bundleRoot "evidence\network\resolver.log")
New-EndpointDnsActivity -OutputPath (Join-Path $bundleRoot "evidence\endpoint\process_dns_activity.csv")
New-DnsExfilAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dns_exfil_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\dns_exfiltration_monitoring_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\dns_exfiltration_triage_runbook.txt")
New-Intel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
