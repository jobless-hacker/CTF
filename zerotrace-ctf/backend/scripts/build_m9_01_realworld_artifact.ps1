param()

$ErrorActionPreference = "Stop"

$bundleName = "m9-01-image-metadata"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m9_01_realworld_build"
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

function New-CameraRollIndex {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("capture_time_utc,file_name,device_id,sha256,geo_tag_status,folder")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    $folders = @("DCIM/100MEDIA","DCIM/101MEDIA","DCIM/102MEDIA","DCIM/103MEDIA")
    $sha256 = [System.Security.Cryptography.SHA256]::Create()

    for ($i = 0; $i -lt 6500; $i++) {
        $ts = $base.AddSeconds($i * 11).ToString("o")
        $file = "IMG_" + ("{0:D4}" -f (2000 + $i)) + ".JPG"
        $device = "mobile-cam-" + ("{0:D2}" -f (($i % 12) + 1))
        $bytes = [Text.Encoding]::UTF8.GetBytes("img-$i-$device")
        $hashBytes = $sha256.ComputeHash($bytes)
        $hash = ([System.BitConverter]::ToString($hashBytes)).Replace("-", "").ToLower()
        $geo = if (($i % 17) -eq 0) { "true" } else { "false" }
        $folder = $folders[$i % $folders.Count]
        $lines.Add("$ts,$file,$device,$hash,$geo,$folder")
    }

    $sha256.Dispose()

    $lines.Add("2026-03-06T19:41:22Z,IMG_8842.JPG,mobile-cam-07,5b7602efb4a6cc9adf663d1a6dcf4f517ec6a11f1f7c902b53a11e250c594e38,true,DCIM/103MEDIA")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ExifBatchAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $devices = @("iPhone 12","Pixel 6","Samsung S22","Nikon D3500","Canon EOS 80D")

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $file = "IMG_" + ("{0:D4}" -f (3000 + $i)) + ".JPG"
        $cam = $devices[$i % $devices.Count]
        $lat = if (($i % 23) -eq 0) { "17." + ("{0:D4}" -f (($i * 3) % 10000)) } else { "N/A" }
        $lon = if (($i % 23) -eq 0) { "78." + ("{0:D4}" -f (($i * 7) % 10000)) } else { "N/A" }
        $lines.Add("$ts exiftool file=$file camera=`"$cam`" gps_lat=$lat gps_lon=$lon status=parsed")
    }

    $lines.Add("2026-03-06T19:44:10Z exiftool file=IMG_8842.JPG camera=`"iPhone 13`" gps_lat=17.3850 gps_lon=78.4867 status=parsed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GeotagJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $cities = @("unknown","unknown","unknown","unknown","mumbai","delhi","chennai","pune")

    for ($i = 0; $i -lt 5400; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            file = "IMG_" + ("{0:D4}" -f (4200 + $i)) + ".JPG"
            gps = [ordered]@{
                lat = if (($i % 29) -eq 0) { "17." + ("{0:D4}" -f (($i * 5) % 10000)) } else { $null }
                lon = if (($i % 29) -eq 0) { "78." + ("{0:D4}" -f (($i * 9) % 10000)) } else { $null }
            }
            city_guess = $cities[$i % $cities.Count]
            confidence = if (($i % 29) -eq 0) { 0.62 } else { 0.0 }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-06T19:44:12Z"
        file = "IMG_8842.JPG"
        gps = [ordered]@{
            lat = "17.3850"
            lon = "78.4867"
        }
        city_guess = "hyderabad"
        confidence = 0.99
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ReverseGeoLookup {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("lookup_time_utc,lat,lon,provider,city,state,country,score")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $providers = @("osm","nominatim","geoapi","maps-internal")
    $cities = @("secunderabad","hyderabad","secunderabad","hyderabad","warangal","nizamabad")

    for ($i = 0; $i -lt 4200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $lat = "17." + ("{0:D4}" -f (($i * 13) % 10000))
        $lon = "78." + ("{0:D4}" -f (($i * 17) % 10000))
        $provider = $providers[$i % $providers.Count]
        $city = $cities[$i % $cities.Count]
        $score = [math]::Round((0.51 + (($i % 40) / 100)), 2)
        $lines.Add("$ts,$lat,$lon,$provider,$city,telangana,india,$score")
    }

    $lines.Add("2026-03-06T19:44:13Z,17.3850,78.4867,osm,hyderabad,telangana,india,0.99")
    $lines.Add("2026-03-06T19:44:14Z,17.3850,78.4867,nominatim,hyderabad,telangana,india,0.98")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 211) -eq 0) { "metadata_quality_check" } else { "osint_pipeline_heartbeat" }
        $sev = if ($evt -eq "metadata_quality_check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,osint-pipeline-01,$sev,batch metadata normalization completed")
    }

    $lines.Add("2026-03-06T19:44:15Z,target_image_identified,osint-pipeline-01,medium,target file IMG_8842.JPG moved to priority analysis queue")
    $lines.Add("2026-03-06T19:44:16Z,geolocation_match_confirmed,osint-pipeline-01,high,reverse geocode confirmed city=hyderabad for lat=17.3850 lon=78.4867")
    $lines.Add("2026-03-06T19:44:20Z,ctf_answer_ready,osint-pipeline-01,high,submit city hyderabad")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-OsintCaseNotes {
    param([string]$OutputPath)

    $content = @'
OSINT Case Notes (Extract)

Lead:
Leaked image from social profile has geotag remnants.

Analyst tip:
Do not trust single provider output. Validate with at least two geocoding sources.

Target:
Find the city associated with the recovered image metadata.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Recent campaigns often leak media files with intact EXIF GPS metadata.
Recovered target image: IMG_8842.JPG
Validated city from investigation pipeline: hyderabad
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-PhotoEvidence {
    param([string]$OutputPath)

    $base64 = "/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxISEhUTEhIVFhUVFRUVFRUVFRUVFRUWFhUXFhUYHSggGBolGxUVITEhJSkrLi4uFx8zODMsNygtLisBCgoKDg0OGxAQGy0mICUvLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLf/AABEIAAEAAQMBIgACEQEDEQH/xAAXAAADAQAAAAAAAAAAAAAAAAAAAQID/8QAFhABAQEAAAAAAAAAAAAAAAAAAQAC/8QAFQEBAQAAAAAAAAAAAAAAAAAAAgP/xAAVEQEBAAAAAAAAAAAAAAAAAAABAP/aAAwDAQACEQMRAD8ArQBkA//Z"
    $bytes = [Convert]::FromBase64String($base64)
    Write-BytesFile -Path $OutputPath -Bytes $bytes
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M9-01 Image Metadata (Real-World Investigation Pack)

Scenario:
An image connected to an investigation was recovered from a public profile dump.
The SOC OSINT pipeline flagged possible location metadata.

Task:
Analyze the evidence pack and identify the city where the photo was taken.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5901
Severity: Medium
Queue: SOC OSINT

Summary:
Recovered photo may contain location metadata that can reveal a real-world city.

Scope:
- target image: IMG_8842.JPG
- objective: identify city from metadata and cross-source geolocation confirmation
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate camera roll index, EXIF parsing logs, geotag extraction output,
  reverse geocode results, SIEM timeline, and intel notes.
- Determine the final city associated with the target image.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-PhotoEvidence -OutputPath (Join-Path $bundleRoot "evidence\photo.jpg")
New-CameraRollIndex -OutputPath (Join-Path $bundleRoot "evidence\metadata\camera_roll_index.csv")
New-ExifBatchAudit -OutputPath (Join-Path $bundleRoot "evidence\metadata\exif_batch_audit.log")
New-GeotagJsonl -OutputPath (Join-Path $bundleRoot "evidence\metadata\geotag_extract.jsonl")
New-ReverseGeoLookup -OutputPath (Join-Path $bundleRoot "evidence\osint\reverse_geo_lookup.csv")
New-TimelineEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-OsintCaseNotes -OutputPath (Join-Path $bundleRoot "evidence\osint\case_notes.txt")
New-IntelSnapshot -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
