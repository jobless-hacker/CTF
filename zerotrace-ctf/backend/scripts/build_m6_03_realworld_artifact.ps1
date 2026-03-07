param()

$ErrorActionPreference = "Stop"

$bundleName = "m6-03-plaintext-credentials"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m6_03_realworld_build"
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

function New-HttpCapture {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# pseudo pcap export (http-focused)")
    $lines.Add("# columns: frame,time_utc,src_ip,dst_ip,proto,src_port,dst_port,http_method,http_uri,http_status,notes")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $uris = @("/index","/assets/app.js","/api/health","/products","/search?q=test")

    for ($i = 1; $i -le 9200; $i++) {
        $ts = $base.AddMilliseconds($i * 420).ToString("o")
        $src = "192.168.1.$(10 + ($i % 90))"
        $dst = if (($i % 2) -eq 0) { "10.20.0.45" } else { "10.20.0.46" }
        $sport = 20000 + ($i % 32000)
        $uri = $uris[$i % $uris.Count]
        $status = if (($i % 173) -eq 0) { 304 } else { 200 }
        $lines.Add("$i,$ts,$src,$dst,TCP,$sport,80,GET,$uri,$status,http_plaintext_baseline")
    }

    $lines.Add("9201,2026-03-08T12:18:10.1000000Z,192.168.1.60,10.20.0.45,TCP,49812,80,POST,/login,302,http_form_login")
    $lines.Add("9202,2026-03-08T12:18:10.1010000Z,192.168.1.60,10.20.0.45,TCP,49812,80,POST,/login,302,http_body:username=john&password=secret123")
    $lines.Add("9203,2026-03-08T12:18:10.2100000Z,10.20.0.45,192.168.1.60,TCP,80,49812,HTTP,/dashboard,200,set-cookie sessionid=abccf1")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HttpSessionSummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,uri,method,status,content_type,request_bytes,response_bytes,anomaly_flag")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $uris = @("/index","/home","/products","/api/items","/support")

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 3).ToString("o")
        $src = "192.168.1.$(12 + ($i % 80))"
        $uri = $uris[$i % $uris.Count]
        $req = 220 + (($i * 7) % 2200)
        $resp = 1800 + (($i * 11) % 35000)
        $flag = if (($i % 269) -eq 0) { "review" } else { "none" }
        $lines.Add("$ts,$src,10.20.0.45,$uri,GET,200,text/html,$req,$resp,$flag")
    }

    $lines.Add("2026-03-08T12:18:10Z,192.168.1.60,10.20.0.45,/login,POST,302,application/x-www-form-urlencoded,198,412,plaintext_credentials_observed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProxyHttpLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $src = "192.168.1.$(15 + ($i % 70))"
        $uri = if (($i % 3) -eq 0) { "/index" } elseif (($i % 3) -eq 1) { "/products" } else { "/api/health" }
        $lines.Add("$ts proxy node=proxy-01 src=$src method=GET host=portal.company.local uri=$uri status=200 bytes=$((900 + ($i % 28000)))")
    }

    $lines.Add("2026-03-08T12:18:10Z proxy node=proxy-01 src=192.168.1.60 method=POST host=portal.company.local uri=/login status=302 bytes=412 content_hint=cleartext_form")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HostProcessNet {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,src_ip,process_name,proc_path,connection,uri,notes")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $procs = @("chrome.exe","msedge.exe","powershell.exe","agentd.exe","updater.exe")

    for ($i = 0; $i -lt 5700; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $proc = $procs[$i % $procs.Count]
        $path = "C:/Program Files/$proc"
        $conn = "192.168.1.$(12 + ($i % 80)):$(30000 + ($i % 10000))->10.20.0.45:80"
        $uri = if (($i % 4) -eq 0) { "/home" } elseif (($i % 4) -eq 1) { "/products" } elseif (($i % 4) -eq 2) { "/index" } else { "/api/health" }
        $lines.Add("$ts,workstation-60,192.168.1.60,$proc,$path,$conn,$uri,baseline_http")
    }

    $lines.Add("2026-03-08T12:18:10Z,workstation-60,192.168.1.60,chrome.exe,C:/Program Files/chrome.exe,192.168.1.60:49812->10.20.0.45:80,/login,cleartext_credentials_submitted")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HttpAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("http_baseline_watch","credential_exposure_watch","cleartext_form_watch","traffic_profile_drift")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "http-" + ("{0:D8}" -f (99600000 + $i))
            severity = if (($i % 181) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine http telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T12:18:10Z"
        alert_id = "http-99988001"
        severity = "critical"
        type = "plaintext_credentials_detected"
        status = "open"
        detail = "HTTP login request exposed credentials in cleartext"
        leaked_username = "john"
        source_host = "192.168.1.60"
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
        $evt = if (($i % 229) -eq 0) { "http_security_review" } else { "routine_http_monitoring" }
        $sev = if ($evt -eq "http_security_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-http-01,$sev,http telemetry baseline")
    }

    $lines.Add("2026-03-08T12:18:10Z,plaintext_login_payload,siem-http-01,critical,observed username=john in HTTP POST body")
    $lines.Add("2026-03-08T12:18:15Z,credential_leak_confirmed,siem-http-01,high,leaked username identified from cleartext capture")
    $lines.Add("2026-03-08T12:18:22Z,incident_opened,siem-http-01,high,INC-2026-5603 plaintext credentials investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Cleartext Credential Policy (Excerpt)

1) Login forms must not transmit credentials over plaintext HTTP.
2) Any exposed credential field requires immediate incident response.
3) Analysts must extract leaked username during triage.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Plaintext Credential Leak Runbook (Excerpt)

1) Inspect HTTP capture for POST body credentials.
2) Correlate with proxy logs and host process activity.
3) Validate leaked identity via alert and SIEM data.
4) Force credential reset and move traffic to HTTPS only.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M6-03 Plaintext Credentials (Real-World Investigation Pack)

Scenario:
Network monitoring detected an HTTP login flow that exposed credentials in cleartext.

Task:
Analyze the investigation pack and identify the leaked username.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5603
Severity: High
Queue: SOC + Network Security + IAM

Summary:
A workstation submitted HTTP login credentials over plaintext traffic.

Scope:
- Source host: 192.168.1.60
- Window: 2026-03-08 12:18 UTC
- Goal: identify leaked username
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate HTTP capture export, session summary, proxy logs, host process network activity, security alerts, SIEM timeline, and policy/runbook guidance.
- Determine the leaked username exposed in plaintext.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-HttpCapture -OutputPath (Join-Path $bundleRoot "evidence\network\http_capture.pcap")
New-HttpSessionSummary -OutputPath (Join-Path $bundleRoot "evidence\network\http_session_summary.csv")
New-ProxyHttpLog -OutputPath (Join-Path $bundleRoot "evidence\network\proxy_http.log")
New-HostProcessNet -OutputPath (Join-Path $bundleRoot "evidence\host\workstation_process_net.csv")
New-HttpAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\http_credential_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\cleartext_credential_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\plaintext_credential_leak_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
