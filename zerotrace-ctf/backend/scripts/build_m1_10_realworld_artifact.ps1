param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-10-backup-corruption"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_10_realworld_build"
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

function Get-HexFromText {
    param([string]$Text)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    return ([System.BitConverter]::ToString($bytes)).Replace("-", "").ToLower()
}

function New-BackupCatalog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("backup_id,timestamp_utc,source,backup_file,size_gb,sha256,status,verification_stage,storage_tier,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5400; $i++) {
        $tsObj = $base.AddMinutes($i * 8)
        $ts = $tsObj.ToString("o")
        $source = if (($i % 3) -eq 0) { "postgres-prod" } elseif (($i % 5) -eq 0) { "postgres-staging" } else { "orders-db-prod" }
        $file = "$source-$($tsObj.ToString('yyyyMMdd-HHmm'))-full.tar.zst"
        $size = "{0:N2}" -f (8.2 + (($i * 3) % 130) / 10.0)
        $hash = (Get-HexFromText -Text "bk-$i-$source").PadRight(64, '0').Substring(0,64)
        $status = "success"
        $stage = if (($i % 17) -eq 0) { "metadata-only" } else { "checksum-verified" }
        $tier = if (($i % 4) -eq 0) { "warm" } else { "standard" }
        $note = if ($stage -eq "metadata-only") { "deferred full verification window" } else { "verification complete" }
        $lines.Add("BK-$((120000 + $i)),$ts,$source,$file,$size,$hash,$status,$stage,$tier,$note")
    }

    # Known false positive from staging maintenance test
    $lines.Add("BK-125921,2026-03-05T23:00:02Z,postgres-staging,postgres-staging-20260305-2300-full.tar.zst,6.42,2f3e8b4d5d17398ef64c1b9a7e3b4f6ad8e302f1e8b72a996e55131af0d9c1a2,success,checksum-warning,standard,staging test archive included intentionally modified fixture file")

    # Incident backup row
    $lines.Add("BK-126004,2026-03-05T23:00:02Z,customer-db-prod,customer-db-2026-03-05.tar.zst,18.40,874b7c2e5f9f0a0e9b31a0e1946737ded3931314db4f4374c6d4cbf6ab0f8e5a,success,metadata-only,standard,verification pipeline delayed")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BackupManifestJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T23:00:02", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4200; $i++) {
        $ts = $base.AddMilliseconds($i * 120).ToString("o")
        $entry = [ordered]@{
            backup_id = "BK-126004"
            timestamp = $ts
            file = "data/chunk-$($i.ToString('D5')).bin"
            size_bytes = 65536 + (($i * 17) % 2048)
            checksum_algorithm = "sha256"
            checksum = (Get-HexFromText -Text "chunk-$i").PadRight(64,'0').Substring(0,64)
            compression = "zstd"
            verified_at_backup_time = $false
        }
        $lines.Add(($entry | ConvertTo-Json -Depth 6 -Compress))
    }

    $manifestMeta = [ordered]@{
        backup_id = "BK-126004"
        manifest_type = "backup_manifest"
        source = "customer-db-prod"
        backup_file = "customer-db-2026-03-05.tar.zst"
        manifest_checksum = "874b7c2e5f9f0a0e9b31a0e1946737ded3931314db4f4374c6d4cbf6ab0f8e5a"
        expected_size_bytes = 19756849561
        backup_engine = "dbbackupctl v2.14.8"
    }
    $lines.Add(($manifestMeta | ConvertTo-Json -Depth 6 -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RestoreControllerLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T10:50:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 9800; $i++) {
        $tsObj = $base.AddMilliseconds($i * 260)
        $ts = $tsObj.ToString("o")
        $job = "restore-job-$((45000 + ($i % 220)))"
        $msg = if (($i % 9) -eq 0) { "validation checkpoint complete" } elseif (($i % 17) -eq 0) { "restoring non-critical dataset succeeded" } else { "restore workflow heartbeat ok" }
        $lines.Add("$ts restorectl[4121]: job=$job level=info msg=""$msg""")
    }

    # Incident sequence
    $lines.Add("2026-03-06T11:54:10Z restorectl[4121]: job=restore-job-46211 level=info msg=""starting restore"" source=customer-db-prod backup_file=customer-db-2026-03-05.tar.zst")
    $lines.Add("2026-03-06T11:54:16Z restorectl[4121]: job=restore-job-46211 level=info msg=""reading backup manifest"" backup_id=BK-126004")
    $lines.Add("2026-03-06T11:54:18Z restorectl[4121]: job=restore-job-46211 level=info msg=""verifying archive checksum"" expected=874b7c2e5f9f0a0e9b31a0e1946737ded3931314db4f4374c6d4cbf6ab0f8e5a")
    $lines.Add("2026-03-06T11:54:20Z restorectl[4121]: job=restore-job-46211 level=error msg=""archive checksum mismatch"" observed=44b9fa4f8df3964b4888958037f1552cbd1c5c93d6aa6d9cf6e7db5b6f2fdc8a")
    $lines.Add("2026-03-06T11:54:20Z restorectl[4121]: job=restore-job-46211 level=error msg=""archive extraction failed"" detail=""Unexpected EOF in archive""")
    $lines.Add("2026-03-06T11:54:21Z restorectl[4121]: job=restore-job-46211 level=error msg=""restore aborted"" impact=""database unavailable""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ChecksumValidation {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,job_id,backup_id,file,expected_sha256,observed_sha256,status,notes")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T09:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("o")
        $job = "verify-$((70000 + $i))"
        $bid = "BK-$((122000 + ($i % 5000)))"
        $file = "archive-$((8000 + ($i % 4000))).tar.zst"
        $expected = (Get-HexFromText -Text "e-$i").PadRight(64,'0').Substring(0,64)
        $observed = $expected
        $status = "match"
        $note = "ok"

        if (($i % 803) -eq 0) {
            # benign stale-catalog warning, quickly reconciled
            $status = "warning"
            $note = "catalog lag detected, revalidation completed"
        }

        $lines.Add("$ts,$job,$bid,$file,$expected,$observed,$status,$note")
    }

    $lines.Add("2026-03-06T11:54:20Z,verify-777711,BK-126004,customer-db-2026-03-05.tar.zst,874b7c2e5f9f0a0e9b31a0e1946737ded3931314db4f4374c6d4cbf6ab0f8e5a,44b9fa4f8df3964b4888958037f1552cbd1c5c93d6aa6d9cf6e7db5b6f2fdc8a,mismatch,archive appears truncated or corrupted")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ObjectStorageAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,bucket,operation,object_key,request_id,client_ip,status_code,bytes,etag,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T22:30:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $op = if (($i % 6) -eq 0) { "PutObject" } else { "CompleteMultipartUpload" }
        $key = "backups/archive-$((11000 + ($i % 2000))).tar.zst"
        $req = "req-$((900000 + $i))"
        $ip = "10.88.4.$(10 + ($i % 50))"
        $code = 200
        $bytes = 130000000 + (($i * 7000) % 420000000)
        $etag = (Get-HexFromText -Text "etag-$i").PadRight(32,'0').Substring(0,32)
        $note = "normal-backup-upload"
        $lines.Add("$ts,prod-backup-vault,$op,$key,$req,$ip,$code,$bytes,$etag,$note")
    }

    # incident upload anomaly
    $lines.Add("2026-03-05T23:00:05Z,prod-backup-vault,InitiateMultipartUpload,backups/customer-db-2026-03-05.tar.zst,req-999001,10.88.4.23,200,0,,multipart start")
    $lines.Add("2026-03-05T23:00:16Z,prod-backup-vault,UploadPart,backups/customer-db-2026-03-05.tar.zst,req-999002,10.88.4.23,200,524288000,abf1132cd4ef88aa9c6612d111234abc,part=1")
    $lines.Add("2026-03-05T23:00:31Z,prod-backup-vault,UploadPart,backups/customer-db-2026-03-05.tar.zst,req-999003,10.88.4.23,500,0,,network reset during part upload")
    $lines.Add("2026-03-05T23:00:36Z,prod-backup-vault,CompleteMultipartUpload,backups/customer-db-2026-03-05.tar.zst,req-999004,10.88.4.23,200,19756849561,0d132aa44f89bb129c111ff2930fa66e,completed with missing final segment")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ServiceImpact {
    param(
        [string]$StatusPath,
        [string]$ProbePath
    )

    $status = New-Object System.Collections.Generic.List[string]
    $status.Add("timestamp_utc,service,state,detail")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:30:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 2600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $state = "healthy"
        $detail = "primary online"
        if ($ts -ge "2026-03-06T11:52:00Z" -and $ts -lt "2026-03-06T11:54:10Z") {
            $state = "degraded"
            $detail = "primary storage read failures; failover pending"
        }
        if ($ts -ge "2026-03-06T11:54:10Z" -and $ts -le "2026-03-06T12:05:00Z") {
            $state = "down"
            $detail = "restore in progress or failed"
        }
        $status.Add("$ts,customer-db,$state,$detail")
    }
    Write-LinesFile -Path $StatusPath -Lines $status

    $probe = New-Object System.Collections.Generic.List[string]
    $probe.Add("timestamp_utc,probe_region,check,http_status,response_time_ms,result")
    $probeBase = [datetime]::SpecifyKind([datetime]"2026-03-06T11:40:00", [DateTimeKind]::Utc)
    $regions = @("hyd","mum","blr","del")

    for ($i = 0; $i -lt 3400; $i++) {
        $tsObj = $probeBase.AddMilliseconds($i * 650)
        $ts = $tsObj.ToString("o")
        $region = $regions[$i % $regions.Count]
        $code = 200
        $lat = 180 + (($i * 5) % 260)
        $result = "ok"

        if ($tsObj -ge [datetime]::SpecifyKind([datetime]"2026-03-06T11:54:20", [DateTimeKind]::Utc) -and
            $tsObj -le [datetime]::SpecifyKind([datetime]"2026-03-06T12:05:00", [DateTimeKind]::Utc)) {
            if (($i % 3) -eq 0) {
                $code = 503
                $lat = 4200 + (($i * 4) % 2600)
                $result = "degraded"
            } else {
                $code = 0
                $lat = 10000
                $result = "timeout"
            }
        }

        $probe.Add("$ts,$region,/api/health,$code,$lat,$result")
    }
    Write-LinesFile -Path $ProbePath -Lines $probe
}

