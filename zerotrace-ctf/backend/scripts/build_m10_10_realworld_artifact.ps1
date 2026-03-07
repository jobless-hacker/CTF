param()

$ErrorActionPreference = "Stop"

$bundleName = "m10-10-forensic-report"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m10_10_realworld_build"
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

function New-IncidentReportTxt {
    param([string]$OutputPath)

    $content = @'
Investigation Summary

Attacker alias discovered:
darktrace
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ReportPreview {
    param([string]$OutputPath)

    $content = @'
Forensic Report Preview

Attribution section references a high-confidence attacker alias.
Correlate with timelines, intel, and entity-resolution outputs.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseTimelineCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,case_id,event_type,source_system,severity,summary")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $events = @("ioc_ingested","correlation_run","artifact_scanned","intel_enriched","entity_linked","analyst_note")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $cid = "CASE-" + ("{0:D8}" -f (41000000 + $i))
        $evt = $events[$i % $events.Count]
        $sev = if (($i % 227) -eq 0) { "medium" } else { "low" }
        $summary = if ($sev -eq "medium") { "requires attribution review" } else { "pipeline normal" }
        $lines.Add("$ts,$cid,$evt,forensics-core,$sev,$summary")
    }

    $lines.Add("2026-03-08T03:20:10Z,CASE-49999991,attribution_locked,forensics-core,high,attacker_alias=darktrace")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EntityResolutionLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $aliases = @("noisefox","silentmesh","deltafog","ghostproxy","nightwire")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $alias = $aliases[$i % $aliases.Count]
        $conf = [math]::Round((0.07 + (($i % 50) / 100)), 2)
        $lines.Add("$ts entity_resolution candidate_alias=$alias confidence=$conf source=link-engine")
    }

    $lines.Add("2026-03-08T03:20:14Z entity_resolution candidate_alias=darktrace confidence=0.99 source=link-engine status=confirmed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IntelAttributionJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            record_id = "ATTR-" + ("{0:D10}" -f (5200000000 + $i))
            threat_cluster = "cluster_" + ("{0:D4}" -f ($i % 9000))
            attacker_alias = "noise_alias_" + ("{0:D5}" -f ($i % 60000))
            confidence = [math]::Round((0.16 + (($i % 70) / 100)), 2)
            source = "intel-attribution"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T03:20:18Z"
        record_id = "ATTR-9999999915"
        threat_cluster = "cluster_7712"
        attacker_alias = "darktrace"
        confidence = 0.99
        source = "intel-attribution"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AttributionMatrixCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,matrix_id,left_signal,right_signal,attribution_alias,confidence")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $mid = "MAT-" + ("{0:D9}" -f (220000000 + $i))
        $left = "ioc_" + ("{0:D6}" -f ($i % 800000))
        $right = "entity_" + ("{0:D6}" -f ($i % 800000))
        $alias = "noise_" + ("{0:D5}" -f ($i % 50000))
        $conf = [math]::Round((0.17 + (($i % 70) / 100)), 2)
        $lines.Add("$ts,$mid,$left,$right,$alias,$conf")
    }

    $lines.Add("2026-03-08T03:20:21Z,MAT-299999991,ioc_case_499,entity_case_499,darktrace,0.99")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEventsCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 283) -eq 0) { "attribution-anomaly-check" } else { "forensics-pipeline-heartbeat" }
        $sev = if ($evt -eq "attribution-anomaly-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,dfir-attribution-siem-01,$sev,attribution correlation heartbeat")
    }

    $lines.Add("2026-03-08T03:20:24Z,attacker_alias_confirmed,dfir-attribution-siem-01,high,attacker_alias=darktrace")
    $lines.Add("2026-03-08T03:20:30Z,ctf_answer_ready,dfir-attribution-siem-01,high,submit darktrace")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
Forensics Case Notes (Extract)

Objective:
Identify attacker alias from final attribution package.

Validation rule:
Correlate case timeline, entity-resolution logs, intel attribution output, attribution matrix, and SIEM confirmation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Intel Snapshot

Attribution workflow reached high-confidence attacker identity.
Primary alias candidate: darktrace
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M10-10 Forensic Report (Real-World Investigation Pack)

Scenario:
Incident response attribution records include the final attacker alias in noisy forensic telemetry.

Task:
Analyze the evidence pack and identify the attacker name.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-6010
Severity: Medium
Queue: DFIR

Summary:
Review forensic attribution package and confirm attacker alias.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate incident report, case timeline, entity-resolution logs,
  intel-attribution records, attribution matrix, SIEM events, and intel notes.
- Determine attacker alias token for submission.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-IncidentReportTxt -OutputPath (Join-Path $bundleRoot "evidence\incident_report.txt")
New-ReportPreview -OutputPath (Join-Path $bundleRoot "evidence\forensics\report_preview.txt")
New-CaseTimelineCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\case_timeline.csv")
New-EntityResolutionLog -OutputPath (Join-Path $bundleRoot "evidence\forensics\entity_resolution.log")
New-IntelAttributionJsonl -OutputPath (Join-Path $bundleRoot "evidence\forensics\intel_attribution.jsonl")
New-AttributionMatrixCsv -OutputPath (Join-Path $bundleRoot "evidence\forensics\attribution_matrix.csv")
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
