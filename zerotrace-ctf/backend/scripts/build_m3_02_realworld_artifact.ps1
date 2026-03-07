param()

$ErrorActionPreference = "Stop"

$bundleName = "m3-02-github-credentials"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m3_02_realworld_build"
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

function New-GitHistory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)
    $authors = @("anita.dev","sre-oncall","devops-bot","qa-automation","platform-team")
    $subjects = @(
        "refactor logging middleware",
        "improve connection retry handling",
        "update CI test matrix",
        "add metrics for db pool",
        "cleanup stale feature flags"
    )

    for ($i = 0; $i -lt 9800; $i++) {
        $ts = $base.AddMinutes($i * 3).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $hash = "{0:x12}" -f (400000000000 + $i)
        $author = $authors[$i % $authors.Count]
        $subject = $subjects[$i % $subjects.Count]
        $lines.Add("$hash|$ts|$author|$subject")
    }

    $lines.Add("8d39f3a1c4ef|2026-03-07T11:32:14Z|anita.dev|added database config for hotfix")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CommitDiffs {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7400; $i++) {
        $ts = $base.AddSeconds($i * 33).ToString("o")
        $hash = "{0:x12}" -f (500000000000 + $i)
        $lines.Add("commit $hash")
        $lines.Add("Author: dev_$($i % 20)")
        $lines.Add("Date:   $ts")
        $lines.Add("")
        $lines.Add("    routine update")
        $lines.Add("")
        $lines.Add("diff --git a/src/module_$($i % 30).py b/src/module_$($i % 30).py")
        $lines.Add("@@ -10,2 +10,2 @@")
        $lines.Add("-timeout = 30")
        $lines.Add("+timeout = 35")
        $lines.Add("")
    }

    $lines.Add("commit 8d39f3a1c4ef")
    $lines.Add("Author: anita.dev")
    $lines.Add("Date:   2026-03-07T11:32:14Z")
    $lines.Add("")
    $lines.Add("    Added database configuration for emergency reconnect")
    $lines.Add("")
    $lines.Add("diff --git a/config/db.env b/config/db.env")
    $lines.Add("@@ -1,3 +1,4 @@")
    $lines.Add(" DB_HOST=prod-db.company.com")
    $lines.Add(" DB_USER=admin")
    $lines.Add("+DB_PASSWORD=SuperSecret123")
    $lines.Add(" DB_PORT=5432")
    $lines.Add("")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecretScannerFindings {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,scanner,repo,branch,commit_hash,file_path,rule,severity,status,snippet")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $rules = @("generic_api_key","private_token","suspicious_entropy","basic_auth_string")

    for ($i = 0; $i -lt 4600; $i++) {
        $ts = $base.AddSeconds($i * 17).ToString("o")
        $rule = $rules[$i % $rules.Count]
        $sev = if (($i % 151) -eq 0) { "medium" } else { "low" }
        $lines.Add("$ts,secretwatch,org/crm-sync,main,$('{0:x12}' -f (610000000000 + $i)),src/file_$($i % 40).txt,$rule,$sev,closed_false_positive,placeholder_string")
    }

    $lines.Add("2026-03-07T11:33:01Z,secretwatch,org/crm-sync,main,8d39f3a1c4ef,config/db.env,database_password,critical,open,DB_PASSWORD=SuperSecret123")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CiPipelineLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 19).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $lines.Add("$ts [pipeline] INFO build step $($i % 12) completed")
    }

    $lines.Add("2026-03-07T11:33:00.411Z [secretwatch] WARN potential_secret file=config/db.env commit=8d39f3a1c4ef")
    $lines.Add("2026-03-07T11:33:00.992Z [secretwatch] ERROR database_password_exposed snippet=DB_PASSWORD=SuperSecret123")
    $lines.Add("2026-03-07T11:33:01.330Z [pipeline] FAIL security gate blocked deployment")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RepoIssueTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,actor,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 11).ToString("o")
        $event = if (($i % 223) -eq 0) { "security_review" } else { "repo_activity" }
        $sev = if ($event -eq "security_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,repo-bot,$sev,routine repository telemetry")
    }

    $lines.Add("2026-03-07T11:32:14Z,commit_pushed,anita.dev,high,commit 8d39f3a1c4ef pushed to main")
    $lines.Add("2026-03-07T11:33:00Z,secret_scanner_hit,secretwatch,critical,db.env contains plaintext database password")
    $lines.Add("2026-03-07T11:33:08Z,incident_opened,soc-automation,high,INC-2026-5002 github credential leak")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecureDevPolicy {
    param([string]$OutputPath)

    $content = @'
Secure Development Policy (Excerpt)

1) Credentials must never be committed to source control.
2) Secrets must be injected through approved vault integrations.
3) Any plaintext credential in repository files is a critical violation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M3-02 GitHub Credentials (Real-World Investigation Pack)

Scenario:
Security monitoring detected that a developer commit likely exposed database credentials in a public repository.

Task:
Analyze the investigation pack and identify the leaked database password.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5002
Severity: High
Queue: SOC + AppSec

Summary:
A commit to `org/crm-sync` triggered secret scanner alerts indicating a plaintext credential in repository history.

Scope:
- Repo: org/crm-sync
- Suspect commit: 8d39f3a1c4ef
- Detection window: 2026-03-07 11:32-11:34 UTC

Deliverable:
Identify the leaked database password.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate git history, commit diffs, secret scanner findings, CI logs, and issue timeline.
- Confirm that the detected secret is a real database credential leak.
- Extract the leaked DB password value.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-GitHistory -OutputPath (Join-Path $bundleRoot "evidence\repo\git_history.log")
New-CommitDiffs -OutputPath (Join-Path $bundleRoot "evidence\repo\commit_diffs.patchlog")
New-SecretScannerFindings -OutputPath (Join-Path $bundleRoot "evidence\security\secret_scanner_findings.csv")
New-CiPipelineLog -OutputPath (Join-Path $bundleRoot "evidence\ci\pipeline_security.log")
New-RepoIssueTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\repo_timeline.csv")
New-SecureDevPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\secure_dev_policy.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
