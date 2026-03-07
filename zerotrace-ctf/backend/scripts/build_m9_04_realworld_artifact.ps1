param()

$ErrorActionPreference = "Stop"

$bundleName = "m9-04-document-metadata"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m9_04_realworld_build"
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

function New-ReportPdf {
    param([string]$OutputPath)

    $pdf = @'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 200] /Contents 4 0 R /Resources << >> >>
endobj
4 0 obj
<< /Length 56 >>
stream
BT /F1 12 Tf 40 120 Td (Internal Quarterly Report) Tj ET
endstream
endobj
5 0 obj
<< /Author (John Carter) /Title (Quarterly Risk Review) /Producer (DocPipeline) >>
endobj
xref
0 6
0000000000 65535 f
0000000010 00000 n
0000000060 00000 n
0000000120 00000 n
0000000220 00000 n
0000000340 00000 n
trailer
<< /Root 1 0 R /Size 6 /Info 5 0 R >>
startxref
430
%%EOF
'@
    Write-TextFile -Path $OutputPath -Content $pdf
}

function New-DocumentInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("snapshot_time_utc,file_name,file_type,size_bytes,owner,status,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $owners = @("ops-team","hr-team","sec-team","finance-team","legal-team")
    $classes = @("internal","restricted","public","confidential")

    for ($i = 0; $i -lt 6700; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $file = "report_" + ("{0:D5}" -f (20000 + $i)) + ".pdf"
        $size = 40000 + (($i * 91) % 950000)
        $owner = $owners[$i % $owners.Count]
        $status = if (($i % 213) -eq 0) { "needs_review" } else { "indexed" }
        $cls = $classes[$i % $classes.Count]
        $lines.Add("$ts,$file,pdf,$size,$owner,$status,$cls")
    }

    $lines.Add("2026-03-06T22:42:31Z,report.pdf,pdf,182304,sec-team,needs_review,confidential")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PdfMetadataExtractLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $authors = @("Unknown","Ops Writer","Finance Bot","Automation Service","Editorial Team")

    for ($i = 0; $i -lt 7200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $file = "report_" + ("{0:D5}" -f (25000 + $i)) + ".pdf"
        $author = $authors[$i % $authors.Count]
        $title = "Periodic Review " + ("{0:D3}" -f ($i % 400))
        $lines.Add("$ts metadata_extract file=$file author=`"$author`" title=`"$title`" status=ok")
    }

    $lines.Add("2026-03-06T22:42:38Z metadata_extract file=report.pdf author=`"John Carter`" title=`"Quarterly Risk Review`" status=ok")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DocParserJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5400; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            file = "doc-" + ("{0:D5}" -f (30000 + $i)) + ".pdf"
            meta = [ordered]@{
                author = "author-" + ("{0:D4}" -f ($i % 2300))
                producer = "DocPipeline"
            }
            risk = if (($i % 199) -eq 0) { "medium" } else { "low" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-06T22:42:41Z"
        file = "report.pdf"
        meta = [ordered]@{
            author = "John Carter"
            producer = "DocPipeline"
            title = "Quarterly Risk Review"
        }
        risk = "high"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DlpAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $file = "report_" + ("{0:D5}" -f (35000 + $i)) + ".pdf"
        $status = if (($i % 187) -eq 0) { "warning" } else { "allow" }
        $lines.Add("$ts dlp_audit file=$file pii_detected=false metadata_check=ok action=$status")
    }

    $lines.Add("2026-03-06T22:42:45Z dlp_audit file=report.pdf pii_detected=false metadata_check=author_verified action=warning note=author_name_extracted:John Carter")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 221) -eq 0) { "doc-metadata-quality-check" } else { "document-enrichment-heartbeat" }
        $sev = if ($evt -eq "doc-metadata-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,doc-siem-01,$sev,document metadata pipeline heartbeat")
    }

    $lines.Add("2026-03-06T22:42:49Z,document_author_confirmed,doc-siem-01,high,target report.pdf author resolved as John Carter")
    $lines.Add("2026-03-06T22:42:55Z,ctf_answer_ready,doc-siem-01,high,submit author John_Carter")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
OSINT Case Notes (Extract)

Objective:
Identify author metadata from target leaked document report.pdf.

Validation rule:
Correlate metadata extract logs with parser output and SIEM normalization.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Leaked document under review: report.pdf
Latest metadata attribution: John Carter
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M9-04 Document Metadata (Real-World Investigation Pack)

Scenario:
A leaked PDF was flagged in a document triage workflow and requires author attribution.

Task:
Analyze the evidence pack and identify the author of the target document.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5904
Severity: Medium
Queue: SOC OSINT

Summary:
Author attribution required for leaked file report.pdf.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate document inventory, metadata extraction logs, parser output,
  DLP audit trail, SIEM timeline, and intel notes.
- Identify author of report.pdf.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ReportPdf -OutputPath (Join-Path $bundleRoot "evidence\report.pdf")
New-DocumentInventory -OutputPath (Join-Path $bundleRoot "evidence\osint\document_inventory.csv")
New-PdfMetadataExtractLog -OutputPath (Join-Path $bundleRoot "evidence\osint\pdf_metadata_extract.log")
New-DocParserJsonl -OutputPath (Join-Path $bundleRoot "evidence\osint\doc_parser_output.jsonl")
New-DlpAuditLog -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_audit.log")
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
