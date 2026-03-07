param()

$ErrorActionPreference = "Stop"

$bundleName = "m8-01-public-storage-bucket"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m8_01_realworld_build"
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

function New-BucketObjectInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $files = @(
        "customers.csv",
        "daily_report.csv",
        "invoices_2026_03.csv",
        "contracts.pdf",
        "employees.csv",
        "pricing_sheet.xlsx",
        "logs_2026_03_07.json",
        "app_backup_20260307.tar",
        "addresses.csv",
        "service_catalog.csv"
    )

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $f = $files[$i % $files.Count]
        $size = 450 + (($i * 31) % 9800000)
        $class = if (($i % 211) -eq 0) { "internal" } else { "public_data" }
        $lines.Add("$ts bucket-inventory bucket=corp-analytics-prod object=$f size=$size classification=$class")
    }

    $lines.Add("2026-03-08T15:25:11Z bucket-inventory bucket=corp-analytics-prod object=payroll.xlsx size=1789452 classification=restricted_data note=sensitive_compensation_file")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BucketListingSnapshot {
    param([string]$OutputPath)

    $content = @'
aws s3 ls s3://corp-analytics-prod/

2026-03-08 15:18:02  customers.csv
2026-03-08 15:18:04  employees.csv
2026-03-08 15:18:05  payroll.xlsx
2026-03-08 15:18:07  service_catalog.csv
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ObjectAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.45.18.10","49.205.90.13","125.16.55.70","110.227.12.91")
    $objects = @("customers.csv","daily_report.csv","employees.csv","service_catalog.csv","contracts.pdf")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $obj = $objects[$i % $objects.Count]
        $op = if (($i % 7) -eq 0) { "ListObjectsV2" } else { "GetObject" }
        $status = 200
        $bytes = 300 + (($i * 17) % 1800000)
        $lines.Add("$ts s3-access bucket=corp-analytics-prod operation=$op object=$obj src_ip=$ip status=$status bytes=$bytes auth=iam-role")
    }

    $lines.Add("2026-03-08T15:25:13Z s3-access bucket=corp-analytics-prod operation=GetObject object=payroll.xlsx src_ip=185.246.44.22 status=200 bytes=1789452 auth=anonymous note=public_access")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudTrailEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ops = @("ListBucket","GetObject","PutObject","HeadObject")

    for ($i = 0; $i -lt 5400; $i++) {
        $entry = [ordered]@{
            eventTime = $base.AddSeconds($i * 7).ToString("o")
            eventSource = "s3.amazonaws.com"
            eventName = $ops[$i % $ops.Count]
            awsRegion = "ap-south-1"
            sourceIPAddress = "10.10.5." + (($i % 200) + 10)
            requestParameters = [ordered]@{
                bucketName = "corp-analytics-prod"
                key = "customers.csv"
            }
            userIdentity = [ordered]@{
                type = "AssumedRole"
                principalId = "AROAXXXXX:analytics-job"
            }
            managementEvent = $false
            readOnly = $true
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        eventTime = "2026-03-08T15:25:14Z"
        eventSource = "s3.amazonaws.com"
        eventName = "GetObject"
        awsRegion = "ap-south-1"
        sourceIPAddress = "185.246.44.22"
        requestParameters = [ordered]@{
            bucketName = "corp-analytics-prod"
            key = "payroll.xlsx"
        }
        userIdentity = [ordered]@{
            type = "Anonymous"
            principalId = "AWS:Anonymous"
        }
        additionalEventData = [ordered]@{
            publicRead = $true
            sensitiveObject = "payroll.xlsx"
        }
        managementEvent = $false
        readOnly = $true
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BucketPolicyAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $lines.Add("$ts policy-audit bucket=corp-analytics-prod rule=no-public-read status=pass principal=internal-only action=s3:GetObject")
    }

    $lines.Add("2026-03-08T15:25:15Z policy-audit bucket=corp-analytics-prod rule=no-public-read status=violation principal=* action=s3:GetObject scope=payroll.xlsx")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("bucket-permission-watch","object-exposure-watch","storage-anomaly-watch","public-read-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "s3exp-" + ("{0:D8}" -f (77200000 + $i))
            severity = if (($i % 191) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine storage exposure monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T15:25:16Z"
        alert_id = "s3exp-77259999"
        severity = "critical"
        type = "sensitive_object_public_exposure"
        status = "open"
        bucket = "corp-analytics-prod"
        exposed_object = "payroll.xlsx"
        detail = "restricted payroll object publicly listable and downloadable"
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
        $evt = if (($i % 257) -eq 0) { "storage-permission-review" } else { "normal-cloud-monitoring" }
        $sev = if ($evt -eq "storage-permission-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cloud-01,$sev,s3 exposure baseline telemetry")
    }

    $lines.Add("2026-03-08T15:25:17Z,public_bucket_exposure_confirmed,siem-cloud-01,high,correlated listing/access/policy evidence confirms sensitive object exposure")
    $lines.Add("2026-03-08T15:25:20Z,exposed_sensitive_file_identified,siem-cloud-01,critical,exposed sensitive payroll file identified as payroll.xlsx")
    $lines.Add("2026-03-08T15:25:30Z,incident_opened,siem-cloud-01,high,INC-2026-5801 public storage bucket exposure investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Cloud Storage Exposure Policy (Excerpt)

1) Restricted data objects must never be publicly listable or readable.
2) Bucket policies must deny public principals for sensitive datasets.
3) SOC/CloudSec must identify and report the exposed sensitive object name.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Public Bucket Exposure Triage Runbook (Excerpt)

1) Confirm object presence from bucket listing snapshot and object inventory.
2) Validate anonymous/public access in access and CloudTrail artifacts.
3) Confirm policy misconfiguration and security alert enrichment.
4) Submit normalized exposed sensitive object filename.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed breach pattern: public bucket exposure of finance/HR documents.
Most targeted spreadsheet label in this campaign: payroll.xlsx
Current incident normalized sensitive object: payroll.xlsx
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M8-01 Public Storage Bucket (Real-World Investigation Pack)

Scenario:
Cloud security monitoring indicates a storage bucket may be publicly listable with restricted files exposed.

Task:
Analyze the investigation pack and identify the sensitive payroll file exposed publicly.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5801
Severity: High
Queue: SOC + CloudSec

Summary:
Potential public exposure of sensitive file in production cloud bucket.

Scope:
- Bucket: corp-analytics-prod
- Objective: identify exposed sensitive payroll file
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate bucket listing snapshot, object inventory, access logs, CloudTrail events, policy audit logs, security alerts, SIEM timeline, and policy/runbook context.
- Determine the exposed sensitive payroll file name.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-BucketObjectInventory -OutputPath (Join-Path $bundleRoot "evidence\cloud\bucket_object_inventory.log")
New-BucketListingSnapshot -OutputPath (Join-Path $bundleRoot "evidence\cloud\bucket_listing_snapshot.txt")
New-ObjectAccessLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\object_access.log")
New-CloudTrailEvents -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloudtrail_events.jsonl")
New-BucketPolicyAudit -OutputPath (Join-Path $bundleRoot "evidence\cloud\bucket_policy_audit.log")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\storage_exposure_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\cloud_storage_exposure_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\public_bucket_exposure_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
