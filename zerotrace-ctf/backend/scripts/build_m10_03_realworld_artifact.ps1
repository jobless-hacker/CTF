param()

$ErrorActionPreference = "Stop"

$bundleName = "m10-03-image-metadata"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m10_03_realworld_build"
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

function New-PhotoEvidence {
    param([string]$OutputPath)

    # Minimal JPEG payload (valid header/footer) for realistic binary evidence.
    $hex = @(
        0xFF,0xD8,0xFF,0xE0,0x00,0x10,0x4A,0x46,0x49,0x46,0x00,0x01,0x01,0x01,0x00,0x60,
        0x00,0x60,0x00,0x00,0xFF,0xDB,0x00,0x43,0x00,0x08,0x06,0x06,0x07,0x06,0x05,0x08,
        0x07,0x07,0x07,0x09,0x09,0x08,0x0A,0x0C,0x14,0x0D,0x0C,0x0B,0x0B,0x0C,0x19,0x12,
        0x13,0x0F,0x14,0x1D,0x1A,0x1F,0x1E,0x1D,0x1A,0x1C,0x1C,0x20,0x24,0x2E,0x27,0x20,
        0x22,0x2C,0x23,0x1C,0x1C,0x28,0x37,0x29,0x2C,0x30,0x31,0x34,0x34,0x34,0x1F,0x27,
        0x39,0x3D,0x38,0x32,0x3C,0x2E,0x33,0x34,0x32,0xFF,0xD9
    )
    [byte[]]$bytes = $hex
    Write-BytesFile -Path $OutputPath -Bytes $bytes
}

function New-ImageInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,file_id,file_name,size_bytes,source_device,ingest_status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $devices = @("cam-proxy-01","cam-proxy-02","mobile-sync-01","mobile-sync-02")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $fid = "IMG" + ("{0:D8}" -f (30000000 + $i))
        $name = "photo_" + ("{0:D5}" -f (60000 + $i)) + ".jpg"
        $size = 120000 + (($i * 87) % 9200000)
        $device = $devices[$i % $devices.Count]
        $status = if (($i % 211) -eq 0) { "needs_metadata_scan" } else { "indexed" }
        $lines.Add("$ts,$fid,$name,$size,$device,$status")
    }

    $lines.Add("2026-03-08T01:36:12Z,IMG39999991,photo.jpg,356712,mobile-sync-02,needs_metadata_scan")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ExifScanLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $models = @("Samsung S23","Pixel 8","iPhone 12","Nikon D5600","Sony A6400","Canon EOS 200D")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $name = "photo_" + ("{0:D5}" -f (62000 + $i)) + ".jpg"
        $model = $models[$i % $models.Count]
        $os = if ($model.StartsWith("iPhone")) { "iOS" } else { "mixed" }
        $lines.Add("$ts exif_scan file=$name camera_model=`"$model`" os=$os status=ok")
    }

    $lines.Add("2026-03-08T01:36:16Z exif_scan file=photo.jpg camera_model=`"iPhone 13`" os=iOS status=ok")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-XmpParseJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            file = "photo_" + ("{0:D5}" -f (70000 + $i)) + ".jpg"
            xmp = [ordered]@{
                creatorTool = "Mobile Pipeline"
                deviceModel = "Device-" + ("{0:D4}" -f ($i % 3000))
            }
            confidence = [math]::Round((0.15 + (($i % 70) / 100)), 2)
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T01:36:18Z"
        file = "photo.jpg"
        xmp = [ordered]@{
            creatorTool = "Mobile Pipeline"
            deviceModel = "iPhone 13"
        }
        confidence = 0.99
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DeviceFingerprintCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,file_name,fingerprint_hash,candidate_device,confidence,engine")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $cands = @("iPhone 12","Pixel 7","Samsung S22","iPhone 11","OnePlus 11")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $name = "img_" + ("{0:D6}" -f (800000 + $i)) + ".jpg"
        $hash = ("{0:x32}" -f (910000 + $i))
        $cand = $cands[$i % $cands.Count]
        $conf = [math]::Round((0.2 + (($i % 60) / 100)), 2)
        $lines.Add("$ts,$name,$hash,$cand,$conf,dev-fp-v3")
    }

    $lines.Add("2026-03-08T01:36:21Z,photo.jpg,4cb02c22f42d91654bde98f9ac63a5e1,iPhone 13,0.99,dev-fp-v3")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 229) -eq 0) { "image-device-quality-check" } else { "image-forensics-heartbeat" }
        $sev = if ($evt -eq "image-device-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,dfir-image-siem-01,$sev,image device attribution pipeline heartbeat")
    }

    $lines.Add("2026-03-08T01:36:24Z,device_confirmed,dfir-image-siem-01,high,target photo device resolved as iPhone 13")
    $lines.Add("2026-03-08T01:36:30Z,ctf_answer_ready,dfir-image-siem-01,high,submit iPhone_13")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-MetadataPreview {
    param([string]$OutputPath)

    $content = @'
Metadata:
Camera: iPhone 13
Date: 2024-05-10
Location: Office
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
Forensics Case Notes (Extract)

Objective:
Identify acquisition device from image metadata for target photo.jpg.

Validation rule:
Correlate EXIF scan, XMP parsing, fingerprinting, and SIEM confirmation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Intel Snapshot

Target photo attribution currently maps to an Apple mobile device.
Consensus model: iPhone 13
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M10-03 Image Metadata (Real-World Investigation Pack)

Scenario:
Photo evidence contains metadata that can identify acquisition device details.

Task:
Analyze the evidence pack and identify the device used.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-6003
Severity: Medium
Queue: DFIR

Summary:
Identify capture device for recovered image photo.jpg.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate image inventory, EXIF scan logs, XMP parse output,
  device fingerprint records, SIEM timeline, and intel notes.
- Identify device used to capture photo.jpg.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-PhotoEvidence -OutputPath (Join-Path $bundleRoot "evidence\photo.jpg")
New-MetadataPreview -OutputPath (Join-Path $bundleRoot "evidence\forensics\metadata_preview.txt")
New-ImageInventory -OutputPath (Join-Path $bundleRoot "evidence\forensics\image_inventory.csv")
New-ExifScanLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\exif_scan.log")
New-XmpParseJsonl -OutputPath (Join-Path $bundleRoot "evidence\forensics\xmp_parse.jsonl")
New-DeviceFingerprintCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\device_fingerprint.csv")
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
