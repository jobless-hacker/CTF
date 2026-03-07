param()

$ErrorActionPreference = "Stop"

$bundleName = "m9-10-public-code-leak"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m9_10_realworld_build"
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

function New-RepoCommitHistory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,repo,commit_sha,author_email,author_username,message,files_changed,risk")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $repos = @("web-portal","infra-scripts","analytics-engine","docs-site")
    $users = @("buildbot","ops_svc","release_mgr","qa_automation","ci_runner")

    for ($i = 0; $i -lt 6900; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $repo = $repos[$i % $repos.Count]
        $sha = ("{0:x40}" -f (900000 + $i))
        $user = $users[$i % $users.Count]
        $mail = "$user@company.com"
        $msg = "routine update " + ("{0:D4}" -f ($i % 1500))
        $files = 1 + ($i % 14)
        $risk = if (($i % 231) -eq 0) { "medium" } else { "low" }
        $lines.Add("$ts,$repo,$sha,$mail,$user,$msg,$files,$risk")
    }

    $lines.Add("2026-03-07T23:41:05Z,web-portal,92ad8f5cbb0dd02b31ad4f99922c94f2fc06f0c1,alice.dev@company.com,alice_dev,Added API integration code,9,high")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GitAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $repos = @("web-portal","infra-scripts","analytics-engine")

    for ($i = 0; $i -lt 7400; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $repo = $repos[$i % $repos.Count]
        $actor = "user" + ("{0:D4}" -f ($i % 1200))
        $action = if (($i % 91) -eq 0) { "push_force" } else { "push" }
        $lines.Add("$ts git_audit repo=$repo actor=$actor action=$action status=ok")
    }

    $lines.Add("2026-03-07T23:41:09Z git_audit repo=web-portal actor=alice_dev action=push status=ok note=linked_public_commit")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ContributorGraph {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            repo = "repo-" + ("{0:D4}" -f ($i % 500))
            contributor = "contrib_" + ("{0:D5}" -f (70000 + $i))
            edges = 1 + ($i % 8)
            trust = if (($i % 177) -eq 0) { "review" } else { "known" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T23:41:12Z"
        repo = "web-portal"
        contributor = "alice_dev"
        edges = 14
        trust = "watch"
        tags = @("public-code-leak", "api-integration")
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CodeSearchHits {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,repo,query,match_file,match_line,author_hint,confidence")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $repo = "repo-" + ("{0:D4}" -f ($i % 600))
        $query = "api integration"
        $file = "src/module" + ($i % 90) + ".ts"
        $line = 10 + ($i % 500)
        $hint = "user" + ("{0:D4}" -f ($i % 1600))
        $conf = [math]::Round((0.1 + (($i % 75) / 100)), 2)
        $lines.Add("$ts,$repo,$query,$file,$line,$hint,$conf")
    }

    $lines.Add("2026-03-07T23:41:14Z,web-portal,api integration,src/api/integration.ts,182,alice_dev,0.99")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 233) -eq 0) { "commit-attribution-quality-check" } else { "code-osint-heartbeat" }
        $sev = if ($evt -eq "commit-attribution-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,osint-code-siem-01,$sev,public code leak enrichment heartbeat")
    }

    $lines.Add("2026-03-07T23:41:18Z,developer_identity_confirmed,osint-code-siem-01,high,public commit author username identified as alice_dev")
    $lines.Add("2026-03-07T23:41:24Z,ctf_answer_ready,osint-code-siem-01,high,submit alice_dev")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GithubCommitTxt {
    param([string]$OutputPath)

    $content = @'
commit 92ad8f

Author: alice_dev
Added API integration code
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
OSINT Case Notes (Extract)

Objective:
Identify developer username from leaked public commit artifacts.

Validation rule:
Correlate commit history, git audit, contributor graph, and SIEM timeline.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

High-confidence leaked commit attribution:
alice_dev
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M9-10 Public Code Leak (Real-World Investigation Pack)

Scenario:
Public repository artifacts may expose developer identity details.

Task:
Analyze the evidence pack and identify the developer username.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5910
Severity: Medium
Queue: SOC OSINT

Summary:
Identify developer username from leaked public code artifact trail.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate repository commit history, git audit logs, contributor graph,
  code search hits, SIEM timeline, and intel notes.
- Identify leaked developer username.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-GithubCommitTxt -OutputPath (Join-Path $bundleRoot "evidence\github_commit.txt")
New-RepoCommitHistory -OutputPath (Join-Path $bundleRoot "evidence\code\repo_commit_history.csv")
New-GitAuditLog -OutputPath (Join-Path $bundleRoot "evidence\code\git_audit.log")
New-ContributorGraph -OutputPath (Join-Path $bundleRoot "evidence\code\contributor_graph.jsonl")
New-CodeSearchHits -OutputPath (Join-Path $bundleRoot "evidence\code\code_search_hits.csv")
New-TimelineEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CaseNotes -OutputPath (Join-Path $bundleRoot "evidence\code\case_notes.txt")
New-IntelSnapshot -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
