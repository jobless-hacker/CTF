param()

$ErrorActionPreference = "Stop"

$bundleName = "m8-08-misconfigured-storage-policy"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m8_08_realworld_build"
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

function New-BucketPolicyVersions {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $buckets = @("corp-assets","corp-logs","corp-analytics","corp-static")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $bucket = $buckets[$i % $buckets.Count]
        $ver = "pol-" + ("{0:D8}" -f (73300000 + $i))
        $lines.Add("$ts policy-version bucket=$bucket version=$ver principal=internal-role action=s3:GetObject status=safe")
    }

    $lines.Add("2026-03-08T19:42:11Z policy-version bucket=corp-static version=pol-73389999 principal=* action=s3:GetObject status=violation risky_policy_value=* note=wildcard_principal_exposure")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PolicySimulationCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,bucket,principal,action,resource,decision,risk")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $lines.Add("$ts,corp-static,internal-role,s3:GetObject,arn:aws:s3:::corp-static/*,allow,low")
    }

    $lines.Add("2026-03-08T19:42:12Z,corp-static,*,s3:GetObject,arn:aws:s3:::corp-static/*,allow,critical")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudTrailEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $events = @("GetBucketPolicy","ListBuckets","GetBucketAcl")

    for ($i = 0; $i -lt 5400; $i++) {
        $entry = [ordered]@{
            eventTime = $base.AddSeconds($i * 7).ToString("o")
            eventSource = "s3.amazonaws.com"
            eventName = $events[$i % $events.Count]
            awsRegion = "ap-south-1"
            sourceIPAddress = "10.60.4." + (($i % 200) + 10)
            userIdentity = [ordered]@{
                type = "AssumedRole"
                principalId = "AROAXXXXX:cloud-audit"
            }
            readOnly = $true
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        eventTime = "2026-03-08T19:42:13Z"
        eventSource = "s3.amazonaws.com"
        eventName = "PutBucketPolicy"
        awsRegion = "ap-south-1"
        sourceIPAddress = "185.90.14.52"
        userIdentity = [ordered]@{
            type = "IAMUser"
            userName = "ops-temp-admin"
        }
        requestParameters = [ordered]@{
            bucketName = "corp-static"
            principal = "*"
            action = "s3:GetObject"
        }
        additionalEventData = [ordered]@{
            riskyPolicyValue = "*"
            publicRead = $true
        }
        readOnly = $false
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ObjectAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $objects = @("logo.svg","index.html","manual.pdf","catalog.csv")
    $ips = @("10.0.2.10","10.0.2.22","10.0.2.34","10.0.2.46")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $obj = $objects[$i % $objects.Count]
        $ip = $ips[$i % $ips.Count]
        $lines.Add("$ts object-access bucket=corp-static object=$obj src_ip=$ip auth=iam-role status=200")
    }

    $lines.Add("2026-03-08T19:42:14Z object-access bucket=corp-static object=manual.pdf src_ip=185.90.14.52 auth=anonymous status=200 policy_principal=* note=public_policy_access")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PolicyAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $lines.Add("$ts policy-audit control=no-wildcard-principal status=pass bucket=corp-static")
    }

    $lines.Add("2026-03-08T19:42:15Z policy-audit control=no-wildcard-principal status=violation bucket=corp-static risky_policy_value=* reason=principal_wildcard")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("bucket-policy-watch","wildcard-principal-watch","public-access-watch","policy-risk-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "pol-" + ("{0:D8}" -f (84600000 + $i))
            severity = if (($i % 197) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine storage policy posture monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T19:42:16Z"
        alert_id = "pol-84659999"
        severity = "critical"
        type = "misconfigured_storage_policy_detected"
        status = "open"
        bucket = "corp-static"
        risky_policy_value = "*"
        detail = "bucket policy grants public object access through wildcard principal"
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
        $evt = if (($i % 251) -eq 0) { "storage-policy-review" } else { "normal-cloud-monitoring" }
        $sev = if ($evt -eq "storage-policy-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cloud-08,$sev,bucket policy baseline telemetry")
    }

    $lines.Add("2026-03-08T19:42:17Z,misconfigured_policy_confirmed,siem-cloud-08,high,correlated policy/cloudtrail/access/audit evidence confirms risky storage policy")
    $lines.Add("2026-03-08T19:42:20Z,risky_policy_value_identified,siem-cloud-08,critical,risky storage policy value identified as *")
    $lines.Add("2026-03-08T19:42:28Z,incident_opened,siem-cloud-08,high,INC-2026-5808 misconfigured storage policy investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BucketPolicyJson {
    param([string]$OutputPath)

    $content = @'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::corp-static/*"
    }
  ]
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Storage Policy Hardening Standard (Excerpt)

1) Bucket policy principals must never use wildcard values for sensitive/public buckets.
2) Public access must be explicitly denied unless formally approved and scoped.
3) SOC/CloudSec must identify and report risky policy values from evidence.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Misconfigured Storage Policy Triage Runbook (Excerpt)

1) Correlate bucket policy versions, raw policy artifact, and CloudTrail changes.
2) Validate policy impact via object access logs and policy audits.
3) Confirm normalized risky value in alerts and SIEM timeline.
4) Submit risky policy value.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed cloud breach pattern: wildcard principals in object storage policies.
Most abused risky policy value in this campaign: *
Current incident normalized risky policy value: *
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M8-08 Misconfigured Storage Policy (Real-World Investigation Pack)

Scenario:
Cloud storage policy controls indicate a bucket policy may be using a dangerous wildcard value.

Task:
Analyze the investigation pack and identify the risky policy value.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5808
Severity: High
Queue: SOC + CloudSec

Summary:
Potential misconfigured storage policy exposing bucket data publicly.

Scope:
- Bucket: corp-static
- Objective: identify risky policy value
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate bucket policy versions, policy simulation, CloudTrail policy changes, object access logs, policy audit logs, security alerts, SIEM timeline, and policy/runbook context.
- Determine the risky policy value.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-BucketPolicyVersions -OutputPath (Join-Path $bundleRoot "evidence\cloud\bucket_policy_versions.log")
New-PolicySimulationCsv -OutputPath (Join-Path $bundleRoot "evidence\cloud\policy_simulation.csv")
New-CloudTrailEvents -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloudtrail_events.jsonl")
New-ObjectAccessLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\object_access.log")
New-PolicyAuditLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\policy_audit.log")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\storage_policy_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-BucketPolicyJson -OutputPath (Join-Path $bundleRoot "evidence\cloud\bucket_policy.json")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\storage_policy_hardening_standard.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\misconfigured_storage_policy_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
