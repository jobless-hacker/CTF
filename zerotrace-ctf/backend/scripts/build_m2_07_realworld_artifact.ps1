param()

$ErrorActionPreference = "Stop"

$bundleName = "m2-07-unusual-web-request"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m2_07_realworld_build"
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

function New-ProxyRequests {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $domains = @(
        "updates.microsoft.com",
        "cdn.cloudflare.com",
        "portal.company.local",
        "api.github.com",
        "outlook.office.com",
        "packages.ubuntu.com"
    )
    $users = @("ops_maya","deployer","hr_readonly","finance_ro","sre_oncall","john")
    $agents = @("Mozilla/5.0 (Windows NT 10.0; Win64; x64)", "CorporateAgent/2.7", "Edge/123.0")

    for ($i = 0; $i -lt 11500; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $domain = $domains[$i % $domains.Count]
        $path = if (($i % 7) -eq 0) { "/download/update-$($i % 40).cab" } else { "/api/v1/heartbeat" }
        $user = $users[$i % $users.Count]
        $status = if (($i % 89) -eq 0) { 304 } else { 200 }
        $method = if (($i % 4) -eq 0) { "GET" } else { "POST" }
        $bytes = 1200 + (($i * 121) % 980000)
        $ua = $agents[$i % $agents.Count]
        $lines.Add("$ts src=10.70.11.$((20 + ($i % 60))) user=$user method=$method url=""https://$domain$path"" status=$status bytes_out=$bytes ua=""$ua"" category=allowed")
    }

    $lines.Add("2026-03-07T14:22:11.292Z src=10.70.11.43 user=john method=GET url=""http://malicious-site.ru/payload.exe"" status=200 bytes_out=834219 ua=""Mozilla/5.0 (Windows NT 10.0; Win64; x64)"" category=unknown")
    $lines.Add("2026-03-07T14:22:16.944Z src=10.70.11.43 user=john method=GET url=""http://malicious-site.ru/loader.ps1"" status=200 bytes_out=19340 ua=""Mozilla/5.0 (Windows NT 10.0; Win64; x64)"" category=unknown")
    $lines.Add("2026-03-07T14:22:29.171Z src=10.70.11.43 user=john method=GET url=""http://malicious-site.ru/c2/checkin"" status=200 bytes_out=721 ua=""Mozilla/5.0 (Windows NT 10.0; Win64; x64)"" category=unknown")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsQueries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,client_ip,query_type,domain,response_ip,rcode,resolver")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $domains = @(
        "updates.microsoft.com",
        "outlook.office.com",
        "api.github.com",
        "portal.company.local",
        "telemetry.company.local",
        "cdn.cloudflare.com"
    )

    for ($i = 0; $i -lt 8700; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $domain = $domains[$i % $domains.Count]
        $ip = if ($domain -like "*.local") { "10.80.5.$((10 + ($i % 40)))" } else { "104.16.$((10 + ($i % 120))).$((20 + ($i % 180)))" }
        $rcode = if (($i % 137) -eq 0) { "NXDOMAIN" } else { "NOERROR" }
        $lines.Add("$ts,10.70.11.$((20 + ($i % 60))),A,$domain,$ip,$rcode,dns-core-01")
    }

    $lines.Add("2026-03-07T14:22:09Z,10.70.11.43,A,malicious-site.ru,185.225.19.77,NOERROR,dns-core-01")
    $lines.Add("2026-03-07T14:22:15Z,10.70.11.43,A,malicious-site.ru,185.225.19.77,NOERROR,dns-core-01")
    $lines.Add("2026-03-07T14:22:28Z,10.70.11.43,A,malicious-site.ru,185.225.19.77,NOERROR,dns-core-01")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DownloadHistory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,user,browser,source_url,file_name,file_size,sha256,download_status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $files = @("report.pdf","agent_update.msi","meeting-notes.docx","patch.cab","invoice_2026.xlsx")

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $file = $files[$i % $files.Count]
        $url = "https://download.company.local/$file"
        $sha = "{0:x64}" -f (800000000000 + $i)
        $lines.Add("$ts,ws-$((20 + ($i % 50))),$((@('ops_maya','deployer','finance_ro')[$i % 3])),edge,$url,$file,$((20000 + (($i * 49) % 2000000))),$sha,success")
    }

    $lines.Add("2026-03-07T14:22:11Z,ws-43,john,edge,http://malicious-site.ru/payload.exe,payload.exe,834219,7ca0f1fc6a1aa610de5505f117f3414c267f1b5f27051df23995a8fef5d11234,success")
    $lines.Add("2026-03-07T14:22:16Z,ws-43,john,edge,http://malicious-site.ru/loader.ps1,loader.ps1,19340,bf7dd31af9421ca31f70dad79315ef2874a1f0eca868054ad848b3e170f73861,success")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EdrWebAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $signals = @("low_reputation_domain","unsigned_binary_warning","script_execution_guard","anomalous_http")

    for ($i = 0; $i -lt 4100; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 13).ToString("o")
            host = "ws-$((20 + ($i % 50)))"
            user = if (($i % 2) -eq 0) { "ops_maya" } else { "deployer" }
            severity = if (($i % 121) -eq 0) { "medium" } else { "low" }
            signal = $signals[$i % $signals.Count]
            domain = "updates.microsoft.com"
            status = "closed_false_positive"
            note = "routine browser telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T14:22:12Z"
        host = "ws-43"
        user = "john"
        severity = "high"
        signal = "suspicious_executable_download"
        domain = "malicious-site.ru"
        status = "open"
        note = "downloaded executable payload.exe from uncategorized domain"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T14:22:17Z"
        host = "ws-43"
        user = "john"
        severity = "critical"
        signal = "malware_stager_script_observed"
        domain = "malicious-site.ru"
        status = "open"
        note = "loader.ps1 download indicates probable staging activity"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DomainIntel {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("domain,category,reputation_score,first_seen,last_seen,asn,country,threat_label")
    $domains = @(
        @{ d = "updates.microsoft.com"; c = "software-update"; s = 98; asn = "AS8075"; country = "US"; t = "benign" },
        @{ d = "outlook.office.com"; c = "mail"; s = 97; asn = "AS8075"; country = "US"; t = "benign" },
        @{ d = "api.github.com"; c = "developer"; s = 96; asn = "AS36459"; country = "US"; t = "benign" },
        @{ d = "cdn.cloudflare.com"; c = "cdn"; s = 95; asn = "AS13335"; country = "US"; t = "benign" }
    )

    for ($i = 0; $i -lt 3200; $i++) {
        $x = $domains[$i % $domains.Count]
        $lines.Add("$($x.d),$($x.c),$($x.s),2025-12-01,2026-03-07,$($x.asn),$($x.country),$($x.t)")
    }

    $lines.Add("malicious-site.ru,uncategorized,4,2026-03-05,2026-03-07,AS60068,RU,malware-delivery")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FirewallEgress {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,dst_port,proto,action,bytes_out,session_id,zone,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5900; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $lines.Add("$ts,10.70.11.$((20 + ($i % 60))),104.16.$((20 + ($i % 120))).$((30 + ($i % 170))),443,tcp,allow,$((9000 + (($i * 31) % 1500000))),FW-$((88000 + $i)),corp-egress,approved")
    }

    $lines.Add("2026-03-07T14:22:11Z,10.70.11.43,185.225.19.77,80,tcp,allow,834219,FW-991771,corp-egress,unapproved")
    $lines.Add("2026-03-07T14:22:16Z,10.70.11.43,185.225.19.77,80,tcp,allow,19340,FW-991771,corp-egress,unapproved")
    $lines.Add("2026-03-07T14:22:29Z,10.70.11.43,185.225.19.77,80,tcp,allow,721,FW-991771,corp-egress,unapproved")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,host,user,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 211) -eq 0) { "web_alert_review" } else { "routine_web_activity" }
        $sev = if ($event -eq "web_alert_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,ws-$((20 + ($i % 50))),deployer,$sev,baseline web telemetry processing")
    }

    $lines.Add("2026-03-07T14:22:09Z,dns_lookup,ws-43,john,medium,query for malicious-site.ru resolved to 185.225.19.77")
    $lines.Add("2026-03-07T14:22:11Z,file_download,ws-43,john,high,payload.exe downloaded via http from malicious-site.ru")
    $lines.Add("2026-03-07T14:22:17Z,edr_alert,ws-43,john,critical,malware stager signal linked to malicious-site.ru")
    $lines.Add("2026-03-07T14:22:30Z,siem_case_opened,siem-automation,ws-43,high,INC-2026-4824 suspicious web request workflow")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WebPolicy {
    param([string]$OutputPath)

    $content = @'
Web Access and Download Policy (Excerpt)

1) Executable downloads over plain HTTP from uncategorized domains are prohibited.
2) All unknown domains must be sandbox-scanned before user access.
3) Workstations must not execute scripts downloaded from untrusted domains.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M2-07 Unusual Web Request (Real-World Investigation Pack)

