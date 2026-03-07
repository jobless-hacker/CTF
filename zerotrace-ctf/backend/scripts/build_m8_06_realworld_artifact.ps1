param()

$ErrorActionPreference = "Stop"

$bundleName = "m8-06-suspicious-cloudtrail-event"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m8_06_realworld_build"
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
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $events = @("ConsoleLogin","DescribeInstances","ListBuckets","GetCallerIdentity")

    for ($i = 0; $i -lt 7100; $i++) {
        $entry = [ordered]@{
            eventTime = $base.AddSeconds($i * 5).ToString("o")
            eventSource = "signin.amazonaws.com"
            eventName = $events[$i % $events.Count]
            awsRegion = "ap-south-1"
            sourceIPAddress = "10.40.8." + (($i % 200) + 10)
            userIdentity = [ordered]@{
                type = "IAMUser"
                userName = "ops-readonly"
            }
            responseElements = [ordered]@{
                ConsoleLogin = "Success"
            }
            additionalEventData = [ordered]@{
                MFAUsed = "Yes"
                LoginTo = "https://console.aws.amazon.com/"
            }
            readOnly = $true
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        eventTime = "2026-03-08T18:33:44Z"
        eventSource = "signin.amazonaws.com"
        eventName = "ConsoleLogin"
        awsRegion = "ap-south-1"
        sourceIPAddress = "185.22.33.41"
        userIdentity = [ordered]@{
            type = "IAMUser"
            userName = "ops-admin"
        }
        responseElements = [ordered]@{
            ConsoleLogin = "Success"
        }
        additionalEventData = [ordered]@{
            MFAUsed = "No"
            LoginTo = "https://console.aws.amazon.com/"
        }
        readOnly = $false
        suspiciousLogin = $true
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ConsoleLoginAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.72.12.44","49.205.23.18","125.16.45.90","110.227.10.34")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $lines.Add("$ts console-login user=ops-readonly src_ip=$ip mfa=Yes result=Success risk=low")
    }

    $lines.Add("2026-03-08T18:33:45Z console-login user=ops-admin src_ip=185.22.33.41 mfa=No result=Success risk=critical note=anomalous_external_login")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GeoIpEnrichment {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source_ip,country,asn,known_org,reputation,category")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $lines.Add("$ts,10.40.8.$(($i % 200) + 10),Private,N/A,Internal,benign,internal")
    }

    $lines.Add("2026-03-08T18:33:46Z,185.22.33.41,RU,AS48282,Unknown-Hosting,high,external_suspicious")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GuardDutyFindings {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("Recon:EC2/PortProbeUnprotectedPort","UnauthorizedAccess:IAMUser/ConsoleLogin","Stealth:IAMUser/CloudTrailLoggingDisabled")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            finding_id = "gd-" + ("{0:D8}" -f (61000000 + $i))
            type = $types[$i % $types.Count]
            severity = if (($i % 173) -eq 0) { "medium" } else { "low" }
            status = "archived"
            resource = "iam-user/ops-readonly"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T18:33:47Z"
        finding_id = "gd-61059999"
        type = "UnauthorizedAccess:IAMUser/ConsoleLogin"
        severity = "high"
        status = "active"
        resource = "iam-user/ops-admin"
        source_ip = "185.22.33.41"
        detail = "suspicious successful console login from unusual external source without MFA"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-MfaPolicyAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $lines.Add("$ts mfa-audit user=ops-readonly policy=console-login-mfa-required status=pass")
    }

    $lines.Add("2026-03-08T18:33:48Z mfa-audit user=ops-admin policy=console-login-mfa-required status=violation source_ip=185.22.33.41 reason=mfa_not_used")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 251) -eq 0) { "console-login-review" } else { "normal-cloud-monitoring" }
        $sev = if ($evt -eq "console-login-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cloud-06,$sev,console login baseline telemetry")
    }

    $lines.Add("2026-03-08T18:33:49Z,suspicious_console_login_confirmed,siem-cloud-06,high,correlated cloudtrail/login/geoip/guardduty evidence confirms suspicious login source")
    $lines.Add("2026-03-08T18:33:52Z,suspicious_ip_identified,siem-cloud-06,critical,suspicious login source IP identified as 185.22.33.41")
    $lines.Add("2026-03-08T18:34:00Z,incident_opened,siem-cloud-06,high,INC-2026-5806 suspicious cloudtrail event investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudTrailJson {
    param([string]$OutputPath)

    $content = @'
{
  "eventName": "ConsoleLogin",
  "sourceIPAddress": "185.22.33.41",
  "userIdentity": {
    "type": "IAMUser",
    "userName": "ops-admin"
  },
  "additionalEventData": {
    "MFAUsed": "No"
  }
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Cloud Console Access Monitoring Policy (Excerpt)

1) Successful console logins from unusual external IPs must be investigated immediately.
2) MFA absence on privileged IAM console login is a critical violation.
3) SOC/CloudSec must identify and report suspicious source IPs from CloudTrail evidence.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Suspicious CloudTrail Event Triage Runbook (Excerpt)

1) Pivot login events in CloudTrail and console audit logs.
2) Enrich source IP through GeoIP and threat detections.
3) Validate MFA policy violations and SIEM normalization output.
4) Submit suspicious source IP address.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed cloud abuse pattern: successful IAM console logins from unfamiliar external hosting ranges.
Current incident suspicious external source IP: 185.22.33.41
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M8-06 Suspicious CloudTrail Event (Real-World Investigation Pack)

Scenario:
Cloud audit telemetry indicates an unusual successful console login from an external source.

Task:
Analyze the investigation pack and identify the suspicious IP address.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5806
Severity: High
Queue: SOC + CloudSec

Summary:
Potential unauthorized cloud console access detected from external source.

Scope:
- Event source: CloudTrail ConsoleLogin
- Objective: identify suspicious source IP
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate CloudTrail events, console login audit, GeoIP enrichment, GuardDuty findings, MFA policy audits, SIEM timeline, and policy/runbook context.
- Determine the suspicious source IP address.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-CloudTrailEvents -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloudtrail_events.jsonl")
New-ConsoleLoginAudit -OutputPath (Join-Path $bundleRoot "evidence\cloud\console_login_audit.log")
New-GeoIpEnrichment -OutputPath (Join-Path $bundleRoot "evidence\cloud\geoip_enrichment.csv")
New-GuardDutyFindings -OutputPath (Join-Path $bundleRoot "evidence\security\guardduty_findings.jsonl")
New-MfaPolicyAudit -OutputPath (Join-Path $bundleRoot "evidence\cloud\mfa_policy_audit.log")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CloudTrailJson -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloudtrail.json")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\cloud_console_access_monitoring_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\suspicious_cloudtrail_event_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
