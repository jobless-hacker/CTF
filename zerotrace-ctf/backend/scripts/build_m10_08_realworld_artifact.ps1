param()

$ErrorActionPreference = "Stop"

$bundleName = "m10-08-hex-artifact"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m10_08_realworld_build"
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

function New-HexDumpTxt {
    param([string]$OutputPath)

    $content = @'
Recovered Hex Snippet

66 6C 61 67
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-HexPreview {
    param([string]$OutputPath)

    $content = @'
Hex Artifact Preview

Observed sequence: 66 6C 61 67
Analyst note: decode to ASCII and validate through correlated telemetry.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-MemorySegmentsCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,segment_id,process_name,offset_hex,length_bytes,hex_fragment,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $fragments = @("73 74 61 74 75 73","68 65 61 72 74","63 61 63 68 65","6F 6B","73 65 72 76 69 63 65")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $seg = "SEG-" + ("{0:D9}" -f (610000000 + $i))
        $proc = "proc_" + ("{0:D4}" -f (($i % 180) + 1))
        $offset = "0x" + ("{0:X8}" -f (8192 + ($i * 32)))
        $len = 4 + ($i % 12)
        $frag = $fragments[$i % $fragments.Count]
        $status = if (($i % 187) -eq 0) { "review" } else { "normal" }
        $lines.Add("$ts,$seg,$proc,$offset,$len,$frag,$status")
    }

    $lines.Add("2026-03-08T02:50:10Z,SEG-699999901,proc_0102,0x00FFA120,4,66 6C 61 67,review")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HexdumpCaptureLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hexRows = @(
        "00000000: 73 74 61 74 75 73",
        "00000010: 68 65 61 72 74",
        "00000020: 63 61 63 68 65",
        "00000030: 6F 6B",
        "00000040: 73 65 72 76 69 63 65"
    )

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $row = $hexRows[$i % $hexRows.Count]
        $lines.Add("$ts hexdump_capture source=mem-carver block=$("{0:D7}" -f $i) data=`"$row`"")
    }

    $lines.Add("2026-03-08T02:50:14Z hexdump_capture source=mem-carver block=9999999 data=`"0000FFA0: 66 6C 61 67`" ascii=`"flag`"")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AsciiCandidatesJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            candidate_id = "ASC-" + ("{0:D10}" -f (7300000000 + $i))
            hex = ("{0:X2} {1:X2} {2:X2}" -f (65 + ($i % 20)), (70 + ($i % 20)), (75 + ($i % 20)))
            ascii = "noise_" + ("{0:D5}" -f ($i % 40000))
            confidence = [math]::Round((0.2 + (($i % 60) / 100)), 2)
            engine = "ascii-decoder-v3"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T02:50:18Z"
        candidate_id = "ASC-9999999913"
        hex = "66 6C 61 67"
        ascii = "flag"
        confidence = 0.99
        engine = "ascii-decoder-v3"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PatternCorrelationCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,record_id,left_artifact,right_artifact,correlation_type,confidence")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $rid = "COR-" + ("{0:D9}" -f (410000000 + $i))
        $left = "hex_noise_" + ("{0:D5}" -f ($i % 50000))
        $right = "ascii_noise_" + ("{0:D5}" -f ($i % 50000))
        $type = "hex_to_ascii"
        $conf = [math]::Round((0.16 + (($i % 70) / 100)), 2)
        $lines.Add("$ts,$rid,$left,$right,$type,$conf")
    }

    $lines.Add("2026-03-08T02:50:21Z,COR-499999991,66 6C 61 67,flag,hex_to_ascii,0.99")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEventsCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 281) -eq 0) { "hex-anomaly-check" } else { "forensics-pipeline-heartbeat" }
        $sev = if ($evt -eq "hex-anomaly-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,dfir-hex-siem-01,$sev,hex decode correlation heartbeat")
    }

    $lines.Add("2026-03-08T02:50:24Z,suspicious_ascii_indicator,dfir-hex-siem-01,high,hex=66 6C 61 67 ascii=flag")
    $lines.Add("2026-03-08T02:50:30Z,ctf_answer_ready,dfir-hex-siem-01,high,submit flag")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
Forensics Case Notes (Extract)

Objective:
Decode recovered hex artifact into its ASCII word.

Validation rule:
Correlate memory segments, hexdump capture, ascii candidate decoding, pattern correlation, and SIEM confirmation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Intel Snapshot

Recovered memory hex sequence maps to a short ASCII indicator.
Primary decoded candidate: flag
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M10-08 Hex Artifact (Real-World Investigation Pack)

Scenario:
A memory-carved hex artifact requires decoding to identify a meaningful ASCII indicator.

Task:
Analyze the evidence pack and identify the ASCII word.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-6008
Severity: Medium
Queue: DFIR

Summary:
Investigate hex artifact from memory carve and determine decoded ASCII word.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate base hex dump, memory segments, hexdump capture logs,
  ASCII candidate decoding, pattern correlation output, SIEM events, and intel notes.
- Determine final ASCII token for submission.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-HexDumpTxt -OutputPath (Join-Path $bundleRoot "evidence\hex_dump.txt")
New-HexPreview -OutputPath (Join-Path $bundleRoot "evidence\forensics\hex_preview.txt")
New-MemorySegmentsCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\memory_segments.csv")
New-HexdumpCaptureLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\hexdump_capture.log")
New-AsciiCandidatesJsonl -OutputPath (Join-Path $bundleRoot "evidence\forensics\ascii_candidates.jsonl")
New-PatternCorrelationCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\pattern_correlation.csv")
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
