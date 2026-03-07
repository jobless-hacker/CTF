param()

$ErrorActionPreference = "Stop"

$bundleName = "m7-04-broken-authentication"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m7_04_realworld_build"
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

function New-AuthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("alice","bob","charlie","dev01","support01")
    $srcIps = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78","157.49.12.90")

    for ($i = 0; $i -lt 9200; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("o")
        $user = $users[$i % $users.Count]
        $src = $srcIps[$i % $srcIps.Count]
        $result = if (($i % 17) -eq 0) { "login_failed" } else { "login_success" }
        $mfa = if (($i % 11) -eq 0) { "challenge_required" } else { "not_required" }
        $lines.Add("$ts auth-gateway user=$user src_ip=$src result=$result method=password mfa=$mfa policy=standard")
    }

    for ($j = 0; $j -lt 10; $j++) {
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-08T09:20:00", [DateTimeKind]::Utc).AddSeconds($j * 6).ToString("o")
        $result = if ($j -lt 9) { "login_failed" } else { "login_success" }
        $lines.Add("$ts auth-gateway user=admin src_ip=185.191.171.88 result=$result method=password mfa=not_enabled policy=legacy-admin")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LoginDebugLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("alice","bob","charlie","dev01")
    $passwordLabels = @("masked","masked","masked","masked")

    for ($i = 0; $i -lt 5300; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $user = $users[$i % $users.Count]
        $pw = $passwordLabels[$i % $passwordLabels.Count]
        $lines.Add("$ts auth-debug request_id=req-$i username=$user password=$pw validation=ok")
    }

    $lines.Add("2026-03-08T09:20:54Z auth-debug request_id=req-admin-991 username=admin password=admin validation=accepted note=debug_logging_exposed_credential")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")
    $paths = @("/login","/dashboard","/profile","/docs")

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
        $ip = $ips[$i % $ips.Count]
        $path = $paths[$i % $paths.Count]
        $status = if (($i % 91) -eq 0) { 401 } else { 200 }
        $bytes = 700 + (($i * 17) % 12000)
        $lines.Add("$ip - - [$ts] `"POST $path HTTP/1.1`" $status $bytes")
    }

    $attackTs = [datetime]::SpecifyKind([datetime]"2026-03-08T09:20:54", [DateTimeKind]::Utc).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
    $lines.Add("185.191.171.88 - - [$attackTs] `"POST /login HTTP/1.1`" 200 1031")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PasswordPolicyAudit {
    param([string]$OutputPath)

    $content = @'
Password Policy Audit Snapshot

Policy set: legacy-admin
- Minimum length: 4
- Complexity requirement: disabled
- Dictionary password check: disabled
- Password rotation: optional
- MFA for admin accounts: disabled

Policy set: standard
- Minimum length: 10
- Complexity requirement: enabled
- Dictionary password check: enabled
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-BruteforceSummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,username,attempts,successes,last_candidate,classification,sensor")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")
    $users = @("alice","bob","charlie","dev01")

    for ($i = 0; $i -lt 5500; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $user = $users[$i % $users.Count]
        $attempts = 1 + ($i % 8)
        $succ = if (($i % 17) -eq 0) { 1 } else { 0 }
        $lines.Add("$ts,$ip,$user,$attempts,$succ,masked,baseline,auth-analytics-01")
    }

    $lines.Add("2026-03-08T09:20:54Z,185.191.171.88,admin,10,1,admin,weak_password_suspected,auth-analytics-01")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("login-failure-watch","credential-pattern-watch","auth-policy-watch","admin-auth-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "auth-" + ("{0:D8}" -f (99100000 + $i))
            severity = if (($i % 173) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine authentication anomaly monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T09:20:55Z"
        alert_id = "auth-99169995"
        severity = "critical"
        type = "authentication_weakness_detected"
        status = "open"
        source_ip = "185.191.171.88"
        username = "admin"
        weakness = "weak_password"
        evidence = "admin account accepted password=admin"
        detail = "legacy policy allows weak default credential"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $evt = if (($i % 263) -eq 0) { "auth-risk-review" } else { "normal-auth-monitoring" }
        $sev = if ($evt -eq "auth-risk-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-auth-01,$sev,authentication baseline monitoring")
    }

    $lines.Add("2026-03-08T09:20:55Z,admin_credential_weakness_confirmed,siem-auth-01,high,admin account accepted low-strength credential")
    $lines.Add("2026-03-08T09:21:00Z,weakness_classified,siem-auth-01,critical,authentication weakness classified as weak_password")
    $lines.Add("2026-03-08T09:21:10Z,incident_opened,siem-auth-01,high,INC-2026-5704 broken authentication investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Authentication Hygiene Policy (Excerpt)

1) Weak/default passwords are prohibited for all privileged users.
2) Admin accounts must enforce complexity + dictionary checks + MFA.
3) SOC/AppSec must classify and report authentication weakness class.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Broken Authentication Triage Runbook (Excerpt)

1) Review login outcomes and admin account authentication pattern.
2) Validate password-policy configuration and exception profiles.
3) Confirm weak-credential evidence in auth/debug logs.
4) Use alerts/SIEM to classify weakness.
5) Submit weakness class and initiate credential reset + MFA enforcement.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed tactic: credential stuffing against weak/default admin passwords
High-risk credential example in incident: admin/admin
Weakness class label: weak_password
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M7-04 Broken Authentication (Real-World Investigation Pack)

Scenario:
Authentication telemetry indicates unsafe credential hygiene in admin login flow.

Task:
Analyze the investigation pack and identify the authentication weakness class.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5704
Severity: High
Queue: SOC + AppSec

Summary:
Admin authentication activity suggests weak credential acceptance.

Scope:
- Endpoint: /login
- Suspicious source: 185.191.171.88
- Objective: identify authentication weakness class
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate auth gateway logs, login debug traces, access logs, password policy audit, brute-force summary, security alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the authentication weakness class for incident closure.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-AuthLog -OutputPath (Join-Path $bundleRoot "evidence\auth\auth.log")
New-LoginDebugLog -OutputPath (Join-Path $bundleRoot "evidence\auth\login_debug.log")
New-AccessLog -OutputPath (Join-Path $bundleRoot "evidence\network\access.log")
New-PasswordPolicyAudit -OutputPath (Join-Path $bundleRoot "evidence\auth\password_policy_audit.txt")
New-BruteforceSummary -OutputPath (Join-Path $bundleRoot "evidence\security\bruteforce_summary.csv")
New-AuthAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\auth_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\authentication_hygiene_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\broken_authentication_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
