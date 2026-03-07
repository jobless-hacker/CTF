param()

$ErrorActionPreference = "Stop"

$bundleName = "m3-07-cloud-access-leak"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m3_07_realworld_build"
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

function New-LeakedConfig {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("{")
    $lines.Add("  ""environment"": ""prod"",")
    $lines.Add("  ""service"": ""reporting-api"",")
    $lines.Add("  ""region"": ""ap-south-1"",")
    $lines.Add("  ""aws_access_key"": ""AKIA12345"",")
    $lines.Add("  ""aws_secret_key"": ""XyZSecretKey987"",")
    $lines.Add("  ""db_host"": ""prod-db.company.com"",")
    $lines.Add("  ""log_level"": ""INFO""")
    $lines.Add("}")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RepoFileIndex {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,repo,path,size_bytes,classification,owner,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $paths = @("src/main.py","src/utils.py","infra/terraform/main.tf","docs/readme.md","config/app.yaml")

    for ($i = 0; $i -lt 8600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $path = $paths[$i % $paths.Count]
        $cls = if ($path -like "config/*") { "internal" } else { "public-code" }
        $owner = if (($i % 2) -eq 0) { "devops-bot" } else { "platform-team" }
        $lines.Add("$ts,org/reporting-api,$path,$((200 + (($i * 17) % 45000))),$cls,$owner,tracked")
    }

    $lines.Add("2026-03-07T14:01:32Z,org/reporting-api,config/cloud/config.json,812,confidential,anita.dev,tracked")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CommitHistory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $subjects = @(
        "update health checks",
        "refactor report cache",
        "cleanup stale env vars",
        "improve retry strategy",
        "adjust logging formatter"
    )

    for ($i = 0; $i -lt 7200; $i++) {
        $hash = "{0:x12}" -f (700000000000 + $i)
        $ts = $base.AddSeconds($i * 11).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $sub = $subjects[$i % $subjects.Count]
        $lines.Add("$hash|$ts|dev_$($i % 25)|$sub")
    }

    $lines.Add("91be7f0c12aa|2026-03-07T14:01:31Z|anita.dev|hotfix cloud config path")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CommitDiff {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $hash = "{0:x12}" -f (810000000000 + $i)
        $ts = $base.AddSeconds($i * 13).ToString("o")
        $lines.Add("commit $hash")
        $lines.Add("Author: dev_$($i % 30)")
        $lines.Add("Date:   $ts")
        $lines.Add("")
        $lines.Add("    routine update")
        $lines.Add("")
        $lines.Add("diff --git a/src/module_$($i % 40).py b/src/module_$($i % 40).py")
        $lines.Add("@@ -1,2 +1,2 @@")
        $lines.Add("-timeout = 20")
        $lines.Add("+timeout = 25")
        $lines.Add("")
    }

    $lines.Add("commit 91be7f0c12aa")
    $lines.Add("Author: anita.dev")
    $lines.Add("Date:   2026-03-07T14:01:31Z")
    $lines.Add("")
    $lines.Add("    added cloud runtime config")
    $lines.Add("")
    $lines.Add("diff --git a/config/cloud/config.json b/config/cloud/config.json")
    $lines.Add("@@ -1,4 +1,8 @@")
    $lines.Add("+{")
    $lines.Add("+  ""aws_access_key"": ""AKIA12345"",")
    $lines.Add("+  ""aws_secret_key"": ""XyZSecretKey987"",")
    $lines.Add("+  ""region"": ""ap-south-1""")
    $lines.Add("+}")
    $lines.Add("")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecretScannerAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,scanner,repo,commit,file_path,rule,severity,status,snippet")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $rules = @("entropy_check","generic_token","credential_pattern","cloud_key_pattern")

    for ($i = 0; $i -lt 4700; $i++) {
        $ts = $base.AddSeconds($i * 12).ToString("o")
        $rule = $rules[$i % $rules.Count]
        $sev = if (($i % 173) -eq 0) { "medium" } else { "low" }
        $lines.Add("$ts,secretwatch,org/reporting-api,$('{0:x12}' -f (910000000000 + $i)),src/file_$($i % 35).txt,$rule,$sev,closed_false_positive,placeholder")
    }

    $lines.Add("2026-03-07T14:01:33Z,secretwatch,org/reporting-api,91be7f0c12aa,config/cloud/config.json,aws_secret_key,critical,open,aws_secret_key=XyZSecretKey987")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudTrailUsage {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $events = @("ListBuckets","GetObject","DescribeInstances","GetCallerIdentity")

    for ($i = 0; $i -lt 5200; $i++) {
        $entry = [ordered]@{
            eventTime = $base.AddSeconds($i * 10).ToString("o")
            eventName = $events[$i % $events.Count]
            awsRegion = "ap-south-1"
            sourceIPAddress = "10.220.41.$(20 + ($i % 50))"
            userIdentity = "svc-reporting"
            result = "Success"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        eventTime = "2026-03-07T14:05:10Z"
        eventName = "GetCallerIdentity"
        awsRegion = "ap-south-1"
        sourceIPAddress = "185.199.110.42"
        userIdentity = "AKIA12345"
        result = "Success"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        eventTime = "2026-03-07T14:05:18Z"
        eventName = "ListBuckets"
        awsRegion = "ap-south-1"
        sourceIPAddress = "185.199.110.42"
        userIdentity = "AKIA12345"
        result = "Success"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 239) -eq 0) { "secret_review" } else { "routine_repo_activity" }
        $sev = if ($event -eq "secret_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,siem-cloud-01,$sev,baseline repo and cloud key monitoring")
    }

    $lines.Add("2026-03-07T14:01:33Z,secret_exposed_in_repo,siem-cloud-01,high,commit contains aws_secret_key in plaintext")
    $lines.Add("2026-03-07T14:05:10Z,suspicious_cloud_api_usage,siem-cloud-01,critical,external IP used leaked access key")
    $lines.Add("2026-03-07T14:05:24Z,incident_opened,siem-cloud-01,high,INC-2026-5180 cloud access key leak")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudCredentialPolicy {
    param([string]$OutputPath)

    $content = @'
Cloud Credential Security Policy (Excerpt)

1) AWS access and secret keys must not be stored in repository configuration files.
2) Any leaked cloud key material requires immediate rotation and incident response.
3) External API usage from leaked keys is a critical security event.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M3-07 Cloud Access Leak (Real-World Investigation Pack)

