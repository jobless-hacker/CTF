param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-17-unauthorized-git-commit"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m1_17_realworld_build"
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

function New-CommitHistory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)
    $authors = @("anitha.dev","rajesh.payments","svc-release-bot","qa.user","arun.api")
    $messages = @(
        "fix: reconcile invoice rounding",
        "refactor: extract tax calculator",
        "chore: bump dependency versions",
        "test: improve payment integration tests",
        "feat: support split settlements"
    )

    for ($i = 0; $i -lt 8600; $i++) {
        $ts = $base.AddMinutes($i * 4).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $author = $authors[$i % $authors.Count]
        $hash = "{0:x40}" -f (100000000000 + $i)
        $msg = $messages[$i % $messages.Count]
        $branch = if (($i % 17) -eq 0) { "release/weekly" } else { "main" }
        $lines.Add("$ts commit=$hash author=$author branch=$branch message=""$msg""")
    }

    $lines.Add("2026-03-06T09:12:44Z commit=82hfd9a77b61c4da090f6e2a213e831d7f31a1aa author=unknown branch=main message=""hotfix: skip verification for retry traffic""")
    $lines.Add("2026-03-06T09:12:58Z commit=82hfd9a77b61c4da090f6e2a213e831d7f31a1aa parent=7b3e9ac1f7b111b29c7f51d2a0f0fd2f6a1120bb files_changed=1")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuditEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    $actors = @("anitha.dev","rajesh.payments","svc-release-bot","org-admin","qa.user")
    $actions = @("repo.clone","repo.pull","pull_request.opened","pull_request.merged","branch.protection.checked")

    for ($i = 0; $i -lt 7200; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 11).ToString("o")
            actor = $actors[$i % $actors.Count]
            action = $actions[$i % $actions.Count]
            repository = "payments-platform"
            branch = if (($i % 13) -eq 0) { "release/weekly" } else { "main" }
            result = "success"
            ip = "203.0.113.$(20 + ($i % 90))"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T09:10:41Z"
        actor = "org-admin"
        action = "branch.protection.updated"
        repository = "payments-platform"
        branch = "main"
        result = "success"
        details = "require_pull_request=false;require_signed_commits=false;temporary_hotfix_window=15m"
        ip = "10.44.3.18"
    }) | ConvertTo-Json -Compress))

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T09:12:44Z"
        actor = "unknown"
        action = "repo.push"
        repository = "payments-platform"
        branch = "main"
        commit = "82hfd9a77b61c4da090f6e2a213e831d7f31a1aa"
        result = "success"
        details = "direct push to protected branch without PR"
        ip = "45.83.22.91"
    }) | ConvertTo-Json -Compress))

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T09:13:03Z"
        actor = "org-admin"
        action = "branch.protection.updated"
        repository = "payments-platform"
        branch = "main"
        result = "success"
        details = "require_pull_request=true;require_signed_commits=true;window_closed"
        ip = "10.44.3.18"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GitServerAuthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T03:00:00", [DateTimeKind]::Utc)
    $users = @("anitha.dev","rajesh.payments","svc-release-bot","qa.user")

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $user = $users[$i % $users.Count]
        $event = if (($i % 25) -eq 0) { "token.refresh" } else { "token.validate" }
        $result = "ok"
        $ip = "198.51.100.$(10 + ($i % 100))"
        $lines.Add("$ts auth event=$event user=$user result=$result ip=$ip mfa=pass")
    }

    $lines.Add("2026-03-06T09:12:39Z auth event=token.validate user=unknown result=ok ip=45.83.22.91 mfa=not_required token_id=pat_tmp_7712")
    $lines.Add("2026-03-06T09:12:40Z auth event=session.start user=unknown result=ok ip=45.83.22.91 mfa=not_required scope=repo:write")
    $lines.Add("2026-03-06T09:12:44Z auth event=push.authorized user=unknown result=ok ip=45.83.22.91 branch=main commit=82hfd9a77b61c4da090f6e2a213e831d7f31a1aa")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SignatureVerification {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,commit,author,signature_state,key_id,verification_note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5700; $i++) {
        $ts = $base.AddMinutes($i * 3).ToString("o")
        $commit = "{0:x40}" -f (100000000000 + $i)
        $author = if (($i % 4) -eq 0) { "svc-release-bot" } else { "anitha.dev" }
        $state = "verified"
        $key = if ($author -eq "svc-release-bot") { "GPG-REL-991A" } else { "GPG-DEV-11B2" }
        $note = "signature valid"
        $lines.Add("$ts,$commit,$author,$state,$key,$note")
    }

    $lines.Add("2026-03-06T09:12:44Z,82hfd9a77b61c4da090f6e2a213e831d7f31a1aa,unknown,unverified,,commit signature missing")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CIPipelineRuns {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("run_id,started_utc,branch,commit,status,test_summary,policy_gate")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T06:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4200; $i++) {
        $start = $base.AddMinutes($i * 5).ToString("o")
        $branch = if (($i % 6) -eq 0) { "release/weekly" } else { "main" }
        $commit = "{0:x40}" -f (100000000000 + ($i % 8600))
        $status = if (($i % 101) -eq 0) { "failed" } else { "passed" }
        $summary = if ($status -eq "failed") { "3 failed / 812 passed" } else { "0 failed / 815 passed" }
        $gate = if ($status -eq "failed") { "blocked" } else { "allowed" }
        $lines.Add("CI-$((50000 + $i)),$start,$branch,$commit,$status,$summary,$gate")
    }

    $lines.Add("CI-59421,2026-03-06T09:12:48Z,main,82hfd9a77b61c4da090f6e2a213e831d7f31a1aa,passed,0 failed / 12 passed (critical suite skipped),allowed")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PRReviewEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,pr_id,event,actor,branch,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-04T07:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 3600; $i++) {
        $ts = $base.AddMinutes($i * 7).ToString("o")
        $pr = 1100 + ($i % 480)
        $event = if (($i % 3) -eq 0) { "opened" } elseif (($i % 3) -eq 1) { "review_approved" } else { "merged" }
        $actor = if ($event -eq "opened") { "anitha.dev" } elseif ($event -eq "merged") { "svc-release-bot" } else { "rajesh.payments" }
        $branch = if (($i % 11) -eq 0) { "release/weekly" } else { "main" }
        $note = "standard review flow"
        $lines.Add("$ts,PR-$pr,$event,$actor,$branch,$note")
    }

    $lines.Add("2026-03-06T09:12:44Z,PR-NA,direct_push,unknown,main,commit introduced without pull request")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ChangeCalendar {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("change_id,scheduled_utc,service,owner,approved,window_type,summary")
    $base = [datetime]::SpecifyKind([datetime]"2026-02-27T08:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 2200; $i++) {
        $ts = $base.AddMinutes($i * 15).ToString("o")
        $service = if (($i % 4) -eq 0) { "payments-platform" } else { "checkout-gateway" }
        $owner = if (($i % 2) -eq 0) { "release-management" } else { "platform-engineering" }
        $approved = "yes"
        $window = if (($i % 9) -eq 0) { "emergency" } else { "standard" }
        $summary = if ($window -eq "emergency") { "infra hotfix with rollback plan" } else { "routine deployment" }
        $lines.Add("CHG-$((77000 + $i)),$ts,$service,$owner,$approved,$window,$summary")
    }

    $lines.Add("CHG-79991,2026-03-06T09:10:00Z,payments-platform,platform-engineering,yes,emergency,temporary branch protection relaxation for hotfix verification")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-17 Unexpected Verification Logic Change (Real-World Investigation Pack)

Scenario:
Payment verification behavior changed after a direct commit reached main.
Evidence includes repository history, audit trail, git auth telemetry, signature verification,
CI runs, PR/review activity, and change-calendar context.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4526
Severity: High
Queue: AppSec + DevSecOps

Summary:
Production payments accepted transactions that should fail verification checks.
Incident review points to an unplanned commit merged directly to main without normal review.

Scope:
- Repository: payments-platform
- Suspected commit: 82hfd9a77b61c4da090f6e2a213e831d7f31a1aa
- Time window: 2026-03-06 09:10 UTC onward

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Determine whether code behavior changed by unauthorized modification.
- Confirm if commit bypassed normal PR + signature controls.
- Distinguish legitimate emergency change window metadata from abusive use.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$patch = @'
commit 82hfd9a77b61c4da090f6e2a213e831d7f31a1aa
Author: unknown
Date:   2026-03-06T09:12:44Z

    hotfix: skip verification for retry traffic

diff --git a/services/payment_verifier.py b/services/payment_verifier.py
index 0a1b94c..8ce11a0 100644
--- a/services/payment_verifier.py
+++ b/services/payment_verifier.py
@@ -118,7 +118,10 @@ def verify_payment(payload):
     checksum_ok = verify_checksum(payload)
     signature_ok = verify_signature(payload)
     amount_ok = verify_amount(payload)
-    return checksum_ok and signature_ok and amount_ok
+    # temporary bypass for retry traffic
+    if payload.get("retry", False):
+        return True
+    return checksum_ok and amount_ok
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\git\suspicious_commit.patch") -Content $patch

New-CommitHistory -OutputPath (Join-Path $bundleRoot "evidence\git\commit_history.log")
New-AuditEvents -OutputPath (Join-Path $bundleRoot "evidence\security\repo_audit_events.jsonl")
New-GitServerAuthLog -OutputPath (Join-Path $bundleRoot "evidence\security\git_server_auth.log")
New-SignatureVerification -OutputPath (Join-Path $bundleRoot "evidence\git\commit_signature_verification.csv")
New-CIPipelineRuns -OutputPath (Join-Path $bundleRoot "evidence\ci\pipeline_runs.csv")
New-PRReviewEvents -OutputPath (Join-Path $bundleRoot "evidence\reviews\pr_review_events.csv")
New-ChangeCalendar -OutputPath (Join-Path $bundleRoot "evidence\operations\change_calendar.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
