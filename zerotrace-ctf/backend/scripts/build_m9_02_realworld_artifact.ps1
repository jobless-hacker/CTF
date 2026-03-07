param()

$ErrorActionPreference = "Stop"

$bundleName = "m9-02-suspicious-username"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m9_02_realworld_build"
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

function New-ForumUserDump {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("snapshot_time_utc,forum,username,reputation,last_seen_utc,topic_cluster,risk_score")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $forums = @("cyber-lounge","packet-lab","code-hub","net-seek")
    $clusters = @("general","malware","osint","crypto","networking","offtopic")

    for ($i = 0; $i -lt 6700; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $forum = $forums[$i % $forums.Count]
        $user = "user" + ("{0:D5}" -f (10000 + $i))
        $rep = 10 + (($i * 7) % 15000)
        $last = $base.AddSeconds($i * 9 + 3600).ToString("o")
        $cluster = $clusters[$i % $clusters.Count]
        $risk = [math]::Round((($i % 80) / 100), 2)
        $lines.Add("$ts,$forum,$user,$rep,$last,$cluster,$risk")
    }

    $lines.Add("2026-03-06T21:14:52Z,cyber-lounge,shadowfox92,4312,2026-03-06T21:13:44Z,malware,0.98")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AccountActivityLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $actions = @("login","post_created","reply_created","profile_update","logout","session_refresh")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $user = "user" + ("{0:D5}" -f (14000 + ($i % 3200)))
        $act = $actions[$i % $actions.Count]
        $ip = "198.51.100." + (($i % 210) + 10)
        $status = if (($i % 149) -eq 0) { "warning" } else { "ok" }
        $lines.Add("$ts forum-activity user=$user action=$act src_ip=$ip status=$status")
    }

    $lines.Add("2026-03-06T21:15:01Z forum-activity user=shadowfox92 action=profile_update src_ip=45.88.22.71 status=warning note=handle_seen_in_threat_forum")
    $lines.Add("2026-03-06T21:15:09Z forum-activity user=shadowfox92 action=post_created src_ip=45.88.22.71 status=warning tag=suspicious_ops_thread")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HandleCorrelation {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source,handle,alias_count,matched_entities,confidence,verdict")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $sources = @("forum-scraper-a","forum-scraper-b","social-enricher","paste-monitor")
    $verdicts = @("noise","noise","noise","low_signal","needs_review")

    for ($i = 0; $i -lt 4800; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $source = $sources[$i % $sources.Count]
        $handle = "shadow" + ("{0:D2}" -f ($i % 99))
        $aliases = 1 + ($i % 4)
        $entities = 0 + ($i % 3)
        $confidence = [math]::Round((0.12 + (($i % 35) / 100)), 2)
        $verdict = $verdicts[$i % $verdicts.Count]
        $lines.Add("$ts,$source,$handle,$aliases,$entities,$confidence,$verdict")
    }

    $lines.Add("2026-03-06T21:15:12Z,social-enricher,shadowfox92,5,3,0.99,confirmed_suspicious_handle")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EntityGraphJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            observed_at_utc = $base.AddSeconds($i * 8).ToString("o")
            entity_type = "username"
            value = "alias_" + ("{0:D5}" -f (20000 + $i))
            linked_forums = @("cyber-lounge")
            linked_ips = @("198.51.100." + (($i % 180) + 20))
            risk = if (($i % 177) -eq 0) { "medium" } else { "low" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        observed_at_utc = "2026-03-06T21:15:14Z"
        entity_type = "username"
        value = "shadowfox92"
        linked_forums = @("cyber-lounge","packet-lab")
        linked_ips = @("45.88.22.71","198.51.100.219")
        risk = "high"
        tags = @("suspicious_ops_thread","credential_trade_reference")
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 222) -eq 0) { "osint-handle-quality-check" } else { "osint-ingest-heartbeat" }
        $sev = if ($evt -eq "osint-handle-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,osint-siem-01,$sev,username enrichment pipeline heartbeat")
    }

    $lines.Add("2026-03-06T21:15:18Z,suspicious_handle_confirmed,osint-siem-01,high,high-confidence suspicious username identified as shadowfox92")
    $lines.Add("2026-03-06T21:15:25Z,ctf_answer_ready,osint-siem-01,high,submit username shadowfox92")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProfileTxt {
    param([string]$OutputPath)

    $content = @'
Forum account discovered during investigation:

username: shadowfox92
joined: 2023
posts: high-risk discussion threads
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
OSINT Case Notes (Extract)

Objective:
Identify the suspicious username consistently appearing across forum and enrichment pipelines.

Guidance:
- Validate signal across at least three sources.
- Ignore low-confidence alias collisions.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed actor handle in active monitoring set:
shadowfox92

Confidence: high
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M9-02 Suspicious Username (Real-World Investigation Pack)

Scenario:
OSINT enrichment systems detected a potentially malicious forum handle among large profile datasets.

Task:
Analyze the evidence pack and identify the suspicious username.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5902
Severity: Medium
Queue: SOC OSINT

Summary:
Potential threat actor username observed in public forums during enrichment.

Scope:
- find suspicious username from cross-source evidence
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate forum user dump, account activity, handle correlation output,
  entity graph, SIEM timeline, and intel notes.
- Identify one high-confidence suspicious username.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ProfileTxt -OutputPath (Join-Path $bundleRoot "evidence\profile.txt")
New-ForumUserDump -OutputPath (Join-Path $bundleRoot "evidence\osint\forum_user_dump.csv")
New-AccountActivityLog -OutputPath (Join-Path $bundleRoot "evidence\osint\account_activity.log")
New-HandleCorrelation -OutputPath (Join-Path $bundleRoot "evidence\osint\handle_correlation.csv")
New-EntityGraphJsonl -OutputPath (Join-Path $bundleRoot "evidence\osint\entity_graph.jsonl")
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
