param()

$ErrorActionPreference = "Stop"

$bundleName = "m3-03-misconfigured-storage"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m3_03_realworld_build"
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

function New-S3Inventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,bucket,key,size_bytes,storage_class,acl,owner,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    $classes = @("STANDARD","STANDARD_IA","INTELLIGENT_TIERING")

    for ($i = 0; $i -lt 11600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $key = "daily_exports/contacts/segment_$('{0:D4}' -f ($i % 400)).csv"
        $acl = if (($i % 127) -eq 0) { "private" } else { "private" }
        $owner = if (($i % 2) -eq 0) { "crm-exporter" } else { "analytics-bot" }
        $cls = if (($i % 3) -eq 0) { "internal" } else { "restricted" }
        $lines.Add("$ts,corp-data-exports,$key,$((18000 + (($i * 73) % 1300000))),$($classes[$i % $classes.Count]),$acl,$owner,$cls")
    }

    $lines.Add("2026-03-07T10:14:52Z,corp-data-exports,daily_exports/finance/payroll.xlsx,512844,STANDARD,public-read,finance-exporter,restricted-payroll")
    $lines.Add("2026-03-07T10:14:57Z,corp-data-exports,daily_exports/finance/employees.csv,274412,STANDARD,public-read,finance-exporter,restricted-payroll")
    $lines.Add("2026-03-07T10:15:02Z,corp-data-exports,daily_exports/legal/contracts.pdf,882941,STANDARD,private,legal-exporter,confidential")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BucketPolicyChanges {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4100; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 21).ToString("o")
            bucket = "corp-data-exports"
            actor = if (($i % 2) -eq 0) { "infra-bot" } else { "storage-admin" }
            action = "PutBucketPolicy"
            statement_id = "Stmt-$($i % 120)"
            principal = "arn:aws:iam::111122223333:role/internal-access"
            effect = "Allow"
            status = "applied"
            note = "routine policy sync"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T10:14:48Z"
        bucket = "corp-data-exports"
        actor = "temp-contractor"
        action = "PutObjectAcl"
        key = "daily_exports/finance/payroll.xlsx"
        acl = "public-read"
        status = "applied"
        note = "manual acl change outside approved workflow"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T10:14:54Z"
        bucket = "corp-data-exports"
        actor = "temp-contractor"
        action = "PutObjectAcl"
        key = "daily_exports/finance/employees.csv"
        acl = "public-read"
        status = "applied"
        note = "secondary object exposed in same operation window"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudTrailGetObject {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $keys = @("daily_exports/contacts/segment_0001.csv","daily_exports/contacts/segment_0104.csv","daily_exports/legal/contracts.pdf")

    for ($i = 0; $i -lt 5300; $i++) {
        $entry = [ordered]@{
            eventTime = $base.AddSeconds($i * 10).ToString("o")
            eventName = "GetObject"
            eventSource = "s3.amazonaws.com"
            bucket = "corp-data-exports"
            key = $keys[$i % $keys.Count]
            sourceIPAddress = "10.150.20.$(20 + ($i % 50))"
            userAgent = "internal-sync-service"
            status = "Success"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        eventTime = "2026-03-07T10:15:08Z"
        eventName = "GetObject"
        eventSource = "s3.amazonaws.com"
        bucket = "corp-data-exports"
        key = "daily_exports/finance/payroll.xlsx"
        sourceIPAddress = "185.199.110.42"
        userAgent = "curl/8.5.0"
        status = "Success"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        eventTime = "2026-03-07T10:15:21Z"
        eventName = "GetObject"
        eventSource = "s3.amazonaws.com"
        bucket = "corp-data-exports"
        key = "daily_exports/finance/payroll.xlsx"
        sourceIPAddress = "185.199.110.42"
        userAgent = "Wget/1.21.4"
        status = "Success"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DataLossAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $signals = @("acl_change_review","export_volume_check","pii_pattern_detection","public_object_scan")

    for ($i = 0; $i -lt 3900; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 15).ToString("o")
            system = "dlp-cloud-01"
            severity = if (($i % 139) -eq 0) { "medium" } else { "low" }
            signal = $signals[$i % $signals.Count]
            object = "daily_exports/contacts/segment_$('{0:D4}' -f ($i % 300)).csv"
            status = "closed_false_positive"
            note = "baseline storage monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T10:14:59Z"
        system = "dlp-cloud-01"
        severity = "high"
        signal = "public_acl_on_payroll_data"
        object = "daily_exports/finance/payroll.xlsx"
        status = "open"
        note = "restricted payroll dataset exposed to internet"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T10:15:09Z"
        system = "dlp-cloud-01"
        severity = "critical"
        signal = "external_download_restricted_file"
        object = "daily_exports/finance/payroll.xlsx"
        status = "open"
        note = "external source downloaded public payroll file"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ExportJobAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,job_id,owner,dataset,output_key,row_count,target_acl,approval_status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $datasets = @("contacts_segment","customer_emails","invoice_recipients","feedback_emails")

    for ($i = 0; $i -lt 3200; $i++) {
        $ts = $base.AddMinutes($i).ToString("o")
        $ds = $datasets[$i % $datasets.Count]
        $key = "daily_exports/contacts/$ds-$('{0:D4}' -f ($i % 200)).csv"
        $lines.Add("$ts,JOB-$((810000 + $i)),export-bot,$ds,$key,$((100 + (($i * 11) % 5000))),private,approved")
    }

    $lines.Add("2026-03-07T10:14:46Z,JOB-991903,finance-exporter,payroll,daily_exports/finance/payroll.xlsx,124,public-read,not_approved")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 211) -eq 0) { "cloud_acl_review" } else { "routine_cloud_activity" }
        $sev = if ($event -eq "cloud_acl_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,siem-cloud-01,$sev,baseline S3 monitoring")
    }

    $lines.Add("2026-03-07T10:14:52Z,public_acl_detected,siem-cloud-01,high,payroll.xlsx switched to public-read")
    $lines.Add("2026-03-07T10:15:08Z,external_object_access,siem-cloud-01,critical,external IP accessed payroll.xlsx")
    $lines.Add("2026-03-07T10:15:20Z,incident_opened,siem-cloud-01,high,INC-2026-5037 misconfigured storage exposure")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudPolicy {
    param([string]$OutputPath)

    $content = @'
Cloud Storage Security Policy (Excerpt)

1) Payroll exports are classified restricted and must never use public-read ACL.
2) Any ACL change on restricted objects requires approved security change request.
3) External access to restricted S3 objects must trigger immediate incident response.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M3-03 Misconfigured Storage (Real-World Investigation Pack)

Scenario:
A cloud storage misconfiguration exposed restricted finance exports to the public internet.

Task:
Analyze the investigation pack and identify the file containing payroll data.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5037
Severity: High
Queue: SOC + Cloud Security

Summary:
Cloud monitoring detected public ACL exposure on finance exports followed by external object downloads.

Scope:
- Bucket: corp-data-exports
- Exposure window: 2026-03-07 10:14-10:16 UTC
- Affected prefix: daily_exports/finance/

Deliverable:
Identify the file containing payroll data.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate object inventory, policy change events, CloudTrail access logs, DLP alerts, and export-job audit.
- Confirm which exposed finance object is the payroll dataset.
- Return the payroll file name as final answer.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-S3Inventory -OutputPath (Join-Path $bundleRoot "evidence\cloud\s3_object_inventory.csv")
New-BucketPolicyChanges -OutputPath (Join-Path $bundleRoot "evidence\cloud\bucket_policy_changes.jsonl")
New-CloudTrailGetObject -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloudtrail_getobject.jsonl")
New-DataLossAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_storage_alerts.jsonl")
New-ExportJobAudit -OutputPath (Join-Path $bundleRoot "evidence\app\export_job_audit.csv")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CloudPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\cloud_storage_policy.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
