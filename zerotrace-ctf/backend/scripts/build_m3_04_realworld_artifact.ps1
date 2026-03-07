param()

$ErrorActionPreference = "Stop"

$bundleName = "m3-04-database-dump"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m3_04_realworld_build"
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

function New-LeakedUsersDump {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("-- users_dump_2026_03_07.sql")
    $lines.Add("-- Source: auth_core.users")
    $lines.Add("CREATE TABLE users (")
    $lines.Add("  username VARCHAR(64),")
    $lines.Add("  password VARCHAR(128),")
    $lines.Add("  role VARCHAR(32),")
    $lines.Add("  created_at TIMESTAMP")
    $lines.Add(");")
    $lines.Add("")

    $base = [datetime]::SpecifyKind([datetime]"2026-01-01T00:00:00", [DateTimeKind]::Utc)
    for ($i = 0; $i -lt 12200; $i++) {
        $user = "user_$('{0:D5}' -f $i)"
        $pass = "hash_$('{0:x8}' -f (90000000 + $i))"
        $role = if (($i % 8) -eq 0) { "analyst" } elseif (($i % 8) -eq 1) { "viewer" } elseif (($i % 8) -eq 2) { "operator" } else { "staff" }
        $ts = $base.AddMinutes($i).ToString("yyyy-MM-dd HH:mm:ss")
        $lines.Add("INSERT INTO users VALUES ('$user','$pass','$role','$ts');")
    }

    $lines.Add("INSERT INTO users VALUES ('john','john123','staff','2025-11-10 09:00:00');")
    $lines.Add("INSERT INTO users VALUES ('alice','welcome1','staff','2025-11-10 09:05:00');")
    $lines.Add("INSERT INTO users VALUES ('admin','AdminPass!','admin','2025-11-10 09:10:00');")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BackupCatalog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,backup_id,database,object_key,size_mb,encryption,storage_acl,owner,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 8400; $i++) {
        $ts = $base.AddMinutes($i).ToString("o")
        $db = if (($i % 2) -eq 0) { "auth_core" } else { "crm_core" }
        $key = "db_backups/$db/$('{0:yyyyMMdd}' -f $base.AddMinutes($i))_$('{0:D4}' -f ($i % 500)).sql.gz"
        $enc = if (($i % 3) -eq 0) { "kms" } else { "kms" }
        $acl = "private"
        $lines.Add("$ts,BKP-$((660000 + $i)),$db,$key,$((120 + (($i * 13) % 1900))),$enc,$acl,backup-bot,success")
    }

    $lines.Add("2026-03-07T10:21:13Z,BKP-991904,auth_core,incident_drop/users_dump_2026_03_07.sql,88,none,public-read,temp-contractor,success")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-StorageAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $path = "/private/db_backups/auth_core/$('{0:D4}' -f ($i % 600)).sql.gz"
        $ip = "10.170.21.$(20 + ($i % 50))"
        $status = if (($i % 149) -eq 0) { 403 } else { 200 }
        $lines.Add("$ts src_ip=$ip method=GET path=""$path"" status=$status bytes=$((1400 + (($i * 47) % 600000))) ua=""internal-backup-sync""")
    }

    $lines.Add("2026-03-07T10:21:22.151Z src_ip=185.199.110.42 method=GET path=""/incident_drop/users_dump_2026_03_07.sql"" status=200 bytes=1458120 ua=""curl/8.5.0""")
    $lines.Add("2026-03-07T10:21:36.380Z src_ip=185.199.110.42 method=GET path=""/incident_drop/users_dump_2026_03_07.sql"" status=200 bytes=1458120 ua=""Wget/1.21.4""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudChangeEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4100; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 20).ToString("o")
            actor = if (($i % 2) -eq 0) { "infra-bot" } else { "storage-admin" }
            action = "PutObjectRetention"
            bucket = "auth-backup-vault"
            key = "db_backups/auth_core/segment_$('{0:D4}' -f ($i % 500)).sql.gz"
            status = "applied"
            note = "routine backup governance update"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T10:21:10Z"
        actor = "temp-contractor"
        action = "PutObjectAcl"
        bucket = "auth-backup-vault"
        key = "incident_drop/users_dump_2026_03_07.sql"
        acl = "public-read"
        status = "applied"
        note = "manual exposure outside approved workflow"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DlpAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $signals = @("credential_pattern_check","db_export_volume","public_storage_scan","sensitive_keyword_match")

    for ($i = 0; $i -lt 3800; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 14).ToString("o")
            system = "dlp-db-01"
            severity = if (($i % 133) -eq 0) { "medium" } else { "low" }
            signal = $signals[$i % $signals.Count]
            object = "db_backups/auth_core/segment_$('{0:D4}' -f ($i % 400)).sql.gz"
            status = "closed_false_positive"
            note = "routine database backup monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T10:21:14Z"
        system = "dlp-db-01"
        severity = "high"
        signal = "plaintext_password_dump_exposed"
        object = "incident_drop/users_dump_2026_03_07.sql"
        status = "open"
        note = "leaked SQL dump contains plaintext credential records"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T10:21:23Z"
        system = "dlp-db-01"
        severity = "critical"
        signal = "external_download_sensitive_dump"
        object = "incident_drop/users_dump_2026_03_07.sql"
        status = "open"
        note = "external source downloaded leaked auth dump"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 199) -eq 0) { "db_backup_review" } else { "routine_backup_activity" }
        $sev = if ($event -eq "db_backup_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,siem-db-01,$sev,baseline database backup telemetry")
    }

    $lines.Add("2026-03-07T10:21:10Z,public_acl_set,siem-db-01,high,users_dump_2026_03_07.sql set to public-read")
    $lines.Add("2026-03-07T10:21:22Z,external_dump_access,siem-db-01,critical,external IP downloaded leaked SQL dump")
    $lines.Add("2026-03-07T10:21:30Z,incident_opened,siem-db-01,high,INC-2026-5074 database dump exposure")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DbSecurityPolicy {
    param([string]$OutputPath)

    $content = @'
Database Backup Security Policy (Excerpt)

1) Authentication database dumps must be encrypted and stored with private ACL.
2) Plaintext credential fields in backup artifacts are prohibited.
3) Any external access to auth dumps is a critical incident.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M3-04 Database Dump (Real-World Investigation Pack)

Scenario:
A leaked SQL dump from the authentication database was exposed in a public storage path and accessed externally.

Task:
Analyze the investigation pack and identify the admin password.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5074
Severity: High
Queue: SOC + Database Security

Summary:
Cloud and DLP monitoring detected exposure of an authentication SQL dump and subsequent external retrieval.

Scope:
- Object: incident_drop/users_dump_2026_03_07.sql
- Window: 2026-03-07 10:21 UTC
- Data class: authentication credentials

Deliverable:
Identify the admin password from leaked dump evidence.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate backup catalog, ACL changes, object access logs, DLP alerts, and SIEM timeline.
- Confirm leaked SQL dump context and inspect the dump content.
- Extract the admin password value.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-LeakedUsersDump -OutputPath (Join-Path $bundleRoot "evidence\leak\users_dump_2026_03_07.sql")
New-BackupCatalog -OutputPath (Join-Path $bundleRoot "evidence\db\backup_catalog.csv")
New-StorageAccessLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\public_object_access.log")
New-CloudChangeEvents -OutputPath (Join-Path $bundleRoot "evidence\cloud\acl_change_events.jsonl")
New-DlpAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_dump_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-DbSecurityPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\db_backup_security_policy.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
