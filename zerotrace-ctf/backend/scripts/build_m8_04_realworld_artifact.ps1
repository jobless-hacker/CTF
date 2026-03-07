param()

$ErrorActionPreference = "Stop"

$bundleName = "m8-04-overprivileged-iam-role"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m8_04_realworld_build"
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

function New-IamRoleInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $roles = @("app-read-role","reporting-role","support-role","ops-audit-role","batch-runner-role")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $role = $roles[$i % $roles.Count]
        $lines.Add("$ts iam-role-inventory role=$role account=prod permission_profile=least-privilege status=ok")
    }

    $lines.Add("2026-03-08T17:12:11Z iam-role-inventory role=migration-admin-role account=prod permission_profile=overprivileged status=violation dangerous_permission=* note=wildcard_action_detected")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IamPolicyDocuments {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 6).ToString("o")
            role = "app-read-role"
            policy = [ordered]@{
                Effect = "Allow"
                Action = @("s3:GetObject", "s3:ListBucket")
                Resource = @("arn:aws:s3:::corp-data/*")
            }
            risk = "low"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T17:12:12Z"
        role = "migration-admin-role"
        policy = [ordered]@{
            Effect = "Allow"
            Action = "*"
            Resource = "*"
        }
        risk = "critical"
        dangerous_permission = "*"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AccessAdvisorCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,role,service,last_access_days,used_actions,recommended_actions,risk")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("s3","ec2","cloudwatch","rds","kms")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $svc = $services[$i % $services.Count]
        $days = ($i % 60) + 1
        $lines.Add("$ts,app-read-role,$svc,$days,read-only,read-only,low")
    }

    $lines.Add("2026-03-08T17:12:13Z,migration-admin-role,iam,1,all-actions,scoped-actions,critical")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IamSimulatorLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $actions = @("s3:GetObject","ec2:DescribeInstances","cloudwatch:GetMetricData","rds:DescribeDBInstances")

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $a = $actions[$i % $actions.Count]
        $lines.Add("$ts iam-simulator role=app-read-role simulated_action=$a decision=allowed reason=policy_match")
    }

    $lines.Add("2026-03-08T17:12:14Z iam-simulator role=migration-admin-role simulated_action=iam:DeleteRole decision=allowed reason=wildcard_action dangerous_permission=*")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("iam-policy-watch","wildcard-action-watch","least-privilege-watch","role-risk-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "iam-" + ("{0:D8}" -f (99600000 + $i))
            severity = if (($i % 191) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine iam posture monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T17:12:15Z"
        alert_id = "iam-99659999"
        severity = "critical"
        type = "overprivileged_iam_role_detected"
        status = "open"
        role = "migration-admin-role"
        dangerous_permission = "*"
        detail = "role policy includes wildcard action with full resource scope"
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
        $evt = if (($i % 251) -eq 0) { "iam-least-privilege-review" } else { "normal-cloud-monitoring" }
        $sev = if ($evt -eq "iam-least-privilege-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cloud-04,$sev,iam policy hygiene baseline telemetry")
    }

    $lines.Add("2026-03-08T17:12:16Z,overprivileged_role_confirmed,siem-cloud-04,high,correlated policy/simulator/alert evidence confirms overprivileged role")
    $lines.Add("2026-03-08T17:12:19Z,dangerous_permission_identified,siem-cloud-04,critical,dangerous permission value identified as *")
    $lines.Add("2026-03-08T17:12:25Z,incident_opened,siem-cloud-04,high,INC-2026-5804 overprivileged iam role investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IamPolicyJson {
    param([string]$OutputPath)

    $content = @'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
IAM Least Privilege Policy (Excerpt)

1) IAM roles must avoid wildcard actions unless explicitly approved and time-bound.
2) Role permissions must be scoped to required services/resources only.
3) SOC/CloudSec must identify and report dangerous permission values.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Overprivileged IAM Role Triage Runbook (Excerpt)

1) Pivot role-risk findings across inventory and policy document sources.
2) Validate dangerous permission values with simulator outcomes.
3) Confirm security alert and SIEM normalization output.
4) Submit dangerous permission value for remediation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed cloud abuse pattern: wildcard action permissions in production IAM roles.
Most risky permission value in this campaign: *
Current incident normalized dangerous permission: *
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M8-04 Overprivileged IAM Role (Real-World Investigation Pack)

Scenario:
Cloud IAM posture monitoring indicates a production role may include dangerously broad permissions.

Task:
Analyze the investigation pack and identify the dangerous permission value.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5804
Severity: High
Queue: SOC + CloudSec

Summary:
Potential overprivileged IAM role detected in production account.

Scope:
- Role: migration-admin-role
- Objective: identify dangerous permission value
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate IAM role inventory, policy documents, access advisor data, IAM simulator logs, security alerts, SIEM timeline, and policy/runbook context.
- Determine the dangerous permission value.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-IamRoleInventory -OutputPath (Join-Path $bundleRoot "evidence\cloud\iam_role_inventory.log")
New-IamPolicyDocuments -OutputPath (Join-Path $bundleRoot "evidence\cloud\iam_policy_documents.jsonl")
New-AccessAdvisorCsv -OutputPath (Join-Path $bundleRoot "evidence\cloud\access_advisor.csv")
New-IamSimulatorLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\iam_simulator.log")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\iam_risk_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-IamPolicyJson -OutputPath (Join-Path $bundleRoot "evidence\cloud\iam_policy.json")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\iam_least_privilege_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\overprivileged_iam_role_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