function New-SiemEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source,event_type,severity,asset,status,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T10:30:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $etype = if (($i % 14) -eq 0) { "backup_validation_warning" } else { "backup_pipeline_ok" }
        $sev = if ($etype -eq "backup_validation_warning") { 26 } else { 6 }
        $status = if ($etype -eq "backup_validation_warning") { "closed_false_positive" } else { "informational" }
        $note = if ($etype -eq "backup_validation_warning") { "staging fixture mismatch" } else { "routine backup operation" }
        $lines.Add("$ts,siem,$etype,$sev,backup-platform,$status,$note")
    }

    $lines.Add("2026-03-06T11:54:20Z,restorectl,backup_checksum_mismatch,94,BK-126004,open,observed digest differs from manifest")
    $lines.Add("2026-03-06T11:54:21Z,restorectl,restore_failure_unrecoverable,95,customer-db,open,archive extraction failed with unexpected EOF")
    $lines.Add("2026-03-06T11:54:25Z,sre,service_unavailable_post_restore_failure,93,customer-api,open,database recovery blocked")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-10 Backup Corruption (Real-World Investigation Pack)

Scenario:
A primary storage failure triggered a database restore attempt.
The restore failed during integrity checks, and service recovery did not complete.
Evidence includes backup catalog data, manifest records, checksum validation outputs,
object storage audit logs, restore controller logs, service probe telemetry, and SIEM alerts.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4470
Severity: Critical
Queue: Disaster Recovery + Platform Security

