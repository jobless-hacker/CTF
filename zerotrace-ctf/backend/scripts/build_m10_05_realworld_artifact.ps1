param()

$ErrorActionPreference = "Stop"

$bundleName = "m10-05-base64-artifact"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m10_05_realworld_build"
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

function New-EncodedTxt {
    param([string]$OutputPath)

    $content = @'
indicator_id=ENC-1105
encoding=base64
payload=YXR0YWNr
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-DecodeQueueCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,job_id,source,encoded_fragment,decoder,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $fragments = @("c3RhdHVz","aGVhcnRiZWF0","bWV0cmljcw==","b2s=","Y2FjaGU=","c2VydmljZQ==","Y29ubmVjdA==")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $job = "DQ-" + ("{0:D9}" -f (600000000 + $i))
        $src = "collector-" + ("{0:D3}" -f (($i % 88) + 1))
        $frag = $fragments[$i % $fragments.Count]
        $status = if (($i % 173) -eq 0) { "queued_for_retry" } else { "decoded" }
        $lines.Add("$ts,$job,$src,$frag,b64-pipeline-v2,$status")
    }

    $lines.Add("2026-03-08T02:05:10Z,DQ-699999901,collector-021,YXR0YWNr,b64-pipeline-v2,decoded")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-B64ScanLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $candidates = @("c3RhdHVz","aGVhcnRiZWF0","bWV0cmljcw==","Y2FjaGU=","Y29ubmVjdA==","c2VydmljZQ==")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $cand = $candidates[$i % $candidates.Count]
        $valid = if (($i % 181) -eq 0) { "partial" } else { "valid" }
        $lines.Add("$ts b64_scan candidate=$cand validity=$valid stream=mail-gateway")
    }

    $lines.Add("2026-03-08T02:05:14Z b64_scan candidate=YXR0YWNr validity=valid stream=mail-gateway decoded=attack")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DecodeAnalyticsJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            record_id = "ANA-" + ("{0:D10}" -f (9300000000 + $i))
            encoded = "rec_" + ("{0:D5}" -f (50000 + $i))
            decoded = "noise_" + ("{0:D4}" -f ($i % 9000))
            confidence = [math]::Round((0.21 + (($i % 60) / 100)), 2)
            source = "decode-analytics"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T02:05:18Z"
        record_id = "ANA-9999999911"
        encoded = "YXR0YWNr"
        decoded = "attack"
        confidence = 0.99
        source = "decode-analytics"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CorrelationCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,artifact_id,correlation_type,left_value,right_value,confidence")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $artifact = "ART-" + ("{0:D8}" -f (71000000 + $i))
        $left = "token_" + ("{0:D5}" -f ($i % 33000))
        $right = "mapped_" + ("{0:D5}" -f ($i % 33000))
        $confidence = [math]::Round((0.15 + (($i % 70) / 100)), 2)
        $lines.Add("$ts,$artifact,decode_map,$left,$right,$confidence")
    }

    $lines.Add("2026-03-08T02:05:21Z,ART-79999991,decode_map,YXR0YWNr,attack,0.99")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEventsCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 263) -eq 0) { "decode-anomaly-check" } else { "forensics-pipeline-heartbeat" }
        $sev = if ($evt -eq "decode-anomaly-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,dfir-decode-siem-01,$sev,base64 decode telemetry pipeline heartbeat")
    }

    $lines.Add("2026-03-08T02:05:24Z,suspicious_decoded_indicator,dfir-decode-siem-01,high,encoded=YXR0YWNr decoded=attack")
    $lines.Add("2026-03-08T02:05:30Z,ctf_answer_ready,dfir-decode-siem-01,high,submit attack")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EncodedPreview {
    param([string]$OutputPath)

    $content = @'
Encoded Artifact Preview

payload=YXR0YWNr
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
Forensics Case Notes (Extract)

Objective:
Decode suspicious base64 payload extracted from investigation artifacts.

Validation rule:
Correlate decode queue records, scan logs, analytics results, correlation table, and SIEM confirmation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Intel Snapshot

Recovered encoded indicator likely maps to an operational keyword.
Primary decode candidate: attack
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M10-05 Base64 Artifact (Real-World Investigation Pack)

Scenario:
A suspicious encoded indicator was recovered from forensic telemetry.

Task:
Analyze the evidence pack and decode the encoded message.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-6005
Severity: Medium
Queue: DFIR

Summary:
Investigate encoded indicator from forensic collection and recover decoded message.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate encoded payload record, decode queue, scan logs,
  analytics output, correlation table, SIEM events, and intel summary.
- Determine decoded message token for flag submission.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-EncodedTxt -OutputPath (Join-Path $bundleRoot "evidence\encoded.txt")
New-EncodedPreview -OutputPath (Join-Path $bundleRoot "evidence\forensics\encoded_preview.txt")
New-DecodeQueueCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\decode_queue.csv")
New-B64ScanLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\b64_scan.log")
New-DecodeAnalyticsJsonl -OutputPath (Join-Path $bundleRoot "evidence\forensics\decode_analytics.jsonl")
New-CorrelationCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\correlation_matrix.csv")
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
