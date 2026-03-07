param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-11-aws-public-snapshot"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_11_realworld_build"
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

function Write-LinesFile {
    param(
        [string]$Path,
        [System.Collections.Generic.List[string]]$Lines
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    [System.IO.File]::WriteAllLines($Path, $Lines, [System.Text.Encoding]::UTF8)
}

function New-SnapshotInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,account_id,region,snapshot_id,db_instance,engine,snapshot_type,kms_key,sharing_mode,owner_team")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)
    $regions = @("ap-south-1","eu-west-1","us-east-1")
    $engines = @("postgres","mysql","aurora-postgresql")
    $teams = @("billing","support","analytics","growth","security")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddMinutes($i * 6).ToString("o")
        $region = $regions[$i % $regions.Count]
        $engine = $engines[$i % $engines.Count]
        $team = $teams[$i % $teams.Count]
        $snap = "snap-$team-$($region.Replace('-',''))-$((18000 + $i))"
        $db = "$team-db-$((50 + ($i % 300)))"
        $sharing = if (($i % 21) -eq 0) { "shared-account" } else { "private" }
        $lines.Add("$ts,111122223333,$region,$snap,$db,$engine,automated,arn:aws:kms:$region:111122223333:key/$(1000 + ($i % 500)),$sharing,$team")
    }

    $lines.Add("2026-03-05T23:00:02Z,111122223333,ap-south-1,customer-db-backup-2026-03-05,customer-db-prod,postgres,manual,arn:aws:kms:ap-south-1:111122223333:key/9213,private,customer-platform")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudTrailEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T22:00:00", [DateTimeKind]::Utc)
    $users = @("ops-admin","db-automation-role","backup-bot","platform-deployer","audit-sync")
    $sourceIps = @("10.22.8.11","10.22.8.19","10.22.8.35","10.22.9.7","10.22.9.19")

    for ($i = 0; $i -lt 8600; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $u = $users[$i % $users.Count]
        $ip = $sourceIps[$i % $sourceIps.Count]
        $eventName = if (($i % 9) -eq 0) { "DescribeDBSnapshots" } elseif (($i % 17) -eq 0) { "ModifyDBSnapshotAttribute" } else { "ListTagsForResource" }
        $snapshot = if (($i % 11) -eq 0) { "staging-db-backup-2026-03-05" } else { "customer-db-backup-2026-03-04" }
        $valuesToAdd = if ($eventName -eq "ModifyDBSnapshotAttribute" -and ($i % 34) -eq 0) { @("222233334444") } else { @() }

        $entry = [ordered]@{
            eventVersion = "1.11"
            userIdentity = [ordered]@{
                type = "IAMUser"
                userName = $u
                accountId = "111122223333"
            }
            eventTime = $ts
            eventSource = "rds.amazonaws.com"
            eventName = $eventName
            awsRegion = "ap-south-1"
            sourceIPAddress = $ip
            userAgent = "aws-cli/2.15.11 Python/3.11"
            requestParameters = [ordered]@{
                dBSnapshotIdentifier = $snapshot
                attributeName = if ($eventName -eq "ModifyDBSnapshotAttribute") { "restore" } else { "" }
                valuesToAdd = $valuesToAdd
            }
            responseElements = [ordered]@{
                requestId = "req-$((700000 + $i))"
            }
            eventType = "AwsApiCall"
            eventCategory = "Management"
        }
        $lines.Add(($entry | ConvertTo-Json -Depth 8 -Compress))
    }

    # False positive: public shared test snapshot in sandbox account (closed)
    $falsePositive = [ordered]@{
        eventVersion = "1.11"
        userIdentity = [ordered]@{
            type = "IAMUser"
            userName = "qa-lab-user"
            accountId = "111122223333"
        }
        eventTime = "2026-03-06T04:10:00Z"
        eventSource = "rds.amazonaws.com"
        eventName = "ModifyDBSnapshotAttribute"
        awsRegion = "ap-south-1"
        sourceIPAddress = "10.22.8.88"
        userAgent = "aws-cli/2.15.11 Python/3.11"
        requestParameters = [ordered]@{
            dBSnapshotIdentifier = "sandbox-redteam-test-2026-03-06"
            attributeName = "restore"
            valuesToAdd = @("all")
        }
        responseElements = [ordered]@{
            requestId = "req-fp-001"
        }
        eventType = "AwsApiCall"
        eventCategory = "Management"
    }
    $lines.Add(($falsePositive | ConvertTo-Json -Depth 8 -Compress))

    # Incident event
    $incident = [ordered]@{
        eventVersion = "1.11"
        userIdentity = [ordered]@{
            type = "IAMUser"
            userName = "ops-admin"
            accountId = "111122223333"
        }
        eventTime = "2026-03-06T05:14:11Z"
        eventSource = "rds.amazonaws.com"
        eventName = "ModifyDBSnapshotAttribute"
        awsRegion = "ap-south-1"
        sourceIPAddress = "10.22.8.19"
        userAgent = "aws-cli/2.15.11 Python/3.11"
        requestParameters = [ordered]@{
            dBSnapshotIdentifier = "customer-db-backup-2026-03-05"
            attributeName = "restore"
            valuesToAdd = @("all")
        }
        responseElements = [ordered]@{
            requestId = "req-incident-011"
        }
        eventType = "AwsApiCall"
        eventCategory = "Management"
    }
    $lines.Add(($incident | ConvertTo-Json -Depth 8 -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SnapshotAttributeHistory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,snapshot_id,attribute,values_before,values_after,changed_by,change_type,ticket_ref")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-04T00:00:00", [DateTimeKind]::Utc)
    $users = @("backup-bot","db-automation-role","ops-admin","platform-deployer")

    for ($i = 0; $i -lt 7200; $i++) {
        $ts = $base.AddMinutes($i * 5).ToString("o")
        $snap = if (($i % 13) -eq 0) { "staging-db-backup-2026-03-05" } else { "customer-db-backup-2026-03-04" }
        $before = "[]"
        $after = if (($i % 41) -eq 0) { "[""222233334444""]" } else { "[]"}
        $by = $users[$i % $users.Count]
        $ctype = if ($after -eq "[]") { "no-change" } else { "share-approved-account" }
        $ticket = if ($ctype -eq "share-approved-account") { "CHG-$((5000 + ($i % 700)))" } else { "" }
        $lines.Add("$ts,$snap,restore,""$before"",""$after"",$by,$ctype,$ticket")
    }

    # Incident change
    $lines.Add("2026-03-06T05:14:11Z,customer-db-backup-2026-03-05,restore,""[]"",""[""all""]"",ops-admin,public-share,")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GovernanceFindings {
    param(
        [string]$CsvPath,
        [string]$JsonlPath
    )

    $csv = New-Object System.Collections.Generic.List[string]
    $csv.Add("timestamp_utc,control_id,severity,resource,status,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T18:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6300; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $status = if (($i % 14) -eq 0) { "closed_false_positive" } else { "informational" }
        $note = if ($status -eq "closed_false_positive") { "sandbox snapshot intentionally public for tabletop exercise" } else { "baseline compliant" }
        $csv.Add("$ts,RDS-SNAPSHOT-SHARING-01,25,staging-db-backup-2026-03-05,$status,$note")
    }
    $csv.Add("2026-03-06T05:14:20Z,RDS-SNAPSHOT-SHARING-01,95,customer-db-backup-2026-03-05,open,restore attribute includes 'all' on production snapshot")
    Write-LinesFile -Path $CsvPath -Lines $csv

    $jsonl = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt 4100; $i++) {
        $entry = [ordered]@{
            id = "finding-$((310000 + $i))"
            timestamp = $base.AddSeconds($i * 13).ToString("o")
            service = "access-analyzer"
            resourceType = "AWS::RDS::DBSnapshot"
            resource = "staging-db-backup-2026-03-05"
            status = if (($i % 10) -eq 0) { "ARCHIVED" } else { "RESOLVED" }
            isPublic = $true
            note = "sandbox workload scope"
        }
        $jsonl.Add(($entry | ConvertTo-Json -Depth 6 -Compress))
    }
    $incidentFinding = [ordered]@{
        id = "finding-incident-4401"
        timestamp = "2026-03-06T05:14:23Z"
        service = "access-analyzer"
        resourceType = "AWS::RDS::DBSnapshot"
        resource = "customer-db-backup-2026-03-05"
        status = "ACTIVE"
        isPublic = $true
        note = "Production snapshot is publicly restorable."
    }
    $jsonl.Add(($incidentFinding | ConvertTo-Json -Depth 6 -Compress))
    Write-LinesFile -Path $JsonlPath -Lines $jsonl
}

