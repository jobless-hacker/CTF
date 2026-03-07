param()

$ErrorActionPreference = "Stop"

$bundleName = "m8-10-exposed-backup-archive"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m8_10_realworld_build"
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

function New-BackupInventoryLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $archives = @("daily_backup_20260307.tar","logs_archive_20260307.tar","db_delta_20260307.sql.gz","incremental_20260307.zip","weekly_app_backup.tar")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $arc = $archives[$i % $archives.Count]
        $size = 1000 + (($i * 37) % 25000000)
        $lines.Add("$ts backup-inventory bucket=corp-backups object=$arc size_bytes=$size category=routine exposure=restricted")
    }

    $lines.Add("2026-03-08T20:52:11Z backup-inventory bucket=corp-backups object=full_backup_2025.zip size_bytes=982347621 category=full_archive exposure=public note=historical_full_backup_exposed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BackupCatalogCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,archive_name,backup_type,contains_pii,retention,access_level,risk")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("incremental","daily","delta")
    $ret = @("30d","60d","90d")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $name = "daily_backup_" + (20260307 + ($i % 20)) + ".tar"
        $type = $types[$i % $types.Count]
        $r = $ret[$i % $ret.Count]
        $lines.Add("$ts,$name,$type,false,$r,private,low")
    }

    $lines.Add("2026-03-08T20:52:12Z,full_backup_2025.zip,full,true,365d,public,critical")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ObjectAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $objs = @("daily_backup_20260307.tar","logs_archive_20260307.tar","incremental_20260307.zip","weekly_app_backup.tar")
    $ips = @("10.8.1.11","10.8.1.22","10.8.1.33","10.8.1.44")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $obj = $objs[$i % $objs.Count]
        $ip = $ips[$i % $ips.Count]
        $lines.Add("$ts backup-access bucket=corp-backups object=$obj src_ip=$ip auth=iam-role status=200")
    }

    $lines.Add("2026-03-08T20:52:13Z backup-access bucket=corp-backups object=full_backup_2025.zip src_ip=185.77.91.20 auth=anonymous status=200 note=public_full_backup_download")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudTrailEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $events = @("ListBucket","GetBucketPolicy","GetObject")

    for ($i = 0; $i -lt 5400; $i++) {
        $entry = [ordered]@{
            eventTime = $base.AddSeconds($i * 7).ToString("o")
            eventSource = "s3.amazonaws.com"
            eventName = $events[$i % $events.Count]
            awsRegion = "ap-south-1"
            sourceIPAddress = "10.70.3." + (($i % 200) + 10)
            userIdentity = [ordered]@{
                type = "AssumedRole"
                principalId = "AROAXXXXX:backup-audit"
            }
            readOnly = $true
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        eventTime = "2026-03-08T20:52:14Z"
        eventSource = "s3.amazonaws.com"
        eventName = "GetObject"
        awsRegion = "ap-south-1"
        sourceIPAddress = "185.77.91.20"
        userIdentity = [ordered]@{
            type = "Anonymous"
            principalId = "AWS:Anonymous"
        }
        requestParameters = [ordered]@{
            bucketName = "corp-backups"
            key = "full_backup_2025.zip"
        }
        additionalEventData = [ordered]@{
            fullBackupArchive = "full_backup_2025.zip"
            publicRead = $true
        }
        readOnly = $true
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BackupPolicyAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $lines.Add("$ts backup-policy-audit control=no-public-full-archives status=pass bucket=corp-backups")
    }

    $lines.Add("2026-03-08T20:52:15Z backup-policy-audit control=no-public-full-archives status=violation bucket=corp-backups exposed_archive=full_backup_2025.zip reason=public_acl")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("backup-exposure-watch","archive-risk-watch","public-access-watch","retention-policy-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "bkp-" + ("{0:D8}" -f (91200000 + $i))
            severity = if (($i % 191) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine backup archive exposure monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T20:52:16Z"
        alert_id = "bkp-91259999"
        severity = "critical"
        type = "full_backup_archive_exposed"
        status = "open"
        exposed_archive = "full_backup_2025.zip"
        detail = "historical full backup archive publicly accessible"
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
        $evt = if (($i % 251) -eq 0) { "backup-archive-review" } else { "normal-cloud-monitoring" }
        $sev = if ($evt -eq "backup-archive-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cloud-10,$sev,backup archive posture baseline telemetry")
    }

    $lines.Add("2026-03-08T20:52:17Z,exposed_backup_archive_confirmed,siem-cloud-10,high,correlated inventory/catalog/access/cloudtrail/audit evidence confirms exposed full archive")
    $lines.Add("2026-03-08T20:52:20Z,full_backup_archive_identified,siem-cloud-10,critical,full backup archive identified as full_backup_2025.zip")
    $lines.Add("2026-03-08T20:52:28Z,incident_opened,siem-cloud-10,high,INC-2026-5810 exposed backup archive investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudBackupTxt {
    param([string]$OutputPath)

    $content = @'
daily_backup.tar
full_backup_2025.zip
logs_archive.tar
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Backup Archive Exposure Policy (Excerpt)

1) Full historical backup archives must remain private and access-controlled.
2) Public access to full archives is prohibited for all environments.
3) SOC/CloudSec must identify and report exposed full backup archive names.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Exposed Backup Archive Triage Runbook (Excerpt)

1) Correlate backup inventory, catalog classification, and cloud access records.
2) Confirm public access through CloudTrail and object access logs.
3) Validate policy violations and SIEM normalized archive name.
4) Submit exposed full backup archive filename.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed cloud data exposure pattern: publicly accessible full historical backup archives.
Current incident normalized exposed full backup archive: full_backup_2025.zip
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M8-10 Exposed Backup Archive (Real-World Investigation Pack)

Scenario:
Cloud backup telemetry indicates a historical full backup archive may be publicly accessible.

Task:
Analyze the investigation pack and identify the full backup archive.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5810
Severity: High
Queue: SOC + CloudSec

Summary:
Potential public exposure of full historical backup archive in cloud storage.

Scope:
- Bucket: corp-backups
- Objective: identify exposed full backup archive name
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate backup inventory, backup catalog classification, object access logs, CloudTrail events, policy audits, security alerts, SIEM timeline, and policy/runbook context.
- Determine the exposed full backup archive name.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-BackupInventoryLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\backup_inventory.log")
New-BackupCatalogCsv -OutputPath (Join-Path $bundleRoot "evidence\cloud\backup_catalog.csv")
New-ObjectAccessLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\object_access.log")
New-CloudTrailEvents -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloudtrail_events.jsonl")
New-BackupPolicyAudit -OutputPath (Join-Path $bundleRoot "evidence\cloud\backup_policy_audit.log")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\backup_archive_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CloudBackupTxt -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloud_backup.txt")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\backup_archive_exposure_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\exposed_backup_archive_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
