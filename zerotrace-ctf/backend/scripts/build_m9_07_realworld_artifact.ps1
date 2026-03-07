param()

$ErrorActionPreference = "Stop"

$bundleName = "m9-07-hidden-image-info"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m9_07_realworld_build"
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

function New-ImageInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("snapshot_time_utc,file_name,size_bytes,mime_type,ingest_status,source_bucket")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $buckets = @("media-archive-a","media-archive-b","media-archive-c")

    for ($i = 0; $i -lt 6900; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $file = "IMG_" + ("{0:D5}" -f (50000 + $i)) + ".jpg"
        $size = 400000 + (($i * 97) % 9500000)
        $status = if (($i % 211) -eq 0) { "needs_review" } else { "indexed" }
        $bucket = $buckets[$i % $buckets.Count]
        $lines.Add("$ts,$file,$size,image/jpeg,$status,$bucket")
    }

    $lines.Add("2026-03-07T00:12:10Z,target_image.jpg,2845123,image/jpeg,needs_review,media-archive-c")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ExifParserLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $models = @("iPhone 13","Pixel 7","Nikon D3500","Sony A7 III","Canon EOS 200D","Fujifilm X-T30")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $file = "IMG_" + ("{0:D5}" -f (55000 + $i)) + ".jpg"
        $model = $models[$i % $models.Count]
        $lens = "Lens-" + ("{0:D3}" -f ($i % 250))
        $lines.Add("$ts exif_parse file=$file camera_model=`"$model`" lens=$lens status=ok")
    }

    $lines.Add("2026-03-07T00:12:16Z exif_parse file=target_image.jpg camera_model=`"Canon EOS 80D`" lens=`"18-135mm`" status=ok")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-XmpExtractionJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            file = "photo_" + ("{0:D5}" -f (60000 + $i)) + ".jpg"
            xmp = [ordered]@{
                creatorTool = "Adobe Lightroom"
                cameraModel = "Model-" + ("{0:D4}" -f ($i % 2000))
            }
            risk = if (($i % 173) -eq 0) { "medium" } else { "low" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T00:12:19Z"
        file = "target_image.jpg"
        xmp = [ordered]@{
            creatorTool = "Adobe Lightroom"
            cameraModel = "Canon EOS 80D"
        }
        risk = "high"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CameraFingerprintCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,file_name,fp_hash,candidate_model,confidence,source")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $candidates = @("Canon EOS 200D","Nikon D5600","Sony A6400","Fujifilm X-T3","Canon EOS M50")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $file = "img_fp_" + ("{0:D5}" -f (70000 + $i)) + ".jpg"
        $hash = ("{0:x32}" -f (900000 + $i))
        $model = $candidates[$i % $candidates.Count]
        $conf = [math]::Round((0.2 + (($i % 60) / 100)), 2)
        $lines.Add("$ts,$file,$hash,$model,$conf,fp-engine-v2")
    }

    $lines.Add("2026-03-07T00:12:22Z,target_image.jpg,9af2be8d31d471ecaa8c0b94e147cb30,Canon EOS 80D,0.99,fp-engine-v2")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 227) -eq 0) { "image-metadata-quality-check" } else { "image-enrichment-heartbeat" }
        $sev = if ($evt -eq "image-metadata-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,osint-image-siem-01,$sev,image metadata enrichment heartbeat")
    }

    $lines.Add("2026-03-07T00:12:25Z,camera_model_confirmed,osint-image-siem-01,high,target image camera model resolved as Canon EOS 80D")
    $lines.Add("2026-03-07T00:12:31Z,ctf_answer_ready,osint-image-siem-01,high,submit Canon_EOS_80D")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ImageMetadataTxt {
    param([string]$OutputPath)

    $content = @'
Camera Model: Canon EOS 80D
Lens: 18-135mm
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
OSINT Case Notes (Extract)

Objective:
Identify camera model from hidden image metadata and attribution telemetry.

Validation rule:
Correlate EXIF parser output, XMP extraction, and fingerprint model inference.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Target image attribution indicates DSLR class source.
Most likely camera model: Canon EOS 80D
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M9-07 Hidden Image Info (Real-World Investigation Pack)

Scenario:
An image under investigation contains hidden metadata useful for camera attribution.

Task:
Analyze the evidence pack and identify the camera model.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5907
Severity: Medium
Queue: SOC OSINT

Summary:
Camera attribution required for target image using metadata evidence.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate image inventory, EXIF parser logs, XMP extraction output,
  camera fingerprint records, SIEM timeline, and intel notes.
- Identify camera model for target_image.jpg.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ImageMetadataTxt -OutputPath (Join-Path $bundleRoot "evidence\image_metadata.txt")
New-ImageInventory -OutputPath (Join-Path $bundleRoot "evidence\osint\image_inventory.csv")
New-ExifParserLog -OutputPath (Join-Path $bundleRoot "evidence\osint\exif_parser.log")
New-XmpExtractionJsonl -OutputPath (Join-Path $bundleRoot "evidence\osint\xmp_extraction.jsonl")
New-CameraFingerprintCsv -OutputPath (Join-Path $bundleRoot "evidence\osint\camera_fingerprint.csv")
New-TimelineEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CaseNotes -OutputPath (Join-Path $bundleRoot "evidence\osint\case_notes.txt")
New-IntelSnapshot -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
