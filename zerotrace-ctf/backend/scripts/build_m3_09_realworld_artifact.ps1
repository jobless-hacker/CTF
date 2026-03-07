param()

$ErrorActionPreference = "Stop"

$bundleName = "m3-09-archive-leak"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m3_09_realworld_build"
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

function New-DocRegistry {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,doc_id,file_name,owner,classification,department,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $classes = @("internal","restricted","public","internal","internal")
    $depts = @("finance","operations","product","hr","strategy")

    for ($i = 0; $i -lt 8600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $doc = "DOC-{0:D7}" -f (4300000 + $i)
        $name = "doc_$($i % 900)_v$((($i % 4) + 1)).pdf"
        $owner = "user_$($i % 120)"
        $cls = $classes[$i % $classes.Count]
        $dept = $depts[$i % $depts.Count]
        $lines.Add("$ts,$doc,$name,$owner,$cls,$dept,active")
    }

    $lines.Add("2026-03-07T15:11:10Z,DOC-9990102,company_strategy.docx,ceo.office,restricted,strategy,active")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ArchiveManifest {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# breach_archive manifest")
    $lines.Add("# format: path,size_bytes,sha1")

    for ($i = 0; $i -lt 7400; $i++) {
        $path = "archive/batch_$([int]($i / 100))/report_$($i % 100).pdf"
        $size = 20000 + (($i * 17) % 900000)
        $sha = "{0:x40}" -f (120000000000000000 + $i)
        $lines.Add("$path,$size,$sha")
    }

    $lines.Add("archive/top/customer_list.xlsx,128811,5f1f4a4a19dcd000000000000000000000000001")
    $lines.Add("archive/top/contracts.pdf,238944,5f1f4a4a19dcd000000000000000000000000002")
    $lines.Add("archive/top/company_strategy.docx,94421,5f1f4a4a19dcd000000000000000000000000003")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ExtractionLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $tools = @("7z","unzip","forensic-extract","bulk_unpack")

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $tool = $tools[$i % $tools.Count]
        $status = if (($i % 127) -eq 0) { "warning" } else { "ok" }
        $lines.Add("$ts INFO tool=$tool file=part_$($i % 50).zip extracted=$((4 + $i) % 120) status=$status")
    }

    $lines.Add("2026-03-07T15:11:12Z INFO tool=forensic-extract file=breach_archive.zip extracted=3 status=ok")
    $lines.Add("2026-03-07T15:11:12Z INFO extracted_file=customer_list.xlsx")
    $lines.Add("2026-03-07T15:11:12Z INFO extracted_file=contracts.pdf")
    $lines.Add("2026-03-07T15:11:12Z INFO extracted_file=company_strategy.docx")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DownloadLogs {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,uri,method,http_status,bytes,user_agent")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $ip = "10.90.$(20 + ($i % 40)).$((30 + $i) % 220)"
        $uri = "/public/files/file_$($i % 1200).zip"
        $status = if (($i % 91) -eq 0) { 404 } else { 200 }
        $bytes = 500 + (($i * 31) % 2000000)
        $ua = if (($i % 2) -eq 0) { "Mozilla/5.0" } else { "python-requests/2.32.0" }
        $lines.Add("$ts,$ip,$uri,GET,$status,$bytes,$ua")
    }

    $lines.Add("2026-03-07T15:11:16Z,185.199.110.42,/public/leaks/breach_archive.zip,GET,200,392110,python-requests/2.32.0")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DlpAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("pii_scan","keyword_scan","doc_classification_mismatch","hash_watchlist")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "dlp-" + ("{0:D8}" -f (62000000 + $i))
            severity = if (($i % 149) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_false_positive"
            file = "doc_$($i % 500).txt"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T15:11:14Z"
        alert_id = "dlp-88881234"
        severity = "critical"
        type = "restricted_doc_exposed"
        status = "open"
        file = "company_strategy.docx"
        details = "restricted strategy document found in externally downloaded breach archive"
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
        $evt = if (($i % 271) -eq 0) { "archive_triage_review" } else { "routine_data_protection_monitoring" }
        $sev = if ($evt -eq "archive_triage_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-dlp-01,$sev,background security monitoring")
    }

    $lines.Add("2026-03-07T15:11:14Z,restricted_doc_identified,siem-dlp-01,high,company_strategy.docx present in breach archive")
    $lines.Add("2026-03-07T15:11:16Z,external_download_confirmed,siem-dlp-01,critical,archive downloaded from external IP 185.199.110.42")
    $lines.Add("2026-03-07T15:11:20Z,incident_opened,siem-dlp-01,high,INC-2026-5237 archive leak investigation started")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Document Classification Policy (Excerpt)

1) Restricted strategy documents must never be present in externally shareable archives.
2) Any breach archive containing restricted strategy material is a critical incident.
3) Security teams must identify exact exposed filenames during triage.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-TriageNotes {
    param([string]$OutputPath)

    $content = @'
DFIR Triage Notes

- Recovered object: breach_archive.zip
- Extraction shows 3 high-interest files:
  customer_list.xlsx
  contracts.pdf
  company_strategy.docx
- Next step: confirm document classification and external access telemetry.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-NestedBreachArchive {
    param([string]$OutputZip)

    $tmp = Join-Path $buildRoot "nested_breach_archive"
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null

    Write-TextFile -Path (Join-Path $tmp "customer_list.xlsx") -Content "placeholder spreadsheet content"
    Write-TextFile -Path (Join-Path $tmp "contracts.pdf") -Content "placeholder contract content"
    Write-TextFile -Path (Join-Path $tmp "company_strategy.docx") -Content "restricted strategy document placeholder"

    if (Test-Path $OutputZip) {
        Remove-Item -Force $OutputZip
    }
    Compress-Archive -Path (Join-Path $tmp "*") -DestinationPath $OutputZip -Force
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M3-09 Archive Leak (Real-World Investigation Pack)

Scenario:
A recovered breach archive may contain restricted strategic company material mixed with normal business files.

Task:
Analyze the investigation pack and identify the strategic company document filename.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5237
Severity: High
Queue: SOC + DLP + DFIR

Summary:
External download telemetry and DLP alerts indicate restricted documents may be present in a leaked archive.

Scope:
- Artifact: breach_archive.zip
- Window: 2026-03-07 15:11-15:12 UTC
- Goal: identify exact strategic document name exposed in archive
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate archive manifest, extraction logs, document registry, DLP alerts, download logs, and SIEM timeline.
- Confirm which strategic document was exposed.
- Submit only the filename.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-DocRegistry -OutputPath (Join-Path $bundleRoot "evidence\registry\document_registry.csv")
New-ArchiveManifest -OutputPath (Join-Path $bundleRoot "evidence\archive\breach_archive_manifest.txt")
New-ExtractionLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\archive_extraction.log")
New-DownloadLogs -OutputPath (Join-Path $bundleRoot "evidence\storage\public_download_logs.csv")
New-DlpAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_archive_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\document_classification_policy.txt")
New-TriageNotes -OutputPath (Join-Path $bundleRoot "evidence\forensics\triage_notes.txt")
New-NestedBreachArchive -OutputZip (Join-Path $bundleRoot "evidence\archive\breach_archive.zip")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
