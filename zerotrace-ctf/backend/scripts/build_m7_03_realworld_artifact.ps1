param()

$ErrorActionPreference = "Stop"

$bundleName = "m7-03-file-path-access"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m7_03_realworld_build"
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

function New-WebRequestLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78","157.49.12.90")
    $files = @("brochure.pdf","pricing.pdf","terms.txt","manual.docx","guide.pdf")
    $agents = @(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "Mozilla/5.0 (X11; Linux x86_64)",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
    )

    for ($i = 0; $i -lt 9400; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $file = $files[$i % $files.Count]
        $ua = $agents[$i % $agents.Count]
        $status = if (($i % 83) -eq 0) { 304 } else { 200 }
        $lines.Add("$ts request src_ip=$ip method=GET uri=`"/download?file=$file`" status=$status ua=`"$ua`" note=baseline_download")
    }

    $lines.Add("2026-03-08T12:40:05Z request src_ip=185.191.171.77 method=GET uri=`"/download?file=../../etc/passwd`" status=403 ua=`"curl/8.0`" note=suspicious_traversal_pattern")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")
    $paths = @("/download?file=brochure.pdf","/download?file=terms.txt","/download?file=manual.docx","/assets/app.js")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
        $ip = $ips[$i % $ips.Count]
        $path = $paths[$i % $paths.Count]
        $status = if (($i % 97) -eq 0) { 302 } else { 200 }
        $bytes = 700 + (($i * 19) % 18000)
        $lines.Add("$ip - - [$ts] `"GET $path HTTP/1.1`" $status $bytes")
    }

    $attackTs = [datetime]::SpecifyKind([datetime]"2026-03-08T12:40:05", [DateTimeKind]::Utc).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
    $lines.Add("185.191.171.77 - - [$attackTs] `"GET /download?file=../../etc/passwd HTTP/1.1`" 403 981")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DownloadHandlerLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")
    $files = @("/var/www/files/brochure.pdf","/var/www/files/terms.txt","/var/www/files/manual.docx")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $safePath = $files[$i % $files.Count]
        $lines.Add("$ts app=download-handler src_ip=$ip requested_file=`"$safePath`" normalization=ok result=served")
    }

    $lines.Add("2026-03-08T12:40:05Z app=download-handler src_ip=185.191.171.77 requested_file=`"../../etc/passwd`" normalization=failed result=blocked note=directory_traversal_attempt")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FileAccessAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("download-handler","cdn-service","doc-service")
    $paths = @("/var/www/files/brochure.pdf","/var/www/files/terms.txt","/var/www/files/manual.docx")

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $svc = $services[$i % $services.Count]
        $p = $paths[$i % $paths.Count]
        $lines.Add("$ts file-audit service=$svc action=read path=`"$p`" status=success context=baseline_file_download")
    }

    $lines.Add("2026-03-08T12:40:05Z file-audit service=download-handler action=read path=`"/etc/passwd`" status=denied context=path_traversal_guard")
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
        $sev = if (($i % 241) -eq 0) { "NOTICE" } else { "INFO" }
        $lines.Add("$ts waf=node-waf-03 src=$ip action=ALLOW severity=$sev rule=930120 msg=`"baseline traversal filter check`"")
    }

    $lines.Add("2026-03-08T12:40:05Z waf=node-waf-03 src=185.191.171.77 action=BLOCK severity=CRITICAL rule=930120 msg=`"OS File Access Attempt`" uri=`"/download?file=../../etc/passwd`"")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WebAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("download-anomaly-watch","waf-signature-watch","path-normalization-watch","file-access-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "webp-" + ("{0:D8}" -f (99000000 + $i))
            severity = if (($i % 181) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine web input validation monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T12:40:06Z"
        alert_id = "webp-99069995"
        severity = "critical"
        type = "file_path_attack_detected"
        status = "open"
        source_ip = "185.191.171.77"
        endpoint = "/download"
        attack_type = "path_traversal"
        payload = "../../etc/passwd"
        detail = "directory traversal payload targeting system file path"
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
        $evt = if (($i % 271) -eq 0) { "download-security-review" } else { "normal-web-monitoring" }
        $sev = if ($evt -eq "download-security-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-web-03,$sev,download endpoint baseline monitoring")
    }

    $lines.Add("2026-03-08T12:40:06Z,file_path_attack_confirmed,siem-web-03,high,correlated request/waf/app/file-audit evidence confirms traversal attempt")
    $lines.Add("2026-03-08T12:40:10Z,vulnerability_classified,siem-web-03,critical,vulnerability classified as path_traversal")
    $lines.Add("2026-03-08T12:40:22Z,incident_opened,siem-web-03,high,INC-2026-5703 file path access investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Download Path Security Policy (Excerpt)

1) Parent-directory tokens (`../`) in file parameters are high-risk.
2) Correlate request logs, WAF, app normalization, and file audit trails.
3) SOC/AppSec must classify the exploited vulnerability class.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
File Path Access Triage Runbook (Excerpt)

1) Inspect file parameter for traversal sequences.
2) Validate WAF traversal signatures and app normalization failures.
3) Confirm attempted sensitive file access in audit logs.
4) Use alerts/SIEM to finalize attack classification.
5) Submit vulnerability class and enforce strict path canonicalization.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed payload marker: ../../etc/passwd
Technique: directory traversal against download endpoint
Primary vulnerability class label: path_traversal
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ResponseSnapshot {
    param([string]$OutputPath)

    $content = @'
HTTP/1.1 403 Forbidden
Content-Type: application/json

{
  "error": "invalid file path",
  "reason": "path traversal sequence detected"
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M7-03 File Path Access (Real-World Investigation Pack)

Scenario:
Download endpoint telemetry indicates crafted file parameters may target system files.

Task:
Analyze the investigation pack and identify the exploited vulnerability class.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5703
Severity: High
Queue: SOC + AppSec

Summary:
Suspicious file parameter pattern detected against /download endpoint.

Scope:
- Endpoint: /download
- Suspect source: 185.191.171.77
- Objective: identify vulnerability class
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate request logs, access logs, app download-handler logs, file audit records, WAF output, response snapshot, security alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the vulnerability class used in the file path attack.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-WebRequestLog -OutputPath (Join-Path $bundleRoot "evidence\network\web_request.log")
New-AccessLog -OutputPath (Join-Path $bundleRoot "evidence\network\access.log")
New-DownloadHandlerLog -OutputPath (Join-Path $bundleRoot "evidence\application\download_handler.log")
New-FileAccessAudit -OutputPath (Join-Path $bundleRoot "evidence\system\file_access_audit.log")
New-WafLog -OutputPath (Join-Path $bundleRoot "evidence\network\waf.log")
New-WebAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\web_attack_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\download_path_security_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\file_path_access_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")
New-ResponseSnapshot -OutputPath (Join-Path $bundleRoot "evidence\application\response_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