function New-CurrentSnapshotState {
    param([string]$OutputPath)

    $content = @'
{
  "DBSnapshotIdentifier": "customer-db-backup-2026-03-05",
  "DBSnapshotArn": "arn:aws:rds:ap-south-1:111122223333:snapshot:customer-db-backup-2026-03-05",
  "Engine": "postgres",
  "Encrypted": true,
  "Status": "available",
  "SnapshotCreateTime": "2026-03-05T23:00:02Z",
  "DBSnapshotAttributesResult": {
    "DBSnapshotAttributes": [
      {
        "AttributeName": "restore",
        "AttributeValues": [
          "all"
        ]
      }
    ]
  }
}
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-11 Unexpected Snapshot Sharing (Real-World Investigation Pack)

Scenario:
Cloud governance detected that a production RDS snapshot changed sharing permissions.
Evidence includes large CloudTrail streams, snapshot inventory/attribute history,
governance and analyzer findings, and current snapshot state.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4478
Severity: Critical
Queue: Cloud Security + Governance

Summary:
Production customer snapshot appears to have had restore permissions changed to public.
Initial controls flagged multiple snapshot-sharing events, including sandbox traffic.

Scope:
- Snapshot: customer-db-backup-2026-03-05
- Region: ap-south-1
- Window: 2026-03-06 05:14 UTC onward

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Do not assume every public snapshot finding is production impact.
- Correlate snapshot identifier across CloudTrail, history, and current attributes.
- Confirm whether permission changed to specific accounts or the public principal ("all").
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$baseline = @'
{
  "control_id": "RDS-SNAPSHOT-SHARING-01",
  "approved_restore_principals": [
    "222233334444",
    "333344445555"
  ],
  "public_sharing_allowed": false,
  "production_snapshots_must_remain_private": true
}
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\aws\approved_sharing_baseline.json") -Content $baseline

$containment = @'
Containment actions:
1. Remove "all" restore attribute from affected snapshot.
2. Rotate snapshot copy into isolated recovery account.
3. Add SCP guardrail to deny public restore attribute on production snapshots.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\response\containment_actions.txt") -Content $containment

New-SnapshotInventory -OutputPath (Join-Path $bundleRoot "evidence\aws\snapshot_inventory.csv")
New-CloudTrailEvents -OutputPath (Join-Path $bundleRoot "evidence\aws\cloudtrail_events.jsonl")
New-SnapshotAttributeHistory -OutputPath (Join-Path $bundleRoot "evidence\aws\snapshot_attribute_history.csv")
New-GovernanceFindings -CsvPath (Join-Path $bundleRoot "evidence\security\governance_findings.csv") -JsonlPath (Join-Path $bundleRoot "evidence\security\access_analyzer_findings.jsonl")
New-CurrentSnapshotState -OutputPath (Join-Path $bundleRoot "evidence\aws\snapshot_attributes_current.json")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
