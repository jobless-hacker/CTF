param()

$ErrorActionPreference = "Stop"

$bundleName = "m7-09-insecure-cookie"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m7_09_realworld_build"
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

function New-GatewayAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.29.10.12","49.205.12.66","125.16.99.40","110.227.77.14")
    $paths = @("/login","/dashboard","/orders","/account")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $reqId = "req-" + ("{0:D7}" -f (9920000 + $i))
        $ip = $ips[$i % $ips.Count]
        $path = $paths[$i % $paths.Count]
        $code = if (($i % 141) -eq 0) { 302 } else { 200 }
        $bytes = 1100 + (($i * 29) % 19000)
        $lines.Add("$ts edge-gw request_id=$reqId src_ip=$ip method=GET path=$path status=$code bytes=$bytes app=portal-web")
    }

    $lines.Add("2026-03-08T12:07:16Z edge-gw request_id=req-9927333 src_ip=185.244.25.18 method=POST path=/login status=200 bytes=2140 app=portal-web note=cookie_security_review_triggered")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ResponseHeadersLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hosts = @("portal.example.local","app.example.local","billing.example.local")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $reqId = "req-" + ("{0:D7}" -f (9920000 + $i))
        $hostname = $hosts[$i % $hosts.Count]
        $cookie = "Set-Cookie: session_id=sess" + ("{0:D8}" -f (30000000 + $i)) + "; Path=/; Secure; HttpOnly; SameSite=Lax"
        $lines.Add("$ts response-capture request_id=$reqId host=$hostname header=`"$cookie`"")
    }

    $lines.Add("2026-03-08T12:07:16Z response-capture request_id=req-9927333 host=portal.example.local header=`"Set-Cookie: session_id=sess30007333; Path=/; Secure; SameSite=Lax`" note=missing_cookie_flag=httponly")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BrowserSecurityScan {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,scan_id,request_id,target,check,result,missing_flag,severity")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $scanId = "scan-" + ("{0:D7}" -f (4410000 + $i))
        $reqId = "req-" + ("{0:D7}" -f (9920000 + $i))
        $lines.Add("$ts,$scanId,$reqId,portal.example.local,cookie-flag-profile,pass,none,low")
    }

    $lines.Add("2026-03-08T12:07:17Z,scan-4417333,req-9927333,portal.example.local,cookie-flag-profile,fail,httponly,high")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AppSessionConfigAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $lines.Add("$ts session-config-audit profile=default secure=true httponly=true samesite=lax status=ok")
    }

    $lines.Add("2026-03-08T12:07:18Z session-config-audit profile=legacy_login secure=true httponly=false samesite=lax status=violation missing_flag=httponly")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("cookie-baseline-watch","session-profile-watch","browser-check-watch","response-header-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "cook-" + ("{0:D8}" -f (55900000 + $i))
            severity = if (($i % 197) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine cookie policy monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T12:07:19Z"
        alert_id = "cook-55959999"
        severity = "critical"
        type = "cookie_security_flag_missing"
        status = "open"
        request_id = "req-9927333"
        endpoint = "/login"
        missing_flag = "httponly"
        detail = "session cookie set without HttpOnly attribute"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 259) -eq 0) { "cookie-hardening-review" } else { "normal-session-monitoring" }
        $sev = if ($evt -eq "cookie-hardening-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-web-09,$sev,session cookie security baseline telemetry")
    }

    $lines.Add("2026-03-08T12:07:20Z,cookie_misconfiguration_confirmed,siem-web-09,high,correlated header/scan/config evidence confirms missing security flag")
    $lines.Add("2026-03-08T12:07:24Z,missing_cookie_flag_identified,siem-web-09,critical,missing cookie security flag identified as httponly")
    $lines.Add("2026-03-08T12:07:30Z,incident_opened,siem-web-09,high,INC-2026-5709 insecure cookie investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HeaderCapture {
    param([string]$OutputPath)

    $content = @'
HTTP/1.1 200 OK
Date: Sun, 08 Mar 2026 12:07:16 GMT
Server: edge-proxy
Set-Cookie: session_id=sess30007333; Path=/; Secure; SameSite=Lax
Content-Type: text/html; charset=utf-8
X-Request-Id: req-9927333
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Session Cookie Security Policy (Excerpt)

1) Authentication/session cookies must include Secure and HttpOnly attributes.
2) SameSite must be explicitly set to Lax or Strict.
3) SOC/AppSec must identify and report any missing cookie flag in production responses.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Insecure Cookie Triage Runbook (Excerpt)

1) Pivot suspicious request id across gateway and header capture artifacts.
2) Verify Set-Cookie attributes in raw response evidence.
3) Correlate browser scan, config audit, and alert/SIEM enrichment.
4) Submit normalized missing cookie flag name.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed weak pattern: session cookies without proper hardening flags.
Most exploited omission in current campaign: httponly
Current incident normalized missing flag: httponly
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M7-09 Insecure Cookie (Real-World Investigation Pack)

Scenario:
Production login responses may be setting session cookies without required security attributes.

Task:
Analyze the investigation pack and identify the missing cookie security flag.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5709
Severity: High
Queue: SOC + AppSec

Summary:
Possible session cookie hardening gap identified on login flow.

Scope:
- Endpoint: /login
- Suspicious request: req-9927333
- Objective: identify missing cookie security flag
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate gateway logs, response headers, browser security scan, session config audit, security alerts, SIEM timeline, and policy/runbook context.
- Determine the missing cookie security flag.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-GatewayAccessLog -OutputPath (Join-Path $bundleRoot "evidence\web\gateway_access.log")
New-ResponseHeadersLog -OutputPath (Join-Path $bundleRoot "evidence\web\response_headers.log")
New-BrowserSecurityScan -OutputPath (Join-Path $bundleRoot "evidence\web\browser_security_scan.csv")
New-AppSessionConfigAudit -OutputPath (Join-Path $bundleRoot "evidence\app\session_config_audit.log")
New-HeaderCapture -OutputPath (Join-Path $bundleRoot "evidence\web\http_headers.txt")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\cookie_security_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\session_cookie_security_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\insecure_cookie_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
