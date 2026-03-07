param()

$ErrorActionPreference = "Stop"

$bundleName = "m7-05-exposed-admin-panel"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m7_05_realworld_build"
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

function New-DirectoryListing {
    param([string]$OutputPath)

    $content = @'
Index of /

Name                    Last modified      Size
------------------------------------------------
assets/                 2026-03-07 09:21  -
docs/                   2026-03-07 09:21  -
images/                 2026-03-07 09:21  -
login.php               2026-03-07 09:20  4.2K
index.html              2026-03-07 09:20  7.8K
admin/                  2026-03-07 09:19  -
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-DiscoveryLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,scanner,path,status,bytes,title,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $paths = @("/","/about","/contact","/pricing","/docs","/assets","/images","/blog")
    $titles = @("Home","About","Contact","Pricing","Docs","Assets","Images","Blog")

    for ($i = 0; $i -lt 6700; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $path = $paths[$i % $paths.Count]
        $title = $titles[$i % $titles.Count]
        $status = if (($i % 97) -eq 0) { 301 } else { 200 }
        $bytes = 900 + (($i * 23) % 24000)
        $lines.Add("$ts,dirscan-bot-01,$path,$status,$bytes,$title,baseline")
    }

    $lines.Add("2026-03-08T10:02:12Z,dirscan-bot-01,/admin/,200,1450,Admin Panel,sensitive_directory_exposed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")
    $paths = @("/","/docs","/contact","/assets/app.js","/login.php")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
        $ip = $ips[$i % $ips.Count]
        $path = $paths[$i % $paths.Count]
        $status = if (($i % 89) -eq 0) { 304 } else { 200 }
        $bytes = 700 + (($i * 19) % 15000)
        $lines.Add("$ip - - [$ts] `"GET $path HTTP/1.1`" $status $bytes")
    }

    $alertTs = [datetime]::SpecifyKind([datetime]"2026-03-08T10:02:12", [DateTimeKind]::Utc).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
    $lines.Add("185.191.171.91 - - [$alertTs] `"GET /admin/ HTTP/1.1`" 200 1450")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RouteManifest {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $routes = @("/","/about","/docs","/contact","/api/v1/status","/assets/*")

    for ($i = 0; $i -lt 5500; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $route = $routes[$i % $routes.Count]
        $lines.Add("$ts route-manifest route=$route visibility=public auth=none note=baseline_route_inventory")
    }

    $lines.Add("2026-03-08T10:02:12Z route-manifest route=/admin/ visibility=public auth=weak note=sensitive_admin_path_exposed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RobotsSnapshot {
    param([string]$OutputPath)

    $content = @'
User-agent: *
Allow: /
Disallow: /internal/
Disallow: /tmp/
# NOTE: admin path not protected here
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-WebExposureAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("directory-enumeration-watch","route-exposure-watch","sensitive-path-watch","web-hardening-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "exp-" + ("{0:D8}" -f (99200000 + $i))
            severity = if (($i % 191) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine web surface exposure monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T10:02:13Z"
        alert_id = "exp-99269995"
        severity = "critical"
        type = "sensitive_directory_exposed"
        status = "open"
        endpoint = "/admin/"
        sensitive_directory = "admin"
        detail = "directory listing and route scan expose admin panel path"
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
        $evt = if (($i % 277) -eq 0) { "web-surface-review" } else { "normal-web-monitoring" }
        $sev = if ($evt -eq "web-surface-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-web-04,$sev,website route exposure baseline")
    }

    $lines.Add("2026-03-08T10:02:13Z,sensitive_path_confirmed,siem-web-04,high,correlated listing/scan evidence confirms exposed /admin/ path")
    $lines.Add("2026-03-08T10:02:18Z,sensitive_directory_identified,siem-web-04,critical,sensitive directory identified as admin")
    $lines.Add("2026-03-08T10:02:30Z,incident_opened,siem-web-04,high,INC-2026-5705 exposed admin panel investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Admin Surface Protection Policy (Excerpt)

1) Admin interfaces must never be exposed without strict access controls.
2) Route inventory and directory listing must be reviewed for sensitive paths.
3) SOC/AppSec must identify and report exposed sensitive directory names.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Exposed Admin Panel Triage Runbook (Excerpt)

1) Validate sensitive path exposure through directory listing and scans.
2) Correlate access telemetry and route manifest findings.
3) Confirm with security alerts and SIEM classification.
4) Submit sensitive directory name and enforce access restrictions.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Common exposed management path: /admin/
Observed abuse pattern: automated discovery followed by credential attacks
Sensitive directory label for this incident: admin
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M7-05 Exposed Admin Panel (Real-World Investigation Pack)

Scenario:
Web surface telemetry suggests a sensitive management path is publicly exposed.

Task:
Analyze the investigation pack and identify the sensitive directory.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5705
Severity: High
Queue: SOC + AppSec

Summary:
Automated discovery and listing telemetry indicate exposed admin interface.

Scope:
- Affected endpoint class: management directory
- Suspect source: 185.191.171.91
- Objective: identify sensitive directory name
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate directory listing, discovery logs, access logs, route manifest, robots snapshot, security alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the exposed sensitive directory name.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-DirectoryListing -OutputPath (Join-Path $bundleRoot "evidence\web\directory_listing.txt")
New-DiscoveryLog -OutputPath (Join-Path $bundleRoot "evidence\web\discovery_scan.csv")
New-AccessLog -OutputPath (Join-Path $bundleRoot "evidence\web\access.log")
New-RouteManifest -OutputPath (Join-Path $bundleRoot "evidence\web\route_manifest.log")
New-RobotsSnapshot -OutputPath (Join-Path $bundleRoot "evidence\web\robots_snapshot.txt")
New-WebExposureAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\web_exposure_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\admin_surface_protection_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\exposed_admin_panel_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