Summary:
Customer database primary storage failed. Recovery process attempted restore from nightly backup.
Restore job halted on checksum mismatch and archive extraction failure.

Scope:
- Backup ID: BK-126004
- Archive: customer-db-2026-03-05.tar.zst
- Window: 2026-03-06 11:54 UTC onward

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Backup platform has many non-critical warnings from staging fixtures.
- Correlate manifest checksum, restore checksum validation, and object-storage upload logs.
- Confirm whether recovery failure directly caused prolonged service unavailability.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$runbook = @'
DR runbook excerpt:
1. Validate backup manifest and archive digest before restore.
2. Restore to isolated recovery node and run consistency checks.
3. Promote restored node only after successful checksum and extraction validation.
4. If validation fails, use previous known-good snapshot and escalate P1.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\operations\dr_runbook_excerpt.txt") -Content $runbook

New-BackupCatalog -OutputPath (Join-Path $bundleRoot "evidence\backup\backup_catalog.csv")
New-BackupManifestJsonl -OutputPath (Join-Path $bundleRoot "evidence\backup\backup_manifest_records.jsonl")
New-RestoreControllerLog -OutputPath (Join-Path $bundleRoot "evidence\restore\restore_controller.log")
New-ChecksumValidation -OutputPath (Join-Path $bundleRoot "evidence\restore\checksum_validation.csv")
New-ObjectStorageAudit -OutputPath (Join-Path $bundleRoot "evidence\backup\object_storage_audit.csv")
New-ServiceImpact -StatusPath (Join-Path $bundleRoot "evidence\operations\service_recovery_status.csv") -ProbePath (Join-Path $bundleRoot "evidence\operations\uptime_probes.csv")
New-SiemEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\normalized_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
