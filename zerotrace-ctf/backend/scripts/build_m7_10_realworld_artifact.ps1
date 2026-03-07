param()

$ErrorActionPreference = "Stop"

$bundleName = "m7-10-sensitive-backup"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m7_10_realworld_build"
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

function New-WebFilesInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $files = @(
        "index.php",
        "app.js",
        "styles.css",
        "robots.txt",
        "favicon.ico",
        "healthcheck.txt",
        "sitemap.xml",
        "about.html",
        "contact.html",
        "assets/logo.svg"
    )

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $f = $files[$i % $files.Count]
        $size = 300 + (($i * 27) % 820000)
        $lines.Add("$ts file-inventory path=/$f size=$size classification=public")
    }

    $lines.Add("2026-03-08T14:10:12Z file-inventory path=/backup.zip size=48872913 classification=should_be_private note=exposed_sensitive_backup")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DiscoveryScan {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,scan_id,target,path,status,bytes,content_type,exposure_flag")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $paths = @("/","/index.php","/robots.txt","/assets/logo.svg","/healthcheck.txt","/app.js")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $scanId = "scan-" + ("{0:D7}" -f (5510000 + $i))
        $path = $paths[$i % $paths.Count]
        $status = if (($i % 173) -eq 0) { 304 } else { 200 }
        $bytes = 350 + (($i * 19) % 980000)
        $ctype = if ($path -like "*.js") { "application/javascript" } elseif ($path -like "*.svg") { "image/svg+xml" } else { "text/html" }
        $lines.Add("$ts,$scanId,portal.example.local,$path,$status,$bytes,$ctype,false")
    }

    $lines.Add("2026-03-08T14:10:13Z,scan-5517777,portal.example.local,/backup.zip,200,48872913,application/zip,true")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.31.14.20","49.205.21.90","125.16.64.33","110.227.70.18")
    $paths = @("/","/index.php","/dashboard","/assets/logo.svg","/api/status")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
        $ip = $ips[$i % $ips.Count]
        $path = $paths[$i % $paths.Count]
        $status = if (($i % 149) -eq 0) { 302 } else { 200 }
        $bytes = 750 + (($i * 17) % 16000)
        $method = if (($i % 4) -eq 0) { "POST" } else { "GET" }
        $lines.Add("$ip - - [$ts] `"$method $path HTTP/1.1`" $status $bytes")
    }

    $ts1 = [datetime]::SpecifyKind([datetime]"2026-03-08T14:10:14", [DateTimeKind]::Utc).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
    $lines.Add("185.245.72.11 - - [$ts1] `"GET /backup.zip HTTP/1.1`" 200 48872913")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AutoIndexSnapshot {
    param([string]$OutputPath)

    $content = @'
Index of /

Name                    Last modified      Size
---------------------------------------------------------
assets/                 2026-03-08 09:12   -
index.php               2026-03-08 09:13   6K
robots.txt              2026-03-08 09:13   1K
backup.zip              2026-03-08 09:10   46M
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ConfigAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $lines.Add("$ts web-config-audit rule=deny_backup_archives status=pass path_filter=`"*.zip`" applied_to=/secure-backups")
    }

    $lines.Add("2026-03-08T14:10:15Z web-config-audit rule=deny_backup_archives status=violation path=/backup.zip exposure=public missing_restriction=deny_rule")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("surface-watch","directory-watch","artifact-watch","download-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "bkp-" + ("{0:D8}" -f (66100000 + $i))
            severity = if (($i % 199) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine exposed-file monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T14:10:16Z"
        alert_id = "bkp-66159999"
        severity = "critical"
        type = "sensitive_backup_exposed"
        status = "open"
        endpoint = "/backup.zip"
        exposed_backup_file = "backup.zip"
        detail = "publicly accessible backup archive discovered under web root"
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
        $evt = if (($i % 263) -eq 0) { "backup-surface-review" } else { "normal-surface-monitoring" }
        $sev = if ($evt -eq "backup-surface-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-web-10,$sev,web artifact exposure baseline telemetry")
    }

    $lines.Add("2026-03-08T14:10:17Z,sensitive_backup_exposure_confirmed,siem-web-10,high,correlated inventory/scan/access/config evidence confirms exposed backup")
    $lines.Add("2026-03-08T14:10:22Z,exposed_backup_file_identified,siem-web-10,critical,exposed backup file identified as backup.zip")
    $lines.Add("2026-03-08T14:10:30Z,incident_opened,siem-web-10,high,INC-2026-5710 sensitive backup exposure investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Backup Artifact Exposure Policy (Excerpt)

1) Backup archives must never be stored in publicly served web roots.
2) Web access controls must explicitly block direct access to backup artifacts.
3) SOC/AppSec must identify and report exposed backup file names.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Sensitive Backup Exposure Triage Runbook (Excerpt)

1) Correlate inventory, directory listing, and discovery scan results.
2) Validate direct public access via web server access logs.
3) Confirm policy/config mismatch and security alert enrichment.
4) Submit normalized exposed backup file name.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed weak pattern: backup archives left in public web root.
Common exposed backup naming pattern: backup.zip
Current incident normalized exposed backup file: backup.zip
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M7-10 Sensitive Backup (Real-World Investigation Pack)

Scenario:
Web surface monitoring indicates a sensitive backup archive may be publicly accessible from the site root.

Task:
Analyze the investigation pack and identify the exposed backup file.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5710
Severity: High
Queue: SOC + AppSec

Summary:
Potential sensitive backup archive exposure detected on production web host.

Scope:
- Host: portal.example.local
- Objective: identify exposed backup file name
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate web file inventory, discovery scans, access logs, autoindex snapshot, config audits, security alerts, SIEM timeline, and policy/runbook context.
- Determine the exposed backup file name.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-WebFilesInventory -OutputPath (Join-Path $bundleRoot "evidence\web\web_files_inventory.log")
New-DiscoveryScan -OutputPath (Join-Path $bundleRoot "evidence\web\discovery_scan.csv")
New-AccessLog -OutputPath (Join-Path $bundleRoot "evidence\web\access.log")
New-AutoIndexSnapshot -OutputPath (Join-Path $bundleRoot "evidence\web\autoindex_snapshot.txt")
New-ConfigAuditLog -OutputPath (Join-Path $bundleRoot "evidence\app\web_config_audit.log")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\sensitive_backup_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\backup_artifact_exposure_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\sensitive_backup_exposure_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
