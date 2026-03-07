param()

$ErrorActionPreference = "Stop"

$bundleName = "m10-09-stego-image"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m10_09_realworld_build"
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

function New-PictureEvidence {
    param([string]$OutputPath)

    # Minimal valid 1x1 PNG.
    $hex = @(
        0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,
        0x00,0x00,0x00,0x0D,0x49,0x48,0x44,0x52,
        0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,
        0x08,0x02,0x00,0x00,0x00,0x90,0x77,0x53,0xDE,
        0x00,0x00,0x00,0x0C,0x49,0x44,0x41,0x54,
        0x08,0xD7,0x63,0xF8,0xCF,0xC0,0x00,0x00,
        0x03,0x01,0x01,0x00,0x18,0xDD,0x8D,0xE1,
        0x00,0x00,0x00,0x00,0x49,0x45,0x4E,0x44,
        0xAE,0x42,0x60,0x82
    )
    [byte[]]$bytes = $hex
    Write-BytesFile -Path $OutputPath -Bytes $bytes
}

function New-StegoPreview {
    param([string]$OutputPath)

    $content = @'
Stego Artifact Preview

Target artifact: picture.png
Scan focus: hidden keyword extraction through LSB correlation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ImageIntakeCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,image_id,file_name,size_bytes,source_pipeline,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $sources = @("ingest-cam","ingest-mail","ingest-web","ingest-sync","ingest-drive")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $iid = "IMG-" + ("{0:D9}" -f (770000000 + $i))
        $name = "image_" + ("{0:D6}" -f (140000 + $i)) + ".png"
        $size = 10000 + (($i * 81) % 6000000)
        $src = $sources[$i % $sources.Count]
        $status = if (($i % 193) -eq 0) { "needs_stego_scan" } else { "indexed" }
        $lines.Add("$ts,$iid,$name,$size,$src,$status")
    }

    $lines.Add("2026-03-08T03:05:10Z,IMG-799999901,picture.png,186432,ingest-sync,needs_stego_scan")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-StegScanLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $modes = @("lsb-low","lsb-mid","metadata-diff","palette-check","noise-profile")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $mode = $modes[$i % $modes.Count]
        $file = "image_" + ("{0:D6}" -f (141500 + $i)) + ".png"
        $score = [math]::Round((0.05 + (($i % 55) / 100)), 2)
        $lines.Add("$ts steg_scan file=$file mode=$mode anomaly_score=$score status=processed")
    }

    $lines.Add("2026-03-08T03:05:14Z steg_scan file=picture.png mode=lsb-mid anomaly_score=0.99 status=hidden_keyword_detected keyword=shadow")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LsbProbeJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            probe_id = "LSB-" + ("{0:D10}" -f (6200000000 + $i))
            file = "image_" + ("{0:D6}" -f (155000 + $i)) + ".png"
            extracted_token = "noise_" + ("{0:D5}" -f ($i % 50000))
            confidence = [math]::Round((0.19 + (($i % 60) / 100)), 2)
            engine = "stego-lsb-v5"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T03:05:18Z"
        probe_id = "LSB-9999999914"
        file = "picture.png"
        extracted_token = "shadow"
        confidence = 0.99
        engine = "stego-lsb-v5"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-KeywordCorrelationCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,record_id,left_source,right_source,keyword,confidence")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $rid = "KCOR-" + ("{0:D9}" -f (310000000 + $i))
        $left = "scan_noise_" + ("{0:D5}" -f ($i % 60000))
        $right = "probe_noise_" + ("{0:D5}" -f ($i % 60000))
        $key = "noise_key_" + ("{0:D4}" -f ($i % 3000))
        $conf = [math]::Round((0.17 + (($i % 70) / 100)), 2)
        $lines.Add("$ts,$rid,$left,$right,$key,$conf")
    }

    $lines.Add("2026-03-08T03:05:21Z,KCOR-399999991,picture.png,lsb-mid,shadow,0.99")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEventsCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 277) -eq 0) { "stego-anomaly-check" } else { "forensics-pipeline-heartbeat" }
        $sev = if ($evt -eq "stego-anomaly-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,dfir-stego-siem-01,$sev,stego correlation pipeline heartbeat")
    }

    $lines.Add("2026-03-08T03:05:24Z,suspicious_stego_keyword,dfir-stego-siem-01,high,file=picture.png keyword=shadow")
    $lines.Add("2026-03-08T03:05:30Z,ctf_answer_ready,dfir-stego-siem-01,high,submit shadow")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
Forensics Case Notes (Extract)

Objective:
Identify the hidden keyword embedded in picture artifact.

Validation rule:
Correlate image intake records, stego scan logs, LSB probe output, keyword correlation, and SIEM confirmation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Intel Snapshot

Steganography pipeline indicates one high-confidence hidden token.
Primary keyword candidate: shadow
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M10-09 Stego Image (Real-World Investigation Pack)

Scenario:
Image analysis telemetry indicates hidden content may be embedded in a picture artifact.

Task:
Analyze the evidence pack and identify the hidden keyword.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-6009
Severity: Medium
Queue: DFIR

Summary:
Investigate suspected steganography artifact and recover hidden keyword.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate picture artifact, intake records, stego scan logs,
  LSB probe results, keyword-correlation telemetry, SIEM events, and intel notes.
- Determine hidden keyword token for submission.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-PictureEvidence -OutputPath (Join-Path $bundleRoot "evidence\picture.png")
New-StegoPreview -OutputPath (Join-Path $bundleRoot "evidence\forensics\stego_preview.txt")
New-ImageIntakeCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\image_intake.csv")
New-StegScanLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\steg_scan.log")
New-LsbProbeJsonl -OutputPath (Join-Path $bundleRoot "evidence\forensics\lsb_probe.jsonl")
New-KeywordCorrelationCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\keyword_correlation.csv")
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
