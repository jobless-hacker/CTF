param()

$ErrorActionPreference = "Stop"

$bundleName = "m10-06-suspicious-executable"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m10_06_realworld_build"
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

function New-FileSignatureTxt {
    param([string]$OutputPath)

    $content = @'
Suspicious sample signature

hex_signature=4D 5A
offset=0x00000000
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-SignaturePreview {
    param([string]$OutputPath)

    $content = @'
Signature Preview

Detected header bytes: 4D 5A
Analyst note: verify executable format via multi-source validation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-TriageInventoryCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,artifact_id,file_name,size_bytes,collection_source,triage_status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $sources = @("mail-gateway","endpoint-edr","sandbox-uploader","proxy-cache","forensics-share")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $aid = "ART-" + ("{0:D9}" -f (810000000 + $i))
        $name = "sample_" + ("{0:D6}" -f (120000 + $i)) + ".bin"
        $size = 20000 + (($i * 97) % 9000000)
        $src = $sources[$i % $sources.Count]
        $status = if (($i % 191) -eq 0) { "requires_signature_review" } else { "indexed" }
        $lines.Add("$ts,$aid,$name,$size,$src,$status")
    }

    $lines.Add("2026-03-08T02:20:10Z,ART-899999901,sample.bin,483328,endpoint-edr,requires_signature_review")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HeaderScanLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $headers = @("7F 45 4C 46","25 50 44 46","50 4B 03 04","89 50 4E 47","FF D8 FF E0")
    $formats = @("elf","pdf","zip","png","jpeg")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $sig = $headers[$i % $headers.Count]
        $fmt = $formats[$i % $formats.Count]
        $name = "sample_" + ("{0:D6}" -f (122000 + $i)) + ".bin"
        $lines.Add("$ts header_scan file=$name magic=`"$sig`" candidate_format=$fmt source=bulk-scanner")
    }

    $lines.Add("2026-03-08T02:20:14Z header_scan file=sample.bin magic=`"4D 5A`" candidate_format=exe source=bulk-scanner")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-StringExtractionJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            file = "sample_" + ("{0:D6}" -f (130000 + $i)) + ".bin"
            strings = @("status_ok","heartbeat","pipeline_v2")
            signal = if (($i % 237) -eq 0) { "review" } else { "normal" }
            confidence = [math]::Round((0.2 + (($i % 60) / 100)), 2)
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T02:20:18Z"
        file = "sample.bin"
        strings = @("MZ","This program cannot be run in DOS mode")
        signal = "executable_signature_detected"
        confidence = 0.99
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PeAnalysisCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,file_name,analysis_engine,detected_header,detected_format,confidence")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $detected = @("elf","zip","pdf","unknown","jpg")
    $headers = @("7F 45 4C 46","50 4B 03 04","25 50 44 46","00 00 00 00","FF D8 FF E0")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $name = "sample_" + ("{0:D6}" -f (140000 + $i)) + ".bin"
        $fmt = $detected[$i % $detected.Count]
        $hdr = $headers[$i % $headers.Count]
        $conf = [math]::Round((0.18 + (($i % 70) / 100)), 2)
        $lines.Add("$ts,$name,pe-analyzer-v4,$hdr,$fmt,$conf")
    }

    $lines.Add("2026-03-08T02:20:21Z,sample.bin,pe-analyzer-v4,4D 5A,exe,0.99")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEventsCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 271) -eq 0) { "binary-anomaly-check" } else { "forensics-pipeline-heartbeat" }
        $sev = if ($evt -eq "binary-anomaly-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,dfir-binary-siem-01,$sev,binary triage correlation heartbeat")
    }

    $lines.Add("2026-03-08T02:20:24Z,suspicious_executable_confirmed,dfir-binary-siem-01,high,file=sample.bin format=exe")
    $lines.Add("2026-03-08T02:20:30Z,ctf_answer_ready,dfir-binary-siem-01,high,submit exe")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
Forensics Case Notes (Extract)

Objective:
Identify the file format for the suspicious sample using signature-led triage.

Validation rule:
Correlate signature bytes, header scans, string extraction, PE analysis, and SIEM confirmation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Intel Snapshot

Recovered binary exhibits executable header behavior.
Primary triage conclusion: format=exe
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M10-06 Suspicious Executable (Real-World Investigation Pack)

Scenario:
A suspicious binary sample needs file-format attribution using forensic evidence.

Task:
Analyze the evidence pack and identify the file format.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-6006
Severity: Medium
Queue: DFIR

Summary:
Investigate suspicious binary sample and determine accurate file format classification.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate signature bytes, triage inventory, header scan results,
  string extraction output, PE analysis records, SIEM events, and intel notes.
- Determine final file format token for submission.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-FileSignatureTxt -OutputPath (Join-Path $bundleRoot "evidence\file_signature.txt")
New-SignaturePreview -OutputPath (Join-Path $bundleRoot "evidence\forensics\signature_preview.txt")
New-TriageInventoryCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\triage_inventory.csv")
New-HeaderScanLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\header_scan.log")
New-StringExtractionJsonl -OutputPath (Join-Path $bundleRoot "evidence\forensics\string_extraction.jsonl")
New-PeAnalysisCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\pe_analysis.csv")
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
