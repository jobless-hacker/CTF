param()

$ErrorActionPreference = "Stop"

$bundleName = "m9-06-social-media-leak"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m9_06_realworld_build"
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

function New-SocialFeedExport {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,platform,account_id,post_id,language,hashtags,engagement_score,location_hint")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $platforms = @("X","Insta","Threads","ForumMirror")
    $hints = @("none","travel","food","gym","festival","sports","news")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $platform = $platforms[$i % $platforms.Count]
        $acct = "acct_" + ("{0:D6}" -f (300000 + $i))
        $post = "post_" + ("{0:D7}" -f (7000000 + $i))
        $hash = "#tag" + ($i % 500) + "|#topic" + ($i % 130)
        $score = [math]::Round((($i % 95) / 10), 1)
        $hint = $hints[$i % $hints.Count]
        $lines.Add("$ts,$platform,$acct,$post,en,$hash,$score,$hint")
    }

    $lines.Add("2026-03-06T23:48:18Z,X,acct_990991,post_9000123,en,#Charminar|#Hyderabad|#NightWalk,9.8,city_reference")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PostContentLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $phrases = @(
        "Great coffee stop after work.",
        "Morning run done.",
        "Traffic was heavy today.",
        "Trying a new menu this week.",
        "Heading to event setup.",
        "Weekend plans look good."
    )

    for ($i = 0; $i -lt 7200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $post = "post_" + ("{0:D7}" -f (7100000 + $i))
        $msg = $phrases[$i % $phrases.Count]
        $lines.Add("$ts content_log post_id=$post text=`"$msg`" sentiment=neutral")
    }

    $lines.Add("2026-03-06T23:48:21Z content_log post_id=post_9000123 text=`"Excited to visit Charminar today! #Hyderabad`" sentiment=positive")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HashtagAggregation {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $tags = @("fitness","events","startup","food","travel","security","devops","music")

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $tag = $tags[$i % $tags.Count]
        $count = 10 + ($i % 5000)
        $lines.Add("$ts hashtag_summary tag=#$tag mentions=$count region=india")
    }

    $lines.Add("2026-03-06T23:48:24Z hashtag_summary tag=#Hyderabad mentions=11423 region=india source=target_post_cluster")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GeolocationInference {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $cities = @("mumbai","delhi","pune","bengaluru","chennai","kolkata","unknown")

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            post_id = "post_" + ("{0:D7}" -f (7200000 + $i))
            candidate_city = $cities[$i % $cities.Count]
            confidence = [math]::Round((0.12 + (($i % 60) / 100)), 2)
            evidence = @("hashtag", "lexical")
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-06T23:48:26Z"
        post_id = "post_9000123"
        candidate_city = "hyderabad"
        confidence = 0.99
        evidence = @("hashtag", "landmark:Charminar", "language_context")
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EntityLinkGraph {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,node_a,node_b,relation,weight")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $landmarks = @("GatewayOfIndia","IndiaGate","MarinaBeach","Lalbagh","HowrahBridge")

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $nodeA = "post_" + ("{0:D7}" -f (7300000 + $i))
        $nodeB = $landmarks[$i % $landmarks.Count]
        $weight = [math]::Round((0.2 + (($i % 70) / 100)), 2)
        $lines.Add("$ts,$nodeA,$nodeB,semantic_link,$weight")
    }

    $lines.Add("2026-03-06T23:48:27Z,post_9000123,Charminar,landmark_link,0.99")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 229) -eq 0) { "geo-inference-quality-check" } else { "social-osint-heartbeat" }
        $sev = if ($evt -eq "geo-inference-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,osint-social-siem-01,$sev,social geo-context enrichment heartbeat")
    }

    $lines.Add("2026-03-06T23:48:30Z,location_confirmed,osint-social-siem-01,high,location mentioned in target post resolved as hyderabad")
    $lines.Add("2026-03-06T23:48:36Z,ctf_answer_ready,osint-social-siem-01,high,submit location hyderabad")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TweetTxt {
    param([string]$OutputPath)

    $content = @'
Excited to visit Charminar today! #Hyderabad
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
OSINT Case Notes (Extract)

Objective:
Identify city location leaked in a public social media post.

Validation rule:
Correlate direct post text, hashtag aggregation, and geo inference output.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Target post includes landmark and city clue:
Charminar + Hyderabad
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M9-06 Social Media Leak (Real-World Investigation Pack)

Scenario:
A public post may reveal sensitive location context during an OSINT investigation.

Task:
Analyze the evidence pack and identify the location mentioned.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5906
Severity: Medium
Queue: SOC OSINT

Summary:
Determine location leaked in a suspicious public social media post.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate social feed export, post content logs, hashtag aggregations,
  geo-inference outputs, entity links, SIEM timeline, and intel notes.
- Identify the location mentioned in target post.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-TweetTxt -OutputPath (Join-Path $bundleRoot "evidence\tweet.txt")
New-SocialFeedExport -OutputPath (Join-Path $bundleRoot "evidence\osint\social_feed_export.csv")
New-PostContentLog -OutputPath (Join-Path $bundleRoot "evidence\osint\post_content.log")
New-HashtagAggregation -OutputPath (Join-Path $bundleRoot "evidence\osint\hashtag_aggregation.log")
New-GeolocationInference -OutputPath (Join-Path $bundleRoot "evidence\osint\geo_inference.jsonl")
New-EntityLinkGraph -OutputPath (Join-Path $bundleRoot "evidence\osint\entity_link_graph.csv")
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
