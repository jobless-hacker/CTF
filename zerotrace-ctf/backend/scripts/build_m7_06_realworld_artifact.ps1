param()

$ErrorActionPreference = "Stop"

$bundleName = "m7-06-file-upload-abuse"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m7_06_realworld_build"
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

function New-UploadLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("alice","bob","charlie","dev01","support01")
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78","157.49.12.90")
    $files = @("invoice.pdf","profile.png","report.docx","brochure.pdf","banner.jpg")
    $mimes = @("application/pdf","image/png","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/pdf","image/jpeg")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $user = $users[$i % $users.Count]
        $ip = $ips[$i % $ips.Count]
        $file = $files[$i % $files.Count]
        $mime = $mimes[$i % $mimes.Count]
        $size = 1200 + (($i * 37) % 7800000)
        $status = if (($i % 97) -eq 0) { "accepted_with_warning" } else { "accepted" }
        $lines.Add("$ts upload-service user=$user src_ip=$ip file_name=$file mime=$mime size=$size status=$status storage_path=/uploads/$file")
    }

    $lines.Add("2026-03-08T13:15:40Z upload-service user=guest src_ip=185.191.171.99 file_name=shell.php mime=application/octet-stream size=742 status=accepted storage_path=/uploads/shell.php note=extension_filter_bypass")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")
    $paths = @("/upload","/profile","/assets/app.js","/dashboard","/help")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
        $ip = $ips[$i % $ips.Count]
        $path = $paths[$i % $paths.Count]
        $status = if (($i % 113) -eq 0) { 302 } else { 200 }
        $bytes = 850 + (($i * 21) % 19000)
        $method = if (($i % 4) -eq 0) { "POST" } else { "GET" }
        $lines.Add("$ip - - [$ts] `"$method $path HTTP/1.1`" $status $bytes")
    }

    $upTs = [datetime]::SpecifyKind([datetime]"2026-03-08T13:15:40", [DateTimeKind]::Utc).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
    $lines.Add("185.191.171.99 - - [$upTs] `"POST /upload HTTP/1.1`" 200 1180")
    $webshellTs = [datetime]::SpecifyKind([datetime]"2026-03-08T13:16:03", [DateTimeKind]::Utc).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
    $lines.Add("185.191.171.99 - - [$webshellTs] `"GET /uploads/shell.php?cmd=id HTTP/1.1`" 200 321")
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
        $sev = if (($i % 239) -eq 0) { "NOTICE" } else { "INFO" }
        $lines.Add("$ts waf=node-waf-05 src=$ip action=ALLOW severity=$sev rule=933110 msg=`"baseline upload content-type inspection`"")
    }

    $lines.Add("2026-03-08T13:15:40Z waf=node-waf-05 src=185.191.171.99 action=ALERT severity=CRITICAL rule=933110 msg=`"PHP script upload attempt detected`" endpoint=`"/upload`" filename=`"shell.php`"")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-UploadInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,file_name,stored_path,detected_mime,extension,size,scanner_verdict,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $files = @("invoice.pdf","profile.png","report.docx","brochure.pdf","banner.jpg")
    $mimes = @("application/pdf","image/png","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/pdf","image/jpeg")
    $exts = @("pdf","png","docx","pdf","jpg")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $f = $files[$i % $files.Count]
        $mime = $mimes[$i % $mimes.Count]
        $ext = $exts[$i % $exts.Count]
        $size = 1200 + (($i * 17) % 6400000)
        $verdict = if (($i % 211) -eq 0) { "review" } else { "clean" }
        $lines.Add("$ts,$f,/uploads/$f,$mime,$ext,$size,$verdict,baseline")
    }

    $lines.Add("2026-03-08T13:15:41Z,shell.php,/uploads/shell.php,text/x-php,php,742,malicious,webshell_detected")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AvScanLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $files = @("invoice.pdf","profile.png","report.docx","brochure.pdf","banner.jpg")

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $f = $files[$i % $files.Count]
        $lines.Add("$ts av-scan file=/uploads/$f engine=clamav result=clean signature=none")
    }

    $lines.Add("2026-03-08T13:15:41Z av-scan file=/uploads/shell.php engine=clamav result=malicious signature=PHP.WebShell.Generic")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RequestCapture {
    param([string]$OutputPath)

    $content = @'
POST /upload HTTP/1.1
Host: app.example.local
Content-Type: multipart/form-data; boundary=----X

------X
Content-Disposition: form-data; name="file"; filename="shell.php"
Content-Type: application/octet-stream

[payload redacted for training pack]
------X--
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("upload-anomaly-watch","content-signature-watch","extension-policy-watch","webshell-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "up-" + ("{0:D8}" -f (99300000 + $i))
            severity = if (($i % 181) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine file upload monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T13:15:42Z"
        alert_id = "up-99369995"
        severity = "critical"
        type = "malicious_upload_detected"
        status = "open"
        source_ip = "185.191.171.99"
        endpoint = "/upload"
        malicious_file = "shell.php"
        detail = "uploaded php webshell detected in /uploads"
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
        $evt = if (($i % 271) -eq 0) { "upload-security-review" } else { "normal-upload-monitoring" }
        $sev = if ($evt -eq "upload-security-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-web-05,$sev,upload endpoint baseline monitoring")
    }

    $lines.Add("2026-03-08T13:15:42Z,webshell_upload_confirmed,siem-web-05,high,correlated upload/waf/av evidence confirms malicious php upload")
    $lines.Add("2026-03-08T13:15:47Z,malicious_file_identified,siem-web-05,critical,malicious uploaded file identified as shell.php")
    $lines.Add("2026-03-08T13:16:00Z,incident_opened,siem-web-05,high,INC-2026-5706 file upload abuse investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
File Upload Security Policy (Excerpt)

1) Executable/script extensions are prohibited in public upload workflows.
2) Correlate upload telemetry, content scans, and runtime access behavior.
3) SOC/AppSec must identify and report malicious uploaded file names.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
File Upload Abuse Triage Runbook (Excerpt)