Scenario:
A repository configuration leak exposed cloud credential material and was followed by suspicious cloud API activity.

Task:
Analyze the investigation pack and identify the exposed AWS secret key.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5180
Severity: High
Queue: SOC + Cloud Security

Summary:
Secret scanning detected cloud credential exposure in repo config, and external cloud API usage was observed soon after.

Scope:
- Repo: org/reporting-api
- Suspect commit: 91be7f0c12aa
- Window: 2026-03-07 14:01-14:06 UTC

Deliverable:
Identify the exposed AWS secret key.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate leaked config content, commit history/diff, secret scanner findings, cloud usage logs, and SIEM timeline.
- Confirm that leaked credential material was actively abused.
- Extract the exposed AWS secret key value.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-LeakedConfig -OutputPath (Join-Path $bundleRoot "evidence\leak\config.json")
New-RepoFileIndex -OutputPath (Join-Path $bundleRoot "evidence\repo\repo_file_index.csv")
New-CommitHistory -OutputPath (Join-Path $bundleRoot "evidence\repo\commit_history.log")
New-CommitDiff -OutputPath (Join-Path $bundleRoot "evidence\repo\commit_diff.patchlog")
New-SecretScannerAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\secret_scanner_alerts.csv")
New-CloudTrailUsage -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloudtrail_usage.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CloudCredentialPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\cloud_credential_policy.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
