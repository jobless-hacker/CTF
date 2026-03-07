param()

$ErrorActionPreference = "Stop"

$bundleName = "m3-10-web-backup-exposure"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m3_10_realworld_build"
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

function New-NginxAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $uris = @("/","/index.html","/products","/pricing","/contact","/assets/app.js","/api/status")
    $agents = @("Mozilla/5.0","curl/8.6.0","python-requests/2.32.0","Googlebot/2.1")

    for ($i = 0; $i -lt 9600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("dd/MMM/yyyy:HH:mm:ss +0000", [System.Globalization.CultureInfo]::InvariantCulture)
        $ip = "10.77.$(20 + ($i % 40)).$((10 + $i) % 230)"
        $uri = $uris[$i % $uris.Count]
        $status = if (($i % 97) -eq 0) { 404 } elseif (($i % 251) -eq 0) { 500 } else { 200 }
        $bytes = 180 + (($i * 17) % 140000)
        $agent = $agents[$i % $agents.Count]
        $line = "$ip - - [$ts] ""GET $uri HTTP/1.1"" $status $bytes ""-"" ""$agent"""
        $lines.Add($line)
    }

    $lines.Add("185.199.110.42 - - [07/Mar/2026:16:04:12 +0000] ""GET /backup/site_backup_full.tar HTTP/1.1"" 200 437812112 ""-"" ""python-requests/2.32.0""")
    $lines.Add("185.199.110.42 - - [07/Mar/2026:16:04:15 +0000] ""GET /backup/ HTTP/1.1"" 200 2981 ""-"" ""python-requests/2.32.0""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ObjectInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,object_key,size_bytes,storage_class,classification,owner,last_modified")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 8400; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $obj = "backup/partial/site_backup_part_$($i % 300).tar"
        $size = 120000 + (($i * 53) % 9000000)
        $class = if (($i % 5) -eq 0) { "STANDARD_IA" } else { "STANDARD" }
        $cls = if (($i % 7) -eq 0) { "internal" } else { "ops" }
        $owner = if (($i % 2) -eq 0) { "webops-bot" } else { "backup-agent" }
        $last = $base.AddSeconds(($i * 8) + 240).ToString("o")
        $lines.Add("$ts,$obj,$size,$class,$cls,$owner,$last")
    }

    $lines.Add("2026-03-07T16:03:54Z,backup/site_backup_full.tar,437812112,STANDARD,restricted,webops-bot,2026-03-07T16:03:50Z")
    $lines.Add("2026-03-07T16:03:56Z,backup/full_backup_2025.zip,118441205,STANDARD,internal,webops-bot,2026-03-07T16:03:54Z")
    $lines.Add("2026-03-07T16:03:57Z,backup/daily_backup.tar,22881219,STANDARD_IA,internal,backup-agent,2026-03-07T16:03:55Z")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DirectorySnapshot {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Index of /backup/")
    $lines.Add("")
    $lines.Add("Name                           Last modified          Size")
    $lines.Add("---------------------------------------------------------------")

    for ($i = 0; $i -lt 6200; $i++) {
        $name = "site_backup_part_$($i % 400).tar"
        $date = "2026-03-07 15:{0:D2}" -f ($i % 60)
        $size = "{0,10}" -f (200000 + (($i * 37) % 8500000))
        $lines.Add("$name    $date    $size")
    }

    $lines.Add("daily_backup.tar               2026-03-07 16:03      22881219")
    $lines.Add("full_backup_2025.zip           2026-03-07 16:03     118441205")
    $lines.Add("site_backup_full.tar           2026-03-07 16:03     437812112")
    $lines.Add("logs_archive.tar               2026-03-07 16:03       7821451")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ExposureScans {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $checks = @("directory_listing","sensitive_backup_pattern","public_file_probe","misconfig_autoindex")

    for ($i = 0; $i -lt 4500; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            scanner = "web-exposure-checker"
            target = "www.company.example"
            check = $checks[$i % $checks.Count]
            severity = if (($i % 181) -eq 0) { "medium" } else { "low" }
            status = "closed_noise"
            finding = "no critical exposure"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T16:04:11Z"
        scanner = "web-exposure-checker"
        target = "www.company.example"
        check = "sensitive_backup_pattern"
        severity = "critical"
        status = "open"
        finding = "publicly accessible backup object: /backup/site_backup_full.tar"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CdnRequests {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,edge_pop,client_ip,uri,method,status,bytes_sent,cache_status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $pops = @("BOM","MAA","DEL","HYD")

    for ($i = 0; $i -lt 5800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $pop = $pops[$i % $pops.Count]
        $ip = "10.33.$(15 + ($i % 45)).$((40 + $i) % 220)"
        $uri = "/assets/file_$($i % 500).dat"
        $status = if (($i % 83) -eq 0) { 404 } else { 200 }
        $bytes = 120 + (($i * 29) % 180000)
        $cache = if (($i % 5) -eq 0) { "HIT" } else { "MISS" }
        $lines.Add("$ts,$pop,$ip,$uri,GET,$status,$bytes,$cache")
    }

    $lines.Add("2026-03-07T16:04:12Z,HYD,185.199.110.42,/backup/site_backup_full.tar,GET,200,437812112,MISS")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 277) -eq 0) { "backup_exposure_review" } else { "routine_web_monitoring" }
        $sev = if ($event -eq "backup_exposure_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,siem-web-01,$sev,background web telemetry analysis")
    }

    $lines.Add("2026-03-07T16:04:11Z,public_backup_detected,siem-web-01,high,critical scan finding for /backup/site_backup_full.tar")
    $lines.Add("2026-03-07T16:04:12Z,external_backup_download,siem-web-01,critical,external IP 185.199.110.42 downloaded full backup")
    $lines.Add("2026-03-07T16:04:21Z,incident_opened,siem-web-01,high,INC-2026-5264 web backup exposure incident")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WebConfig {
    param([string]$OutputPath)

    $content = @'
server {
    listen 443 ssl;
    server_name www.company.example;

    location /backup/ {
        autoindex on;
        alias /var/www/backups/;
    }
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Web Backup Exposure Policy (Excerpt)

1) Full website backups must never be publicly accessible through web paths.
2) Directory listing on backup paths is prohibited in production.
3) Any external download of full backup files is a critical incident.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M3-10 Web Backup Exposure (Real-World Investigation Pack)

