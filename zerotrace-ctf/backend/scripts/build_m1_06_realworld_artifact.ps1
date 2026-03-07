param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-06-github-secret-leak"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_06_realworld_build"
$bundleRoot = Join-Path $buildRoot $bundleName

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

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
    param(
        [string]$Path,
        [System.Collections.Generic.List[string]]$Lines
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    [System.IO.File]::WriteAllLines($Path, $Lines, [System.Text.Encoding]::UTF8)
}

function New-GitHistoryLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T19:00:00", [DateTimeKind]::Utc)
    $authors = @(
        "Rahul Dev <rahul.dev@company.local>",
        "Anitha S <anitha.s@company.local>",
        "Build Bot <build.bot@company.local>",
        "Vivek Ops <vivek.ops@company.local>",
        "Priya QA <priya.qa@company.local>"
    )
    $messages = @(
        "Refactor billing worker retry logic",
        "Harden API timeout defaults",
        "Update deployment pipeline labels",
        "Fix flaky integration test seed data",
        "Rotate staging webhook endpoint",
        "Add invoice export metrics"
    )

    for ($i = 0; $i -lt 12500; $i++) {
        $ts = $base.AddSeconds($i * 13)
        $author = $authors[$i % $authors.Count]
        $msg = $messages[$i % $messages.Count]
        $sha = ("{0:x8}" -f $i) + "a3f9b0c1d2e3f4a5b6c7d8e9f0a1b2c3"
        $lines.Add("commit $sha")
        $lines.Add("Author: $author")
        $lines.Add("Date:   $($ts.ToString('ddd MMM dd HH:mm:ss yyyy K', [System.Globalization.CultureInfo]::InvariantCulture))")
        $lines.Add("")
        $lines.Add("    $msg")
        $lines.Add("")
    }

    # Incident commit
    $lines.Add("commit 48df8c1a92f08d5f213b8c7f5e6b0aa4c431d901")
    $lines.Add("Author: Rahul Dev <rahul.dev@company.local>")
    $lines.Add("Date:   Fri Mar 06 08:41:09 2026 +0530")
    $lines.Add("")
    $lines.Add("    Prepare billing sync configuration for production rollout")
    $lines.Add("")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GitPushEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,repository,actor,event,ref,commit_sha,source_ip,auth_method,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T19:20:00", [DateTimeKind]::Utc)
    $actors = @("rahul.dev","anitha.s","build.bot","vivek.ops","priya.qa")
    $ips = @("10.31.4.11","10.31.4.14","10.31.4.19","10.31.4.27","10.31.4.40")

    for ($i = 0; $i -lt 13200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $actor = $actors[$i % $actors.Count]
        $ip = $ips[$i % $ips.Count]
        $sha = ("{0:x8}" -f (500000 + $i)) + "f0e1d2c3b4a5968778695a4b3c2d1e0f"
        $event = if (($i % 37) -eq 0) { "pull_request.synchronize" } else { "repo.push" }
        $note = if ($event -eq "pull_request.synchronize") { "routine branch update" } else { "normal commit push" }
        $lines.Add("$ts,company-internal/billing-service,$actor,$event,refs/heads/main,$sha,$ip,oauth_token,$note")
    }

    # False positive test token event
    $lines.Add("2026-03-06T03:05:44Z,company-internal/billing-service,priya.qa,repo.push,refs/heads/qa-sim,5ac0a3d21e6b8d2f5b1e41a0b2f9cc7a1de6aa90,10.31.4.40,oauth_token,test fixture commit with mock token string")

    # Push protection bypass followed by leaked commit
    $lines.Add("2026-03-06T03:10:28Z,company-internal/billing-service,rahul.dev,secret_scanning.push_protection_bypass,refs/heads/main,48df8c1a92f08d5f213b8c7f5e6b0aa4c431d901,10.31.4.11,oauth_token,bypass reason: i'll fix it later")
    $lines.Add("2026-03-06T03:10:31Z,company-internal/billing-service,rahul.dev,repo.push,refs/heads/main,48df8c1a92f08d5f213b8c7f5e6b0aa4c431d901,10.31.4.11,oauth_token,production env update merged")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecretScanningAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T20:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4600; $i++) {
        $ts = $base.AddSeconds($i * 41).ToString("o")
        $id = 9000 + $i
        $state = if (($i % 5) -eq 0) { "resolved" } else { "open" }
        $resolution = if ($state -eq "resolved") { "false_positive" } else { "" }
        $secretType = if (($i % 11) -eq 0) { "generic_api_key" } else { "slack_webhook_url" }
        $location = if ($secretType -eq "generic_api_key") { "tests/fixtures/sample.env:12" } else { "docs/runbook.md:88" }
        $severity = if ($state -eq "resolved") { "low" } else { "medium" }
        $entry = [ordered]@{
            alert_number = $id
            created_at = $ts
            repository = "company-internal/billing-service"
            secret_type = $secretType
            state = $state
            resolution = $resolution
            validity = "unknown"
            severity = $severity
            location = $location
            push_protection_bypassed = $false
            actor = "security-bot"
        }
        $lines.Add(($entry | ConvertTo-Json -Depth 6 -Compress))
    }

    $trueAlert = [ordered]@{
        alert_number = 12417
        created_at = "2026-03-06T03:10:40Z"
        repository = "company-internal/billing-service"
        secret_type = "aws_access_key_id,aws_secret_access_key"
        state = "open"
        resolution = ""
        validity = "active"
        severity = "critical"
        location = "config/.env.production:4-5"
        push_protection_bypassed = $true
        bypass_reason = "i'll fix it later"
        actor = "github-secret-scanning"
        linked_commit = "48df8c1a92f08d5f213b8c7f5e6b0aa4c431d901"
        linked_multi_part_alert = 12418
    }
    $lines.Add(($trueAlert | ConvertTo-Json -Depth 6 -Compress))

    $linkedAlert = [ordered]@{
        alert_number = 12418
        created_at = "2026-03-06T03:10:41Z"
        repository = "company-internal/billing-service"
        secret_type = "aws_secret_access_key"
        state = "open"
        resolution = ""
        validity = "active"
        severity = "critical"
        location = "config/.env.production:5"
        push_protection_bypassed = $true
        actor = "github-secret-scanning"
        linked_commit = "48df8c1a92f08d5f213b8c7f5e6b0aa4c431d901"
        linked_multi_part_alert = 12417
    }
    $lines.Add(($linkedAlert | ConvertTo-Json -Depth 6 -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PushProtectionAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T20:00:00", [DateTimeKind]::Utc)
    $actors = @("anitha.s","priya.qa","vivek.ops","rahul.dev")

    for ($i = 0; $i -lt 2400; $i++) {
        $ts = $base.AddSeconds($i * 63).ToString("o")
        $actor = $actors[$i % $actors.Count]
        $action = if (($i % 19) -eq 0) { "secret_scanning.push_protection_block" } else { "repo.push" }
        $entry = [ordered]@{
            created_at = $ts
            action = $action
            actor = $actor
            repository = "company-internal/billing-service"
            operation_type = "web"
            transport_protocol = "https"
            country = "IN"
            actor_ip = "10.31.4.$(11 + ($i % 30))"
        }
        $lines.Add(($entry | ConvertTo-Json -Depth 5 -Compress))
    }

    $bypass = [ordered]@{
        created_at = "2026-03-06T03:10:28Z"
        action = "secret_scanning.push_protection_bypass"
        actor = "rahul.dev"
        repository = "company-internal/billing-service"
        operation_type = "git"
        transport_protocol = "https"
        actor_ip = "10.31.4.11"
        bypass_reason = "i'll fix it later"
        blocked_secret_type = "aws_access_key_id,aws_secret_access_key"
    }
    $lines.Add(($bypass | ConvertTo-Json -Depth 5 -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudTrailEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T20:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7800; $i++) {
        $ts = $base.AddSeconds($i * 17).ToString("o")
        $entry = [ordered]@{
            eventVersion = "1.11"
            userIdentity = [ordered]@{
                type = "AssumedRole"
                principalId = "AROAU7NORMAL$i:billing-worker"
                arn = "arn:aws:sts::111122223333:assumed-role/billing-worker-role/billing-worker"
                accountId = "111122223333"
                accessKeyId = "ASIAXXXNORMALKEY$(1000 + ($i % 9000))"
                sessionContext = [ordered]@{
                    sessionIssuer = [ordered]@{
                        type = "Role"
                        arn = "arn:aws:iam::111122223333:role/billing-worker-role"
                        userName = "billing-worker-role"
                    }
                }
            }
            eventTime = $ts
            eventSource = "s3.amazonaws.com"
            eventName = if (($i % 23) -eq 0) { "ListObjectsV2" } else { "GetObject" }
            awsRegion = "ap-south-1"
            sourceIPAddress = "10.31.5.$(10 + ($i % 80))"
            userAgent = "aws-sdk-java/2.25.8 Linux/5.15"
            requestParameters = [ordered]@{
                bucketName = "invoice-prod-bucket"
                key = "daily/2026-03-05/invoice-$([int](2000 + ($i % 5000))).json"
            }
            responseElements = [ordered]@{
                x_amz_request_id = "REQ$($i.ToString('D6'))"
            }
            readOnly = $true
            eventType = "AwsApiCall"
            managementEvent = $false
            recipientAccountId = "111122223333"
            eventCategory = "Data"
        }
        $lines.Add(($entry | ConvertTo-Json -Depth 10 -Compress))
    }

    # Suspicious key usage after public exposure
    $malicious = [ordered]@{
        eventVersion = "1.11"
        userIdentity = [ordered]@{
            type = "IAMUser"
            principalId = "AIDAEXAMPLETEAM:billing-sync-user"
            arn = "arn:aws:iam::111122223333:user/billing-sync-user"
            accountId = "111122223333"
            accessKeyId = "AKIAXJ4Q8K7M2N6P4R1S"
            userName = "billing-sync-user"
        }
        eventTime = "2026-03-06T03:17:12Z"
        eventSource = "s3.amazonaws.com"
        eventName = "GetObject"
        awsRegion = "ap-south-1"
        sourceIPAddress = "45.83.22.91"
        userAgent = "aws-cli/2.15.8 Python/3.11"
        requestParameters = [ordered]@{
            bucketName = "invoice-prod-bucket"
            key = "exports/customer_pii_2026-03-06.csv"
        }
        responseElements = [ordered]@{
            x_amz_request_id = "REQMAL001"
        }
        readOnly = $true
        eventType = "AwsApiCall"
        managementEvent = $false
        recipientAccountId = "111122223333"
        eventCategory = "Data"
    }
    $lines.Add(($malicious | ConvertTo-Json -Depth 10 -Compress))

    $malicious2 = [ordered]@{
        eventVersion = "1.11"
        userIdentity = [ordered]@{
            type = "IAMUser"
            principalId = "AIDAEXAMPLETEAM:billing-sync-user"
            arn = "arn:aws:iam::111122223333:user/billing-sync-user"
            accountId = "111122223333"
            accessKeyId = "AKIAXJ4Q8K7M2N6P4R1S"
            userName = "billing-sync-user"
        }
        eventTime = "2026-03-06T03:18:00Z"
        eventSource = "sts.amazonaws.com"
        eventName = "GetCallerIdentity"
        awsRegion = "ap-south-1"
        sourceIPAddress = "45.83.22.91"
        userAgent = "aws-cli/2.15.8 Python/3.11"
        requestParameters = @{}
        responseElements = [ordered]@{
            arn = "arn:aws:iam::111122223333:user/billing-sync-user"
            userId = "AIDAEXAMPLETEAM"
            account = "111122223333"
        }
        readOnly = $true
        eventType = "AwsApiCall"
        managementEvent = $true
        recipientAccountId = "111122223333"
        eventCategory = "Management"
    }
    $lines.Add(($malicious2 | ConvertTo-Json -Depth 10 -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NormalizedFindings {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source,rule_name,severity,entity,status,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T20:10:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 21).ToString("o")
        $rule = if (($i % 13) -eq 0) { "secret_candidate_in_tests" } else { "repo_push_normal" }
        $sev = if ($rule -eq "secret_candidate_in_tests") { 25 } else { 8 }
        $status = if ($rule -eq "secret_candidate_in_tests") { "closed_false_positive" } else { "informational" }
        $note = if ($rule -eq "secret_candidate_in_tests") { "fixture token pattern" } else { "routine engineering activity" }
        $lines.Add("$ts,siem,$rule,$sev,company-internal/billing-service,$status,$note")
    }

    $lines.Add("2026-03-06T03:10:40Z,github_secret_scanning,critical_secret_exposure,95,config/.env.production:4-5,open,aws access key and secret exposed in commit")
    $lines.Add("2026-03-06T03:17:12Z,cloudtrail,credential_use_from_new_geolocation,93,AKIAXJ4Q8K7M2N6P4R1S,open,GetObject from unexpected external IP 45.83.22.91")
    $lines.Add("2026-03-06T03:20:00Z,ir,containment_action,30,billing-sync-user,in_progress,key rotation initiated")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-06 GitHub Secret Leak (Real-World Investigation Pack)

Scenario:
A developer pushed production configuration changes and bypassed push protection.
Shortly after, cloud audit telemetry showed access-key usage from an external IP.
You are provided Git history, push/audit logs, secret-scanning alerts, SIEM findings,
and CloudTrail events.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4442
Severity: Critical
Queue: AppSec + Cloud IR

Summary:
GitHub secret scanning raised a critical alert for billing-service.
A push-protection bypass was recorded just before merge into main.
CloudTrail shows post-exposure use of the same IAM access key from an external network.

Scope:
- Repository: company-internal/billing-service
- Suspected commit: 48df8c1a92f08d5f213b8c7f5e6b0aa4c431d901
- Window: 2026-03-06 03:10 UTC to 03:20 UTC

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Large background engineering activity is normal in this repo.
- Some secret alerts are known fixture false positives.
- Correlate secret-scanning, push-protection audit, and CloudTrail access-key usage.
- Focus on whether sensitive credentials were exposed and then used.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$gitShow = @'
commit 48df8c1a92f08d5f213b8c7f5e6b0aa4c431d901
Author: Rahul Dev <rahul.dev@company.local>
Date:   Fri Mar 06 08:41:09 2026 +0530

    Prepare billing sync configuration for production rollout

diff --git a/config/.env.production b/config/.env.production
index d82f19d..ec88473 100644
--- a/config/.env.production
+++ b/config/.env.production
@@ -2,3 +2,5 @@ BILLING_REGION=ap-south-1
 BILLING_BUCKET=invoice-prod-bucket
 BILLING_SYNC_ENABLED=true
+AWS_ACCESS_KEY_ID=AKIAXJ4Q8K7M2N6P4R1S
+AWS_SECRET_ACCESS_KEY=Qx7nW2e4r9T0uV3yB6kL1pR8sD5fG2hJ9mN4cY7z
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\git\git_show_leak_commit.patch") -Content $gitShow

$rotationMemo = @'
Security response memo:
1. Revoke exposed IAM access key immediately.
2. Rotate dependent credentials and redeploy workloads.
3. Remove credential material from repository history where feasible.
4. Enforce delegated bypass review for push protection.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\response\credential_rotation_plan.txt") -Content $rotationMemo

$timeline = @'
timestamp_utc,stage,observation
2026-03-06T03:10:28Z,git,push protection bypass event recorded
2026-03-06T03:10:31Z,git,commit with credential material pushed to main
2026-03-06T03:10:40Z,detection,secret scanning critical alert created
2026-03-06T03:17:12Z,cloud,external IP used leaked key for GetObject
2026-03-06T03:20:00Z,response,incident response opened and rotation started
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\response\exposure_timeline.csv") -Content $timeline

New-GitHistoryLog -OutputPath (Join-Path $bundleRoot "evidence\git\git_log_fuller.txt")
New-GitPushEvents -OutputPath (Join-Path $bundleRoot "evidence\git\push_activity_events.csv")
New-SecretScanningAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\secret_scanning_alerts.jsonl")
New-PushProtectionAudit -OutputPath (Join-Path $bundleRoot "evidence\security\github_audit_log.jsonl")
New-CloudTrailEvents -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloudtrail_events.jsonl")
New-NormalizedFindings -OutputPath (Join-Path $bundleRoot "evidence\siem\normalized_findings.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
