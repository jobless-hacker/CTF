param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-01-public-bucket-exposure"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_01_realworld_build"
$bundleRoot = Join-Path $buildRoot $bundleName

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

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

function Format-S3Timestamp {
    param([datetime]$DateTimeUtc)

    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    return "[" + $DateTimeUtc.ToString("dd/MMM/yyyy:HH:mm:ss", $culture) + " +0000]"
}

function New-M1PublicBucketS3AccessLog {
    param([string]$OutputPath)

    $bucketOwner = "79a1f58d1f7de1a9cd7c8b944b4ee31dd4b2d9013c6a12e730ef92b8a31a5f50"
    $bucketName = "medvault-diagnostic-prod"
    $lines = New-Object System.Collections.Generic.List[string]
    $baseUtc = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    $normalIps = @(
        "10.24.8.14",
        "10.24.8.17",
        "10.24.8.23",
        "10.24.8.31",
        "10.24.9.10",
        "49.36.11.77",
        "49.36.11.78"
    )
    $normalRequesters = @(
        "arn:aws:iam::123456789012:role/etl-reporting",
        "arn:aws:iam::123456789012:role/web-assets-reader",
        "arn:aws:iam::123456789012:user/ops-backup-bot",
        "arn:aws:iam::123456789012:role/billing-exporter"
    )
    $normalKeys = @(
        "public/pricing-sheet.pdf",
        "public/location-map.png",
        "reports/daily/appointments_summary_2026-03-05.csv",
        "reports/daily/billing_summary_2026-03-05.csv",
        "site-assets/logo.png",
        "site-assets/banner-march.jpg",
        "backups/2026-03-05/config.tar.gz",
        "exports/marketing_leads_2026-03.csv"
    )
    $normalAgents = @(
        "aws-cli/2.15.23 Python/3.11.8 Windows/10 exe/AMD64",
        "Boto3/1.34.41 md/Botocore#1.34.41 ua/2.0 os/windows#10 md/arch#x86_64",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/123.0.0.0 Safari/537.36",
        "curl/8.6.0"
    )

    $suspiciousIp = "185.199.110.42"
    $suspiciousKeys = @(
        "patients/2026/03/patient_master_export.csv",
        "patients/2026/03/lab_results_dump.csv",
        "patients/2026/03/referral_contacts.csv",
        "finance/2026/insurance_claims_q1.xlsx",
        "finance/2026/payout_beneficiary_list.csv"
    )

    # 10,420 realistic noisy lines
    for ($i = 0; $i -lt 10420; $i++) {
        $timestamp = Format-S3Timestamp -DateTimeUtc ($baseUtc.AddSeconds($i * 5))
        $ip = $normalIps[$i % $normalIps.Count]
        $requester = $normalRequesters[$i % $normalRequesters.Count]
        $key = $normalKeys[$i % $normalKeys.Count]
        $userAgent = $normalAgents[$i % $normalAgents.Count]
        $requestId = ("NR{0:D8}" -f $i)
        $op = if (($i % 17) -eq 0) { "REST.HEAD.OBJECT" } elseif (($i % 31) -eq 0) { "REST.GET.BUCKET" } else { "REST.GET.OBJECT" }
        $uri = if ($op -eq "REST.GET.BUCKET") { "GET /$bucketName?prefix=reports%2Fdaily%2F HTTP/1.1" } elseif ($op -eq "REST.HEAD.OBJECT") { "HEAD /$bucketName/$key HTTP/1.1" } else { "GET /$bucketName/$key HTTP/1.1" }
        $status = if (($i % 37) -eq 0) { "304" } elseif (($i % 401) -eq 0) { "403" } else { "200" }
        $errorCode = if ($status -eq "403") { "AccessDenied" } else { "-" }
        $bytesSent = if ($status -eq "200") { 18000 + (($i * 19) % 65000) } else { 0 }
        $objectSize = if ($status -eq "200") { $bytesSent } else { "-" }
        $totalTime = 18 + ($i % 34)
        $turnAround = 15 + ($i % 20)

        $lines.Add((
            "{0} {1} {2} {3} {4} {5} {6} {7} ""{8}"" {9} {10} {11} {12} {13} {14} ""-"" ""{15}"" - HostIdExample SigV4 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader {16}.s3.ap-south-1.amazonaws.com TLSv1.2 - -" -f
            $bucketOwner, $bucketName, $timestamp, $ip, $requester, $requestId, $op, $key, $uri, $status, $errorCode, $bytesSent, $objectSize, $totalTime, $turnAround, $userAgent, $bucketName
        ))
    }

    # False-positive scanner traffic (403s)
    for ($j = 0; $j -lt 28; $j++) {
        $timestamp = Format-S3Timestamp -DateTimeUtc ($baseUtc.AddHours(5).AddSeconds($j * 9))
        $requestId = ("FP{0:D8}" -f $j)
        $lines.Add((
            "{0} {1} {2} 198.51.100.77 - {3} REST.GET.OBJECT .env ""GET /{1}/.env HTTP/1.1"" 403 AccessDenied 0 - 23 21 ""-"" ""Nuclei - Open Source Project (github.com/projectdiscovery/nuclei)"" - HostIdExample SigV4 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader {1}.s3.ap-south-1.amazonaws.com TLSv1.2 - -" -f
            $bucketOwner, $bucketName, $timestamp, $requestId
        ))
    }

    # Suspicious anonymous bulk reads of sensitive objects
    for ($k = 0; $k -lt 122; $k++) {
        $timestamp = Format-S3Timestamp -DateTimeUtc ($baseUtc.AddHours(8).AddMinutes(11).AddSeconds($k * 3))
        $requestId = ("SX{0:D8}" -f $k)
        $key = $suspiciousKeys[$k % $suspiciousKeys.Count]
        $uri = "GET /$bucketName/$key HTTP/1.1"
        $bytes = 70000 + (($k * 103) % 140000)
        $lines.Add((
            "{0} {1} {2} {3} - {4} REST.GET.OBJECT {5} ""{6}"" 200 - {7} {7} 44 42 ""-"" ""curl/8.5.0"" - HostIdExample SigV4 ECDHE-RSA-AES128-GCM-SHA256 QueryString {1}.s3.ap-south-1.amazonaws.com TLSv1.2 - -" -f
            $bucketOwner, $bucketName, $timestamp, $suspiciousIp, $requestId, $key, $uri, $bytes
        ))
    }

    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

function New-M1PublicBucketCloudTrailEvents {
    param([string]$OutputPath)

    $events = New-Object System.Collections.Generic.List[object]
    $bucketName = "medvault-diagnostic-prod"

    for ($i = 0; $i -lt 38; $i++) {
        $events.Add([ordered]@{
            eventVersion = "1.10"
            userIdentity = [ordered]@{
                type = "AssumedRole"
                arn = "arn:aws:sts::123456789012:assumed-role/etl-reporting/athena-job-$i"
                principalId = "AROAETLROLE:athena-job-$i"
                accountId = "123456789012"
            }
            eventTime = ([datetime]::SpecifyKind([datetime]"2026-03-06T06:00:00", [DateTimeKind]::Utc).AddMinutes($i)).ToString("o")
            eventSource = "s3.amazonaws.com"
            eventName = "GetObject"
            awsRegion = "ap-south-1"
            sourceIPAddress = "10.24.8.14"
            userAgent = "aws-sdk-go/1.47"
            requestParameters = [ordered]@{
                bucketName = $bucketName
                key = "reports/daily/appointments_summary_2026-03-05.csv"
            }
            responseElements = [ordered]@{
                xAmzRequestId = ("NORMREQ{0:D4}" -f $i)
            }
            readOnly = $true
            managementEvent = $false
            eventType = "AwsApiCall"
            recipientAccountId = "123456789012"
        })
    }

    $events.Add([ordered]@{
        eventVersion = "1.10"
        userIdentity = [ordered]@{
            type = "AssumedRole"
            arn = "arn:aws:sts::123456789012:assumed-role/cicd-deploy-role/github-actions"
            principalId = "AROACICDROLE:github-actions"
            accountId = "123456789012"
        }
        eventTime = "2026-03-06T08:08:43Z"
        eventSource = "s3.amazonaws.com"
        eventName = "PutBucketPolicy"
        awsRegion = "ap-south-1"
        sourceIPAddress = "185.199.110.42"
        userAgent = "aws-cli/2.15.23 Python/3.11.8 Linux/6.6.17 botocore/2.4.15"
        requestParameters = [ordered]@{
            bucketName = $bucketName
        }
        responseElements = [ordered]@{
            xAmzRequestId = "PBPOLICY-9912"
        }
        readOnly = $false
        managementEvent = $true
        eventType = "AwsApiCall"
        recipientAccountId = "123456789012"
    })

    $events.Add([ordered]@{
        eventVersion = "1.10"
        userIdentity = [ordered]@{
            type = "AssumedRole"
            arn = "arn:aws:sts::123456789012:assumed-role/security-audit-role/config-rule-runner"
            principalId = "AROASECAUDIT:config-rule-runner"
            accountId = "123456789012"
        }
        eventTime = "2026-03-06T08:10:05Z"
        eventSource = "s3.amazonaws.com"
        eventName = "GetBucketPolicyStatus"
        awsRegion = "ap-south-1"
        sourceIPAddress = "10.30.1.25"
        userAgent = "config.amazonaws.com"
        requestParameters = [ordered]@{
            bucketName = $bucketName
        }
        responseElements = [ordered]@{
            policyStatus = [ordered]@{
                isPublic = $true
            }
        }
        readOnly = $true
        managementEvent = $true
        eventType = "AwsApiCall"
        recipientAccountId = "123456789012"
    })

    for ($j = 0; $j -lt 7; $j++) {
        $events.Add([ordered]@{
            eventVersion = "1.10"
            userIdentity = [ordered]@{
                type = "AWSAccount"
                principalId = "AWS:Anonymous"
                accountId = "anonymous"
            }
            eventTime = ([datetime]::SpecifyKind([datetime]"2026-03-06T08:11:10", [DateTimeKind]::Utc).AddSeconds($j * 13)).ToString("o")
            eventSource = "s3.amazonaws.com"
            eventName = "GetObject"
            awsRegion = "ap-south-1"
            sourceIPAddress = "185.199.110.42"
            userAgent = "curl/8.5.0"
            requestParameters = [ordered]@{
                bucketName = $bucketName
                key = if (($j % 2) -eq 0) { "patients/2026/03/patient_master_export.csv" } else { "finance/2026/insurance_claims_q1.xlsx" }
            }
            additionalEventData = [ordered]@{
                AuthenticationMethod = "QueryString"
                SignatureVersion = "SigV4"
            }
            responseElements = [ordered]@{
                xAmzRequestId = ("ANONGET{0:D3}" -f $j)
            }
            readOnly = $true
            managementEvent = $false
            eventType = "AwsApiCall"
            recipientAccountId = "123456789012"
        })
    }

    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $lines = $events | ForEach-Object { $_ | ConvertTo-Json -Depth 10 -Compress }
    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-01 Public Bucket Exposure (Real-World Investigation Pack)

Scenario:
The SOC observed policy drift on a production S3 bucket used by a healthcare diagnostics workflow.
The case pack contains mixed telemetry from cloud control-plane logs, data-plane access logs,
compliance findings, and analyst handoff notes.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4418
Severity: High
Queue: Cloud Security Monitoring
Analyst: Tier-1 SOC (handoff to IR)

Summary:
AWS Config and Security Hub generated alerts that an S3 bucket holding diagnostic center data became publicly readable.
Shortly after, access-log telemetry shows bulk object retrieval from an external IP with anonymous requester context.

Scope:
- Account: 123456789012
- Region: ap-south-1
- Bucket: medvault-diagnostic-prod
- Suspected window: 2026-03-06 08:08 UTC to 08:20 UTC

Deliverable:
Classify the primary CIA impact based on evidence.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$triageNotes = @'
Triage notes:
- External scanner traffic also exists in the same window and may create false positives.
- Focus on successful object reads and policy state transitions.
- Sensitive objects are tagged in inventory as restricted data classes.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\triage_notes.txt") -Content $triageNotes

$inventory = @'
object_key,data_classification,data_owner,last_modified_utc,size_bytes
public/pricing-sheet.pdf,public,marketing,2026-03-05T02:11:12Z,42881
reports/daily/appointments_summary_2026-03-05.csv,internal,operations,2026-03-05T23:59:01Z,81222
reports/daily/billing_summary_2026-03-05.csv,internal,finance,2026-03-05T23:59:08Z,93684
patients/2026/03/patient_master_export.csv,restricted_pii,clinical-data,2026-03-06T00:03:11Z,1862001
patients/2026/03/lab_results_dump.csv,restricted_phi,clinical-data,2026-03-06T00:03:14Z,2299310
patients/2026/03/referral_contacts.csv,restricted_pii,partner-ops,2026-03-06T00:03:18Z,922114
finance/2026/insurance_claims_q1.xlsx,restricted_financial,finance,2026-03-06T00:03:25Z,680114
finance/2026/payout_beneficiary_list.csv,restricted_financial,finance,2026-03-06T00:03:27Z,402901
site-assets/logo.png,public,web-team,2026-02-27T14:20:00Z,12093
site-assets/banner-march.jpg,public,web-team,2026-03-01T05:33:00Z,488120
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\s3\object_inventory.csv") -Content $inventory

$policyBefore = @'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowInternalReadOnly",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:role/etl-reporting",
          "arn:aws:iam::123456789012:role/security-audit-role"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::medvault-diagnostic-prod",
        "arn:aws:s3:::medvault-diagnostic-prod/*"
      ]
    }
  ]
}
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\s3\bucket_policy_before.json") -Content $policyBefore

