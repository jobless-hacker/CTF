param()

$ErrorActionPreference = "Stop"

$bundleName = "m10-07-deleted-file-trace"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m10_07_realworld_build"
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

function New-FilesystemLog {
    param([string]$OutputPath)

    $content = @'
deleted file: credentials.txt
deleted file: logs.txt
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-DeletedFilesPreview {
    param([string]$OutputPath)

    $content = @'
Deleted Files Preview

deleted file: credentials.txt
deleted file: logs.txt
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-DeletionJournalCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_id,host,user,action,file_path,reason")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("ops1","ops2","backupsvc","analyst","cleanup-bot","admin")
    $reasons = @("retention-policy","cleanup-temp","rotation","manual-cleanup","automation-rule")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $eid = "DEL-" + ("{0:D9}" -f (720000000 + $i))
        $srcHost = "fs-node-" + ("{0:D3}" -f (($i % 92) + 1))
        $user = $users[$i % $users.Count]
        $file = "/var/tmp/cache_" + ("{0:D5}" -f ($i % 18000)) + ".tmp"
        $reason = $reasons[$i % $reasons.Count]
        $lines.Add("$ts,$eid,$srcHost,$user,file_deleted,$file,$reason")
    }

    $lines.Add("2026-03-08T02:35:10Z,DEL-799999901,fs-node-017,admin,file_deleted,/srv/data/credentials.txt,manual-cleanup")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FsAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $actors = @("ops1","ops2","svc_rotate","backupsvc","admin")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $actor = $actors[$i % $actors.Count]
        $path = "/var/log/app/log_" + ("{0:D5}" -f ($i % 24000)) + ".txt"
        $lines.Add("$ts fs_audit actor=$actor event=unlink path=$path result=success")
    }

    $lines.Add("2026-03-08T02:35:14Z fs_audit actor=admin event=unlink path=/srv/data/credentials.txt result=success normalized_deleted_file=credentials.txt")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RecoveryCatalogJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            record_id = "REC-" + ("{0:D10}" -f (8800000000 + $i))
            host = "fs-node-" + ("{0:D3}" -f (($i % 85) + 1))
            deleted_candidate = "cache_" + ("{0:D6}" -f ($i % 900000)) + ".tmp"
            recoverable = if (($i % 211) -eq 0) { $false } else { $true }
            confidence = [math]::Round((0.2 + (($i % 60) / 100)), 2)
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T02:35:18Z"
        record_id = "REC-9999999912"
        host = "fs-node-017"
        deleted_candidate = "credentials.txt"
        recoverable = $false
        confidence = 0.99
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IndexCorrelationCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,index_id,source_file,correlated_event,correlated_value,confidence")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $idx = "IDX-" + ("{0:D9}" -f (510000000 + $i))
        $source = "artifact_" + ("{0:D6}" -f ($i % 700000)) + ".dat"
        $event = "unlink"
        $value = "noise_" + ("{0:D5}" -f ($i % 50000))
        $conf = [math]::Round((0.15 + (($i % 70) / 100)), 2)
        $lines.Add("$ts,$idx,$source,$event,$value,$conf")
    }

    $lines.Add("2026-03-08T02:35:21Z,IDX-599999991,filesystem.log,deleted_file,credentials.txt,0.99")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEventsCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 269) -eq 0) { "deleted-file-anomaly-check" } else { "forensics-pipeline-heartbeat" }
        $sev = if ($evt -eq "deleted-file-anomaly-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,dfir-fs-siem-01,$sev,filesystem deletion correlation heartbeat")
    }

    $lines.Add("2026-03-08T02:35:24Z,sensitive_deleted_file_confirmed,dfir-fs-siem-01,high,deleted_file=credentials.txt")
    $lines.Add("2026-03-08T02:35:30Z,ctf_answer_ready,dfir-fs-siem-01,high,submit credentials.txt")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
Forensics Case Notes (Extract)

Objective:
Identify the deleted sensitive file from filesystem cleanup activity.

Validation rule:
Correlate deletion journal, fs audit logs, recovery catalog, index correlation, and SIEM confirmation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Intel Snapshot

Cleanup activity includes deletion of a sensitive credential artifact.
Primary deleted file candidate: credentials.txt
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M10-07 Deleted File Trace (Real-World Investigation Pack)

Scenario:
Filesystem cleanup telemetry suggests a sensitive file was deleted during incident activity.

Task:
Analyze the evidence pack and identify the deleted sensitive file.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-6007
Severity: Medium
Queue: DFIR

Summary:
Investigate filesystem deletion traces and identify deleted sensitive file.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate base filesystem log, deletion journal, fs audit traces,
  recovery catalog output, index correlation data, SIEM events, and intel notes.
- Determine deleted sensitive file token for submission.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-FilesystemLog -OutputPath (Join-Path $bundleRoot "evidence\filesystem.log")
New-DeletedFilesPreview -OutputPath (Join-Path $bundleRoot "evidence\forensics\deleted_files_preview.txt")
New-DeletionJournalCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\deletion_journal.csv")
New-FsAuditLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\fs_audit.log")
New-RecoveryCatalogJsonl -OutputPath (Join-Path $bundleRoot "evidence\forensics\recovery_catalog.jsonl")
New-IndexCorrelationCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\index_correlation.csv")
New-TimelineEventsCsv -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CaseNotes -OutputPath (Join-Path $bundleRoot "evidence\forensics\case_notes.txt")
New-IntelSnapshot -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
