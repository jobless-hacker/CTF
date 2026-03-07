param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-18-cloudtrail-incident"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m1_18_realworld_build"
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

function New-CloudTrailEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    $events = @("GetObject","ListBucket","PutObject","AssumeRole","GetBucketPolicyStatus","HeadObject")
    $users = @(
        "arn:aws:sts::449921101002:assumed-role/app-prod-worker/i-01a2b3",
        "arn:aws:iam::449921101002:user/backup-service",
        "arn:aws:iam::449921101002:role/reporting-job",
        "arn:aws:iam::449921101002:user/data-ops"
    )

    for ($i = 0; $i -lt 9100; $i++) {
        $entry = [ordered]@{
            eventTime = $base.AddSeconds($i * 7).ToString("o")
            eventSource = "s3.amazonaws.com"
            eventName = $events[$i % $events.Count]
            awsRegion = "ap-south-1"
            sourceIPAddress = if (($i % 8) -eq 0) { "10.44.8.$(20 + ($i % 120))" } else { "52.95.$(30 + ($i % 60)).$((10 + $i) % 200)" }
            userIdentity = @{
                arn = $users[$i % $users.Count]
                type = "AssumedRole"
            }
            requestParameters = @{
                bucketName = "customer-database-archive"
                key = "archives/2026/03/customer_delta_$((1000 + ($i % 800))).json.gz"
            }
            responseElements = @{
                x_amz_request_id = "REQ$((5000000 + $i))"
            }
            readOnly = $true
            managementEvent = $false
        }
        $lines.Add(($entry | ConvertTo-Json -Depth 8 -Compress))
    }

    $lines.Add((([ordered]@{
        eventTime = "2026-03-06T11:24:12Z"
        eventSource = "s3.amazonaws.com"
        eventName = "GetObject"
        awsRegion = "ap-south-1"
        sourceIPAddress = "185.22.33.41"
        userAgent = "S3Browser/9.5"
        userIdentity = @{
            type = "AWSAccount"
            principalId = "AIDAEXTERNAL12"
            accountId = "anonymous"
            arn = "anonymous"
        }
        requestParameters = @{
            bucketName = "customer-database-archive"
            key = "exports/customer_pii_snapshot_2026-03-06.parquet"
        }
        additionalEventData = @{
            AuthenticationMethod = "AuthHeader"
            SignatureVersion = "SigV4"
            bytesTransferredOut = 92411763
        }
        responseElements = @{
            x_amz_request_id = "REQ9988121"
        }
        readOnly = $true
        managementEvent = $false
    }) | ConvertTo-Json -Depth 8 -Compress))

    $lines.Add((([ordered]@{
        eventTime = "2026-03-06T11:24:19Z"
        eventSource = "s3.amazonaws.com"
        eventName = "GetBucketPolicyStatus"
        awsRegion = "ap-south-1"
        sourceIPAddress = "10.44.8.22"
        userIdentity = @{
            type = "IAMUser"
            arn = "arn:aws:iam::449921101002:user/cloudsec-audit"
        }
        requestParameters = @{
            bucketName = "customer-database-archive"
        }
        responseElements = @{
            policyStatus = @{
                IsPublic = $true
            }
        }
        readOnly = $true
        managementEvent = $true
    }) | ConvertTo-Json -Depth 8 -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-S3AccessLogs {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,bucket,request_id,remote_ip,requester,operation,key,http_status,bytes_sent,object_size,user_agent,class")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    $ops = @("REST.GET.OBJECT","REST.HEAD.OBJECT","REST.GET.BUCKET","REST.PUT.OBJECT")

    for ($i = 0; $i -lt 7800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $op = $ops[$i % $ops.Count]
        $ip = if (($i % 6) -eq 0) { "10.44.8.$(20 + ($i % 80))" } else { "52.95.$(20 + ($i % 50)).$((10 + $i) % 220)" }
        $key = if (($i % 4) -eq 0) { "reports/daily_$((3000 + $i)).csv" } else { "archives/2026/03/customer_delta_$((1000 + ($i % 800))).json.gz" }
        $status = 200
        $bytes = 1200 + (($i * 37) % 1400000)
        $size = 5000 + (($i * 53) % 1800000)
        $ua = if ($op -eq "REST.GET.OBJECT") { "aws-sdk-go/1.45" } else { "aws-cli/2.12" }
        $class = if ($ip.StartsWith("10.")) { "internal_expected" } else { "aws_service_expected" }
        $lines.Add("$ts,customer-database-archive,REQ$((9000000 + $i)),$ip,arn:aws:iam::449921101002:role/app-reader,$op,$key,$status,$bytes,$size,$ua,$class")
    }

    $lines.Add("2026-03-06T11:24:12Z,customer-database-archive,REQ9988121,185.22.33.41,anonymous,REST.GET.OBJECT,exports/customer_pii_snapshot_2026-03-06.parquet,200,92411763,92411763,S3Browser/9.5,external_unexpected")
    $lines.Add("2026-03-06T11:24:18Z,customer-database-archive,REQ9988122,185.22.33.41,anonymous,REST.HEAD.OBJECT,exports/customer_pii_snapshot_2026-03-06.parquet,200,0,92411763,S3Browser/9.5,external_unexpected")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BucketPolicyVersions {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-04T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 2600; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddMinutes($i * 5).ToString("o")
            bucket = "customer-database-archive"
            version = "v$((100 + $i))"
            actor = if (($i % 5) -eq 0) { "arn:aws:iam::449921101002:user/cloudsec-audit" } else { "arn:aws:iam::449921101002:role/infra-automation" }
            statement = @{
                Effect = "Allow"
                Principal = "arn:aws:iam::449921101002:role/app-reader"
                Action = @("s3:GetObject")
                Resource = "arn:aws:s3:::customer-database-archive/*"
            }
            isPublic = $false
            change_reason = "routine policy maintenance"
        }
        $lines.Add(($entry | ConvertTo-Json -Depth 7 -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T11:20:54Z"
        bucket = "customer-database-archive"
        version = "v3719"
        actor = "arn:aws:iam::449921101002:user/temp-ops-sync"
        statement = @{
            Effect = "Allow"
            Principal = "*"
            Action = @("s3:GetObject")
            Resource = "arn:aws:s3:::customer-database-archive/*"
        }
        isPublic = $true
        change_reason = "temporary integration troubleshooting"
    }) | ConvertTo-Json -Depth 7 -Compress))

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T11:28:40Z"
        bucket = "customer-database-archive"
        version = "v3720"
        actor = "arn:aws:iam::449921101002:user/cloudsec-audit"
        statement = @{
            Effect = "Allow"
            Principal = "arn:aws:iam::449921101002:role/app-reader"
            Action = @("s3:GetObject")
            Resource = "arn:aws:s3:::customer-database-archive/*"
        }
        isPublic = $false
        change_reason = "rollback after security alert"
    }) | ConvertTo-Json -Depth 7 -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ObjectInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("bucket,key,size_bytes,storage_class,contains_pii,sensitivity,last_modified_utc")
    $base = [datetime]::SpecifyKind([datetime]"2026-02-01T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $key = if (($i % 7) -eq 0) { "reports/summary_$((2000 + $i)).csv" } else { "archives/2026/03/customer_delta_$((1000 + $i)).json.gz" }
        $pii = if (($i % 97) -eq 0) { "yes" } else { "no" }
        $sens = if ($pii -eq "yes") { "restricted" } else { "internal" }
        $modified = $base.AddHours($i * 3).ToString("o")
        $lines.Add("customer-database-archive,$key,$((2000 + (($i * 19) % 19000000))),STANDARD,$pii,$sens,$modified")
    }

    $lines.Add("customer-database-archive,exports/customer_pii_snapshot_2026-03-06.parquet,92411763,STANDARD,yes,restricted,2026-03-06T11:18:22Z")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IdentityActivity {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,principal,action,resource,source_ip,result,mfa")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    $principals = @(
        "arn:aws:iam::449921101002:user/cloudsec-audit",
        "arn:aws:iam::449921101002:role/infra-automation",
        "arn:aws:iam::449921101002:user/data-ops"
    )

    for ($i = 0; $i -lt 4800; $i++) {
        $ts = $base.AddSeconds($i * 13).ToString("o")
        $p = $principals[$i % $principals.Count]
        $act = if (($i % 3) -eq 0) { "s3:GetObject" } elseif (($i % 3) -eq 1) { "s3:ListBucket" } else { "s3:PutObject" }
        $resource = "customer-database-archive"
        $ip = "10.44.8.$(20 + ($i % 120))"
        $lines.Add("$ts,$p,$act,$resource,$ip,success,yes")
    }

    $lines.Add("2026-03-06T11:20:54Z,arn:aws:iam::449921101002:user/temp-ops-sync,s3:PutBucketPolicy,customer-database-archive,45.83.22.91,success,no")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityFindings {
    param(
        [string]$GuardDutyPath,
        [string]$MaciePath
    )

    $gd = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 3400; $i++) {
        $entry = [ordered]@{
            id = "gd-$((100000 + $i))"
            timestamp = $base.AddMinutes($i * 3).ToString("o")
            severity = if (($i % 71) -eq 0) { 3.2 } else { 1.1 }
            type = if (($i % 71) -eq 0) { "Recon:IAMUser/NetworkPermissions" } else { "Policy:IAMUser/NoMFAConsoleLogin" }
            resource = "customer-database-archive"
            status = if (($i % 71) -eq 0) { "archived" } else { "closed_false_positive" }
        }
        $gd.Add(($entry | ConvertTo-Json -Compress))
    }

    $gd.Add((([ordered]@{
        id = "gd-199981"
        timestamp = "2026-03-06T11:24:14Z"
        severity = 8.7
        type = "Policy:S3/BucketPublicAccessGranted"
        resource = "customer-database-archive"
        status = "open"
        evidence = "Principal '*' allowed with GetObject"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $GuardDutyPath -Lines $gd

    $macie = New-Object System.Collections.Generic.List[string]
    $macie.Add("timestamp_utc,finding_id,bucket,key,sensitivity,data_identifiers,severity,status")
    $baseM = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    for ($i = 0; $i -lt 2900; $i++) {
        $ts = $baseM.AddMinutes($i * 4).ToString("o")
        $key = "archives/2026/03/customer_delta_$((1000 + ($i % 800))).json.gz"
        $sev = if (($i % 83) -eq 0) { "medium" } else { "low" }
        $id = if ($sev -eq "medium") { "email_address" } else { "none" }
        $status = if ($sev -eq "medium") { "closed_false_positive" } else { "ignored" }
        $macie.Add("$ts,macie-$((20000 + $i)),customer-database-archive,$key,internal,$id,$sev,$status")
    }

    $macie.Add("2026-03-06T11:24:16Z,macie-299991,customer-database-archive,exports/customer_pii_snapshot_2026-03-06.parquet,restricted,ssn+email+phone,critical,open")
    Write-LinesFile -Path $MaciePath -Lines $macie
}

function New-ChangeApprovals {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("change_id,opened_utc,service,requested_by,approved_by,status,summary")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 1800; $i++) {
        $opened = $base.AddMinutes($i * 18).ToString("o")
        $service = if (($i % 4) -eq 0) { "s3-archive-platform" } else { "etl-reporting" }
        $requester = if (($i % 2) -eq 0) { "infra-automation" } else { "data-ops" }
        $status = "approved"
        $lines.Add("CHG-$((88000 + $i)),$opened,$service,$requester,cloud-change-advisory,$status,routine storage policy maintenance")
    }

    $lines.Add("CHG-90551,2026-03-06T11:15:00Z,s3-archive-platform,temp-ops-sync,,pending,temporary public read for troubleshooting")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-18 Unexpected Cloud Access Event (Real-World Investigation Pack)

Scenario:
Cloud security telemetry indicates an external object access from a bucket holding restricted data.
Evidence includes CloudTrail events, S3 access logs, bucket policy history, object inventory,
identity activity, GuardDuty/Macie findings, and change-approval records.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4531
Severity: High
Queue: CloudSec + SOC

Summary:
An external IP accessed a restricted object in `customer-database-archive`.
Initial triage suggests a temporary policy change made the bucket publicly readable.

Scope:
- Bucket: customer-database-archive
- Suspected object: exports/customer_pii_snapshot_2026-03-06.parquet
- Impact window: 2026-03-06 11:20 UTC onward

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate CloudTrail `GetObject` events with S3 access logs and policy state.
- Validate whether the requesting principal and source IP were expected.
- Distinguish approved internal data operations from public-access exposure.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-CloudTrailEvents -OutputPath (Join-Path $bundleRoot "evidence\aws\cloudtrail_events.jsonl")
New-S3AccessLogs -OutputPath (Join-Path $bundleRoot "evidence\aws\s3_access_logs.csv")
New-BucketPolicyVersions -OutputPath (Join-Path $bundleRoot "evidence\aws\bucket_policy_versions.jsonl")
New-ObjectInventory -OutputPath (Join-Path $bundleRoot "evidence\aws\object_inventory.csv")
New-IdentityActivity -OutputPath (Join-Path $bundleRoot "evidence\iam\identity_activity.csv")
New-SecurityFindings -GuardDutyPath (Join-Path $bundleRoot "evidence\security\guardduty_findings.jsonl") -MaciePath (Join-Path $bundleRoot "evidence\security\macie_findings.csv")
New-ChangeApprovals -OutputPath (Join-Path $bundleRoot "evidence\operations\change_approvals.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
