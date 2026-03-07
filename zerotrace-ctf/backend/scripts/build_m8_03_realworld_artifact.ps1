param()

$ErrorActionPreference = "Stop"

$bundleName = "m8-03-public-database-snapshot"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m8_03_realworld_build"
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

function New-SnapshotInventoryLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $snaps = @("orders-snap-20260307","users-snap-20260307","audit-snap-20260307","metrics-snap-20260307","temp-snap-20260307")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $s = $snaps[$i % $snaps.Count]
        $engine = if (($i % 2) -eq 0) { "postgres" } else { "mysql" }
        $size = 1200 + (($i * 41) % 18000000)
        $lines.Add("$ts snapshot-inventory region=ap-south-1 snapshot=$s engine=$engine size_mb=$size visibility=private")
    }

    $lines.Add("2026-03-08T16:40:11Z snapshot-inventory region=ap-south-1 snapshot=db-backup engine=postgres size_mb=8450 visibility=public note=sensitive_snapshot_exposed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RdsApiLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $actions = @("DescribeDBSnapshots","CopyDBSnapshot","ModifyDBSnapshotAttribute","DescribeDBInstances")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $req = "req-" + ("{0:D8}" -f (65000000 + $i))
        $act = $actions[$i % $actions.Count]
        $lines.Add("$ts rds-api request_id=$req action=$act snapshot=orders-snap-20260307 source_ip=10.20.4.$(($i % 200) + 10) status=success")
    }

    $lines.Add("2026-03-08T16:40:12Z rds-api request_id=req-65077777 action=ModifyDBSnapshotAttribute snapshot=db-backup attribute=restore value=all source_ip=185.247.11.60 status=success note=public_restore_enabled")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudTrailLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $events = @("DescribeDBSnapshots","DescribeDBInstances","ListTagsForResource")

    for ($i = 0; $i -lt 5400; $i++) {
        $entry = [ordered]@{
            eventTime = $base.AddSeconds($i * 7).ToString("o")
            eventSource = "rds.amazonaws.com"
            eventName = $events[$i % $events.Count]
            awsRegion = "ap-south-1"
            sourceIPAddress = "10.21.7." + (($i % 200) + 10)
            userIdentity = [ordered]@{
                type = "AssumedRole"
                principalId = "AROAXXXXX:rds-maint"
            }
            requestParameters = [ordered]@{
                dBSnapshotIdentifier = "orders-snap-20260307"
            }
            readOnly = $true
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        eventTime = "2026-03-08T16:40:13Z"
        eventSource = "rds.amazonaws.com"
        eventName = "ModifyDBSnapshotAttribute"
        awsRegion = "ap-south-1"
        sourceIPAddress = "185.247.11.60"
        userIdentity = [ordered]@{
            type = "IAMUser"
            userName = "ops-migrator"
        }
        requestParameters = [ordered]@{
            dBSnapshotIdentifier = "db-backup"
            attributeName = "restore"
            valuesToAdd = @("all")
        }
        additionalEventData = [ordered]@{
            publicSnapshot = $true
            exposedSnapshot = "db-backup"
        }
        readOnly = $false
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SnapshotPolicyAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $lines.Add("$ts snapshot-policy-audit control=no-public-restore status=pass snapshot=orders-snap-20260307 principal=internal-only")
    }

    $lines.Add("2026-03-08T16:40:14Z snapshot-policy-audit control=no-public-restore status=violation snapshot=db-backup principal=all reason=restore_attribute_public")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("rds-snapshot-watch","cloud-policy-watch","public-restore-watch","asset-exposure-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "rds-" + ("{0:D8}" -f (99300000 + $i))
            severity = if (($i % 181) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine snapshot exposure monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T16:40:15Z"
        alert_id = "rds-99359999"
        severity = "critical"
        type = "public_snapshot_exposure"
        status = "open"
        snapshot_id = "db-backup"
        detail = "database snapshot allows public restore permissions"
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
        $evt = if (($i % 251) -eq 0) { "snapshot-permission-review" } else { "normal-cloud-monitoring" }
        $sev = if ($evt -eq "snapshot-permission-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cloud-03,$sev,rds snapshot exposure baseline telemetry")
    }

    $lines.Add("2026-03-08T16:40:16Z,public_snapshot_confirmed,siem-cloud-03,high,correlated inventory/api/cloudtrail/policy evidence confirms public snapshot")
    $lines.Add("2026-03-08T16:40:19Z,exposed_resource_identified,siem-cloud-03,critical,exposed snapshot resource identified as db-backup")
    $lines.Add("2026-03-08T16:40:26Z,incident_opened,siem-cloud-03,high,INC-2026-5803 public database snapshot exposure investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SnapshotJson {
    param([string]$OutputPath)

    $content = @'
{
  "snapshot_id": "db-backup",
  "engine": "postgres",
  "public": true,
  "region": "ap-south-1",
  "created_at": "2026-03-08T15:10:00Z"
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Database Snapshot Exposure Policy (Excerpt)

1) Database snapshots containing production data must not allow public restore.
2) Snapshot permissions must be restricted to approved internal principals only.
3) SOC/CloudSec must identify and report the exposed snapshot resource ID.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Public Snapshot Exposure Triage Runbook (Excerpt)

1) Validate suspected snapshot ID in inventory and direct metadata artifacts.
2) Correlate API and CloudTrail events for permission-change operations.
3) Confirm policy audit violation and alert/SIEM normalization.
4) Submit exposed snapshot resource identifier.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed cloud breach pattern: public restore enabled on DB snapshots.
Common exposed snapshot naming pattern: db-backup
Current incident normalized exposed snapshot resource: db-backup
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M8-03 Public Database Snapshot (Real-World Investigation Pack)

Scenario:
Cloud controls indicate a database snapshot may be exposed with public restore permissions.

Task:
Analyze the investigation pack and identify the exposed resource.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5803
Severity: High
Queue: SOC + CloudSec

Summary:
Potential public exposure of production database snapshot permissions.

Scope:
- Service: RDS snapshots
- Objective: identify exposed snapshot resource ID
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate snapshot inventory, API logs, CloudTrail events, policy audit logs, security alerts, SIEM timeline, and policy/runbook context.
- Determine the exposed snapshot resource ID.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-SnapshotInventoryLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\snapshot_inventory.log")
New-RdsApiLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\rds_api.log")
New-CloudTrailLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloudtrail_events.jsonl")
New-SnapshotPolicyAudit -OutputPath (Join-Path $bundleRoot "evidence\cloud\snapshot_policy_audit.log")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\public_snapshot_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-SnapshotJson -OutputPath (Join-Path $bundleRoot "evidence\cloud\snapshot.json")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\database_snapshot_exposure_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\public_snapshot_exposure_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