1) Review upload metadata and extension/mime mismatches.
2) Confirm suspicious payload via request capture and AV signatures.
3) Validate post-upload execution attempts in access logs.
4) Use alerts/SIEM to finalize malicious file identification.
5) Submit malicious file name and quarantine artifact immediately.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed abuse pattern: webshell upload via unrestricted file endpoint
Common malicious extension in current campaign: .php
Malicious file identified in incident: shell.php
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M7-06 File Upload Abuse (Real-World Investigation Pack)

Scenario:
Upload endpoint telemetry indicates a suspicious script may have been accepted and stored.

Task:
Analyze the investigation pack and identify the malicious uploaded file.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5706
Severity: High
Queue: SOC + AppSec

Summary:
Potential webshell uploaded through public file upload endpoint.

Scope:
- Endpoint: /upload
- Suspicious source: 185.191.171.99
- Objective: identify malicious uploaded file name
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate upload logs, access logs, WAF traces, upload inventory, AV scan logs, request capture, security alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the malicious uploaded file name.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-UploadLog -OutputPath (Join-Path $bundleRoot "evidence\upload\upload.log")
New-AccessLog -OutputPath (Join-Path $bundleRoot "evidence\network\access.log")
New-WafLog -OutputPath (Join-Path $bundleRoot "evidence\network\waf.log")
New-UploadInventory -OutputPath (Join-Path $bundleRoot "evidence\upload\upload_inventory.csv")
New-AvScanLog -OutputPath (Join-Path $bundleRoot "evidence\security\av_scan.log")
New-RequestCapture -OutputPath (Join-Path $bundleRoot "evidence\upload\request_capture.txt")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\upload_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\file_upload_security_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\file_upload_abuse_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