Scenario:
SOC telemetry indicates a workstation requested suspicious executable content from an external website and triggered endpoint alerts.

Task:
Analyze the investigation pack and identify the malicious domain.

Flag format:
CTF{domain}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4824
Severity: High
Queue: SOC Triage

Summary:
Proxy and endpoint telemetry indicate suspicious HTTP executable/script retrieval from workstation `ws-43`.

Scope:
- Endpoint: ws-43
- User in context: john
- Window: 2026-03-07 14:22 UTC

Deliverable:
Identify the malicious domain involved in the request chain.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate DNS lookup, proxy request, download history, firewall egress, and endpoint alerts.
- Use domain reputation context and policy controls to validate maliciousness.
- Extract the malicious domain as the final answer.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ProxyRequests -OutputPath (Join-Path $bundleRoot "evidence\network\proxy.log")
New-DnsQueries -OutputPath (Join-Path $bundleRoot "evidence\network\dns_queries.csv")
New-FirewallEgress -OutputPath (Join-Path $bundleRoot "evidence\network\firewall_egress.csv")
New-DownloadHistory -OutputPath (Join-Path $bundleRoot "evidence\endpoint\download_history.csv")
New-EdrWebAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\edr_web_alerts.jsonl")
New-DomainIntel -OutputPath (Join-Path $bundleRoot "evidence\threat_intel\domain_reputation.csv")
New-WebPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\web_access_policy.txt")
New-TimelineEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