Scenario:
Web backup path misconfiguration exposed internal backup artifacts through a public endpoint.

Task:
Analyze the investigation pack and identify the full website backup filename.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5264
Severity: High
Queue: SOC + WebOps + AppSec

Summary:
Security monitoring flagged public backup exposure and potential external retrieval.

Scope:
- Host: www.company.example
- Window: 2026-03-07 16:04 UTC
- Goal: identify exact full website backup file exposed publicly
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate nginx access logs, directory listing snapshot, object inventory, exposure scans, CDN edge requests, config, policy, and SIEM timeline.
- Determine the exact full website backup filename that was exposed.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-NginxAccessLog -OutputPath (Join-Path $bundleRoot "evidence\web\nginx_access.log")
New-ObjectInventory -OutputPath (Join-Path $bundleRoot "evidence\storage\backup_object_inventory.csv")
New-DirectorySnapshot -OutputPath (Join-Path $bundleRoot "evidence\web\directory_listing_snapshot.txt")
New-ExposureScans -OutputPath (Join-Path $bundleRoot "evidence\security\web_exposure_scan.jsonl")
New-CdnRequests -OutputPath (Join-Path $bundleRoot "evidence\network\cdn_edge_requests.csv")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-WebConfig -OutputPath (Join-Path $bundleRoot "evidence\config\webserver_backup_location.conf")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\web_backup_exposure_policy.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
