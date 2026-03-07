param()

$ErrorActionPreference = "Stop"

$bundleName = "m10-01-suspicious-file-type"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m10_01_realworld_build"
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

function Write-BytesFile {
    param([string]$Path, [byte[]]$Bytes)
    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    [System.IO.File]::WriteAllBytes($Path, $Bytes)
}

function New-FileBin {
    param([string]$OutputPath)

    # Starts with PNG magic bytes but kept as .bin to force type attribution.
    $hex = @(
        0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,
        0x00,0x00,0x00,0x0D,0x49,0x48,0x44,0x52,
        0x00,0x00,0x02,0x80,0x00,0x00,0x01,0xE0,
        0x08,0x02,0x00,0x00,0x00,0x6F,0xB6,0x17,
        0x00,0x00,0x00,0x09,0x70,0x48,0x59,0x73,
        0x00,0x00,0x0E,0xC4,0x00,0x00,0x0E,0xC4
    )
    [byte[]]$bytes = $hex
    Write-BytesFile -Path $OutputPath -Bytes $bytes
}

function New-RecoveredFilesInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,file_id,file_name,extension,size_bytes,recovery_source,triage_status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $exts = @("tmp","dat","raw","log","cfg","bin")
    $sources = @("disk-image-01","disk-image-02","memory-dump-01")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $id = "F" + ("{0:D8}" -f (10000000 + $i))
        $ext = $exts[$i % $exts.Count]
        $name = "recovered_" + ("{0:D5}" -f (20000 + $i)) + "." + $ext
        $size = 256 + (($i * 73) % 7000000)
        $src = $sources[$i % $sources.Count]
        $status = if (($i % 211) -eq 0) { "needs_signature_check" } else { "queued" }
        $lines.Add("$ts,$id,$name,$ext,$size,$src,$status")
    }

    $lines.Add("2026-03-08T00:38:12Z,F19999991,file.bin,bin,48,disk-image-02,needs_signature_check")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FileCarvingLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $sigs = @("4D 5A","25 50 44 46","FF D8 FF E0","50 4B 03 04","7F 45 4C 46")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $fid = "F" + ("{0:D8}" -f (12000000 + $i))
        $sig = $sigs[$i % $sigs.Count]
        $lines.Add("$ts file_carve file_id=$fid sig=`"$sig`" carve_result=partial")
    }

    $lines.Add("2026-03-08T00:38:16Z file_carve file_id=F19999991 file_name=file.bin sig=`"89 50 4E 47 0D 0A 1A 0A`" carve_result=valid_header")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-MagicScanJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("application/pdf","application/zip","application/x-dosexec","image/jpeg","text/plain")

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            file = "artifact_" + ("{0:D6}" -f (400000 + $i)) + ".bin"
            magic = $types[$i % $types.Count]
            real_type = if (($i % 5) -eq 3) { "jpeg" } else { "unknown" }
            confidence = [math]::Round((0.18 + (($i % 70) / 100)), 2)
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T00:38:19Z"
        file = "file.bin"
        magic = "image/png"
        real_type = "png"
        confidence = 0.99
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-YaraTriageLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $rules = @("suspicious_payload","embedded_zip","packed_binary","pdf_obfuscation","benign_pattern")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $file = "artifact_" + ("{0:D6}" -f (500000 + $i)) + ".bin"
        $rule = $rules[$i % $rules.Count]
        $sev = if (($i % 151) -eq 0) { "medium" } else { "low" }
        $lines.Add("$ts yara_scan file=$file rule=$rule severity=$sev result=logged")
    }

    $lines.Add("2026-03-08T00:38:21Z yara_scan file=file.bin rule=embedded_png_header severity=high result=investigate")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 229) -eq 0) { "file-signature-quality-check" } else { "forensics-ingest-heartbeat" }
        $sev = if ($evt -eq "file-signature-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,forensics-siem-01,$sev,file-type attribution pipeline heartbeat")
    }

    $lines.Add("2026-03-08T00:38:24Z,file_type_confirmed,forensics-siem-01,high,target file.bin real type confirmed as png")
    $lines.Add("2026-03-08T00:38:29Z,ctf_answer_ready,forensics-siem-01,high,submit png")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HexDumpTxt {
    param([string]$OutputPath)

    $content = @'
Hex signature:
89 50 4E 47 0D 0A 1A 0A
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
Forensics Case Notes (Extract)

Objective:
Determine real file type for target recovered binary file.bin.

Validation rule:
Correlate carving signature, magic scan output, and SIEM type confirmation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Intel Snapshot

Recovered artifact shows strong PNG magic signature.
Current triage consensus real type: png
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M10-01 Suspicious File Type (Real-World Investigation Pack)

Scenario:
A recovered binary file has a misleading extension and needs true type attribution.

Task:
Analyze the evidence pack and identify the real file type.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-6001
Severity: Medium
Queue: DFIR

Summary:
Determine real type for recovered file.bin in forensic triage.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate recovered file inventory, carving logs, magic scan output,
  YARA triage, SIEM timeline, and intel notes.
- Identify real file type for file.bin.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-FileBin -OutputPath (Join-Path $bundleRoot "evidence\file.bin")
New-HexDumpTxt -OutputPath (Join-Path $bundleRoot "evidence\forensics\hex_dump_target.txt")
New-RecoveredFilesInventory -OutputPath (Join-Path $bundleRoot "evidence\forensics\recovered_files_inventory.csv")
New-FileCarvingLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\file_carving.log")
New-MagicScanJsonl -OutputPath (Join-Path $bundleRoot "evidence\forensics\magic_scan_results.jsonl")
New-YaraTriageLog -OutputPath (Join-Path $bundleRoot "evidence\security\yara_triage.log")
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