$policyAfter = @'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowInternalReadOnly",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:role/etl-reporting",
          "arn:aws:iam::123456789012:role/security-audit-role"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::medvault-diagnostic-prod",
        "arn:aws:s3:::medvault-diagnostic-prod/*"
      ]
    },
    {
      "Sid": "TempPublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::medvault-diagnostic-prod/*"
    }
  ]
}
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\s3\bucket_policy_after.json") -Content $policyAfter

$publicAccessBlock = @'
{
  "before": {
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  },
  "after": {
    "BlockPublicAcls": false,
    "IgnorePublicAcls": false,
    "BlockPublicPolicy": false,
    "RestrictPublicBuckets": false
  }
}
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\s3\public_access_block_diff.json") -Content $publicAccessBlock

$configFindings = @'
{
  "configRuleName": "s3-bucket-public-read-prohibited",
  "evaluations": [
    {
      "resourceType": "AWS::S3::Bucket",
      "resourceId": "medvault-diagnostic-prod",
      "complianceType": "NON_COMPLIANT",
      "annotation": "Bucket policy allows public read access for one or more objects.",
      "orderingTimestamp": "2026-03-06T08:10:16Z"
    },
    {
      "resourceType": "AWS::S3::Bucket",
      "resourceId": "medvault-static-assets",
      "complianceType": "COMPLIANT",
      "annotation": "No public read statements found.",
      "orderingTimestamp": "2026-03-06T08:10:16Z"
    }
  ]
}
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\config\aws_config_rule_evaluations.json") -Content $configFindings

