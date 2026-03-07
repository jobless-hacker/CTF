param()

$ErrorActionPreference = "Stop"

$bundleName = "m7-02-reflected-script"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m7_02_realworld_build"
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

function New-RequestLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78","157.49.12.90")
    $queries = @("laptop","pricing plan","product docs","contact","training")
    $agents = @(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "Mozilla/5.0 (X11; Linux x86_64)",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
    )

    for ($i = 0; $i -lt 9200; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $q = $queries[$i % $queries.Count]
        $ua = $agents[$i % $agents.Count]
        $status = if (($i % 89) -eq 0) { 304 } else { 200 }
        $lines.Add("$ts request src_ip=$ip method=GET uri=`"/search?q=$q`" status=$status ua=`"$ua`" note=baseline_search")
    }

    $lines.Add("2026-03-08T11:55:12Z request src_ip=185.191.171.55 method=GET uri=`"/search?q=<script>alert(1)</script>`" status=200 ua=`"curl/8.0`" note=suspicious_payload")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WebAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")
    $paths = @("/","/search?q=phone","/search?q=monitor","/search?q=headset","/docs")

    for ($i = 0; $i -lt 6300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
        $ip = $ips[$i % $ips.Count]
        $path = $paths[$i % $paths.Count]
        $status = if (($i % 97) -eq 0) { 302 } else { 200 }
        $bytes = 800 + (($i * 13) % 17000)
        $lines.Add("$ip - - [$ts] `"GET $path HTTP/1.1`" $status $bytes")
    }

    $attackTs = [datetime]::SpecifyKind([datetime]"2026-03-08T11:55:12", [DateTimeKind]::Utc).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
    $lines.Add("185.191.171.55 - - [$attackTs] `"GET /search?q=<script>alert(1)</script> HTTP/1.1`" 200 1211")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AppRenderLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")
    $terms = @("phone","monitor","keyboard","mouse","training")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $term = $terms[$i % $terms.Count]
        $lines.Add("$ts app=search-ui src_ip=$ip render_mode=escaped term=`"$term`" response=ok")
    }

    $lines.Add("2026-03-08T11:55:12Z app=search-ui src_ip=185.191.171.55 render_mode=raw term=`"<script>alert(1)</script>`" response=ok note=reflected_payload_rendered")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WafLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $ip = $ips[$i % $ips.Count]
        $sev = if (($i % 233) -eq 0) { "NOTICE" } else { "INFO" }
        $lines.Add("$ts waf=node-waf-02 src=$ip action=ALLOW severity=$sev rule=941100 msg=`"baseline xss filter check`"")
    }

    $lines.Add("2026-03-08T11:55:12Z waf=node-waf-02 src=185.191.171.55 action=ALERT severity=CRITICAL rule=941100 msg=`"XSS Attack Detected`" uri=`"/search?q=<script>alert(1)</script>`"")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BrowserConsoleLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $lines.Add("$ts browser-console level=info msg=`"search page script initialized`"")
    }

    $lines.Add("2026-03-08T11:55:12Z browser-console level=warning msg=`"inline script executed from reflected query parameter`"")
    $lines.Add("2026-03-08T11:55:12Z browser-console level=info msg=`"alert(1) triggered`"")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WebAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("search-anomaly-watch","waf-signature-watch","input-validation-watch","content-render-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "webx-" + ("{0:D8}" -f (98900000 + $i))
            severity = if (($i % 181) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine web client protection monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T11:55:13Z"
        alert_id = "webx-98969995"
        severity = "critical"
        type = "reflected_script_detected"
        status = "open"
        source_ip = "185.191.171.55"
        endpoint = "/search"
        attack_type = "xss"
        payload = "<script>alert(1)</script>"
        detail = "script payload reflected in response context"
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
        $evt = if (($i % 269) -eq 0) { "web-content-review" } else { "normal-web-monitoring" }
        $sev = if ($evt -eq "web-content-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-web-02,$sev,search endpoint behavior baseline")
    }

    $lines.Add("2026-03-08T11:55:13Z,reflected_payload_confirmed,siem-web-02,high,script payload reflected through search query parameter")
    $lines.Add("2026-03-08T11:55:17Z,attack_classified,siem-web-02,critical,attack type classified as xss")
    $lines.Add("2026-03-08T11:55:30Z,incident_opened,siem-web-02,high,INC-2026-5702 reflected script investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Reflected Script Detection Policy (Excerpt)

1) Script tags in user-controlled query parameters are high-risk.
2) Correlate request logs, rendering traces, WAF events, and browser evidence.
3) SOC/AppSec must classify the web attack type.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Reflected Script Triage Runbook (Excerpt)

1) Inspect request parameters for script payload markers.
2) Confirm whether payload is reflected unsanitized in application output.
3) Validate with WAF signatures and browser-side execution clues.
4) Use alerts/SIEM to finalize attack classification.
5) Submit attack type and trigger output encoding remediation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed payload pattern: <script>alert(1)</script>
Technique: reflected client-side script execution
Primary attack type label: xss
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ResponseSnapshot {
    param([string]$OutputPath)

    $content = @'
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8

<html>
  <body>
    <h2>Search Results</h2>
    <div>You searched for: <script>alert(1)</script></div>
  </body>
</html>
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M7-02 Reflected Script (Real-World Investigation Pack)

Scenario:
Search endpoint telemetry indicates user-supplied script content may be reflected in responses.

Task:
Analyze the investigation pack and identify the web attack type.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5702
Severity: High
Queue: SOC + AppSec

Summary:
Potential client-side script execution detected via search query parameter.

Scope:
- Endpoint: /search
- Suspicious source: 185.191.171.55
- Objective: identify attack type
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate request logs, web access logs, app rendering logs, WAF output, browser console traces, response snapshot, security alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the web attack type used in this incident.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-RequestLog -OutputPath (Join-Path $bundleRoot "evidence\network\request_log.txt")
New-WebAccessLog -OutputPath (Join-Path $bundleRoot "evidence\network\access.log")
New-AppRenderLog -OutputPath (Join-Path $bundleRoot "evidence\application\render.log")
New-WafLog -OutputPath (Join-Path $bundleRoot "evidence\network\waf.log")
New-BrowserConsoleLog -OutputPath (Join-Path $bundleRoot "evidence\client\browser_console.log")
New-WebAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\web_attack_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\reflected_script_detection_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\reflected_script_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")
New-ResponseSnapshot -OutputPath (Join-Path $bundleRoot "evidence\application\response_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
