param()

$ErrorActionPreference = "Stop"

$bundleName = "m10-02-hidden-archive"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m10_02_realworld_build"
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

function New-IncidentArchiveZip {
    param([string]$OutputPath)

    $payloadDir = Join-Path $buildRoot "archive_payload"
    Remove-Item -Recurse -Force $payloadDir -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $payloadDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $payloadDir "docs") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $payloadDir "exports") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $payloadDir "tmp") | Out-Null

    Write-TextFile -Path (Join-Path $payloadDir "notes.txt") -Content "Operator notes from incident workstation."
    Write-TextFile -Path (Join-Path $payloadDir "report.txt") -Content "Preliminary report for archive triage."

    for ($i = 0; $i -lt 35; $i++) {
        $name = "doc_" + ("{0:D3}" -f $i) + ".txt"
        Write-TextFile -Path (Join-Path $payloadDir "docs\$name") -Content ("Document sample " + $i)
    }

    for ($i = 0; $i -lt 20; $i++) {
        $name = "export_" + ("{0:D3}" -f $i) + ".csv"
        Write-TextFile -Path (Join-Path $payloadDir "exports\$name") -Content "id,value`n$i,$($i * 7)"
    }

    for ($i = 0; $i -lt 15; $i++) {
        $name = "tmp_" + ("{0:D3}" -f $i) + ".log"
        Write-TextFile -Path (Join-Path $payloadDir "tmp\$name") -Content ("temp log line " + $i)
    }

    # Target hidden/overlooked file expected by challenge
    Write-TextFile -Path (Join-Path $payloadDir "secret.txt") -Content "sensitive internal token memo"

    if (Test-Path $OutputPath) {
        Remove-Item -Force $OutputPath
    }
    Compress-Archive -Path (Join-Path $payloadDir "*") -DestinationPath $OutputPath -Force
}

function New-RecoveredArchivesInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,archive_id,archive_name,size_bytes,source_host,triage_status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $id = "A" + ("{0:D8}" -f (20000000 + $i))
        $name = "bundle_" + ("{0:D5}" -f (30000 + $i)) + ".zip"
        $size = 1024 + (($i * 81) % 90000000)
        $hostName = "wkstn-" + ("{0:D3}" -f ($i % 500))
        $status = if (($i % 211) -eq 0) { "needs_listing_scan" } else { "queued" }
        $lines.Add("$ts,$id,$name,$size,$hostName,$status")
    }

    $lines.Add("2026-03-08T01:02:11Z,A29999991,archive.zip,18842,wkstn-144,needs_listing_scan")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ZipListingScanLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $entries = @("notes.txt","report.txt","docs/doc_001.txt","tmp/tmp_001.log","exports/export_001.csv")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $aid = "A" + ("{0:D8}" -f (22000000 + $i))
        $entry = $entries[$i % $entries.Count]
        $lines.Add("$ts zip_listing archive_id=$aid entry=$entry visibility=normal")
    }

    $lines.Add("2026-03-08T01:02:16Z zip_listing archive_id=A29999991 entry=secret.txt visibility=hidden note=overlooked_entry")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ArchiveContentsIndex {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,archive_name,entry_path,entry_type,entry_size_bytes,scanner")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $archive = "bundle_" + ("{0:D5}" -f (40000 + $i)) + ".zip"
        $entry = "docs/doc_" + ("{0:D3}" -f ($i % 200)) + ".txt"
        $size = 50 + ($i % 3000)
        $lines.Add("$ts,$archive,$entry,file,$size,indexer-v3")
    }

    $lines.Add("2026-03-08T01:02:19Z,archive.zip,secret.txt,file,28,indexer-v3")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HashCatalogJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 8).ToString("o")
            archive = "bundle_" + ("{0:D5}" -f (50000 + $i)) + ".zip"
            entry = "file_" + ("{0:D5}" -f (60000 + $i)) + ".txt"
            sha256 = ("{0:x64}" -f (700000 + $i))
            triage = if (($i % 177) -eq 0) { "review" } else { "normal" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T01:02:22Z"
        archive = "archive.zip"
        entry = "secret.txt"
        sha256 = "fdc98e4f8af6739a95a9ed400de9657c0dd03f0ed5eb64f48d5d59e5f5f00abc"
        triage = "critical"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 229) -eq 0) { "archive-quality-check" } else { "archive-triage-heartbeat" }
        $sev = if ($evt -eq "archive-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,dfir-archive-siem-01,$sev,archive triage enrichment heartbeat")
    }

    $lines.Add("2026-03-08T01:02:25Z,hidden_file_confirmed,dfir-archive-siem-01,high,hidden file identified in archive.zip as secret.txt")
    $lines.Add("2026-03-08T01:02:30Z,ctf_answer_ready,dfir-archive-siem-01,high,submit secret.txt")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ArchiveManifestPreview {
    param([string]$OutputPath)

    $content = @'
Archive sample manifest:
- notes.txt
- report.txt
- secret.txt
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
Forensics Case Notes (Extract)

Objective:
Identify overlooked/hidden file inside recovered archive.

Validation rule:
Correlate archive listing scan, content index, hash catalog, and SIEM confirmation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Intel Snapshot

Recovered archive contains a hidden/overlooked entry.
Current triage consensus: secret.txt
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M10-02 Hidden Archive (Real-World Investigation Pack)

Scenario:
A recovered archive from an incident workstation may contain an overlooked entry.

Task:
Analyze the evidence pack and identify the hidden file.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-6002
Severity: Medium
Queue: DFIR

Summary:
Identify hidden file from recovered archive triage dataset.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate recovered archive inventory, zip listing scans, archive content index,
  hash catalog, SIEM timeline, and intel notes.
- Identify hidden file within archive.zip.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-IncidentArchiveZip -OutputPath (Join-Path $bundleRoot "evidence\archive.zip")
New-ArchiveManifestPreview -OutputPath (Join-Path $bundleRoot "evidence\forensics\archive_manifest_preview.txt")
New-RecoveredArchivesInventory -OutputPath (Join-Path $bundleRoot "evidence\forensics\recovered_archives_inventory.csv")
New-ZipListingScanLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\zip_listing_scan.log")
New-ArchiveContentsIndex -OutputPath (Join-Path $bundleRoot "evidence\forensics\archive_contents_index.csv")
New-HashCatalogJsonl -OutputPath (Join-Path $bundleRoot "evidence\forensics\hash_catalog.jsonl")
New-TimelineEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CaseNotes -OutputPath (Join-Path $bundleRoot "evidence\forensics\case_notes.txt")
New-IntelSnapshot -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