$securityHub = @'
{
  "SchemaVersion": "2018-10-08",
  "Id": "arn:aws:securityhub:ap-south-1:123456789012:subscription/aws-foundational-security-best-practices/v/1.0.0/S3.8/finding/44f5fca3-81f0-47cf-a853-a3f05f2f3f01",
  "ProductArn": "arn:aws:securityhub:ap-south-1::product/aws/securityhub",
  "GeneratorId": "security-control/S3.8",
  "AwsAccountId": "123456789012",
  "Types": [
    "Software and Configuration Checks/AWS Security Best Practices"
  ],
  "CreatedAt": "2026-03-06T08:10:20Z",
  "UpdatedAt": "2026-03-06T08:10:20Z",
  "Severity": {
    "Label": "HIGH"
  },
  "Title": "S3 bucket should prohibit public read access",
  "Description": "Bucket medvault-diagnostic-prod allows public read access.",
  "Resources": [
    {
      "Type": "AwsS3Bucket",
      "Id": "arn:aws:s3:::medvault-diagnostic-prod",
      "Region": "ap-south-1"
    }
  ]
}
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\findings\security_hub_finding.json") -Content $securityHub

$accessAnalyzer = @'
{
  "id": "f3cf7d66-8c86-4ec2-b4ec-c9f07bdab0c9",
  "principal": {
    "AWS": "*"
  },
  "resource": "arn:aws:s3:::medvault-diagnostic-prod",
  "isPublic": true,
  "action": [
    "s3:GetObject"
  ],
  "condition": {},
  "status": "ACTIVE",
  "createdAt": "2026-03-06T08:10:18Z",
  "updatedAt": "2026-03-06T08:10:18Z"
}
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\findings\access_analyzer_finding.json") -Content $accessAnalyzer

New-M1PublicBucketCloudTrailEvents -OutputPath (Join-Path $bundleRoot "evidence\cloudtrail\cloudtrail_events.jsonl")
New-M1PublicBucketS3AccessLog -OutputPath (Join-Path $bundleRoot "evidence\logs\s3_server_access.log")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
