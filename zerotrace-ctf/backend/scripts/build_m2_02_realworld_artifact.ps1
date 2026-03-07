param()

$ErrorActionPreference = "Stop"

$bundleName = "m2-02-login-storm"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m2_02_realworld_build"
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

function New-FailedAuthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T04:00:00", [DateTimeKind]::Utc)
    $users = @("ops-admin","admin","devops","support","billing")
    $ips = @("10.44.8.12","10.55.6.31","10.55.6.44","49.204.22.81","117.220.14.8")
    $fails = @("bad_password","mfa_required","expired_password","invalid_totp")

    for ($i = 0; $i -lt 12800; $i++) {
        $ts = $base.AddMilliseconds($i * 790).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $user = $users[$i % $users.Count]
        $ip = $ips[$i % $ips.Count]
        $reason = $fails[$i % $fails.Count]
        $service = if (($i % 3) -eq 0) { "auth-api" } else { "portal-login" }
        $lines.Add("$ts auth failure service=$service user=$user src_ip=$ip reason=$reason")
    }

    $stormIp = "185.199.110.42"
    $guesses = @("123456","password","qwerty","letmein","admin123","welcome1","pass@123","admin","iloveyou","changeme")
    for ($j = 0; $j -lt 520; $j++) {
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-06T08:19:00", [DateTimeKind]::Utc).AddMilliseconds($j * 190).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $guess = $guesses[$j % $guesses.Count]
        $lines.Add("$ts auth failure service=portal-login user=admin src_ip=$stormIp reason=bad_password password_guess=$guess note=rapid-sequence")
    }

    $lines.Add("2026-03-06T08:20:44.118Z auth failure service=portal-login user=admin src_ip=185.199.110.42 reason=account_locked note=threshold_exceeded")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthApiAttempts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,request_id,src_ip,user,endpoint,result,http_status,attempt_no,device_fingerprint")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T04:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddMilliseconds($i * 620).ToString("o")
        $src = if (($i % 5) -eq 0) { "49.204.22.81" } else { "10.44.8.$(20 + ($i % 140))" }
        $user = if (($i % 4) -eq 0) { "ops-admin" } else { "support" }
        $result = if (($i % 61) -eq 0) { "failure" } else { "success" }
        $code = if ($result -eq "success") { 200 } else { 401 }
        $attempt = if ($result -eq "failure") { 1 + ($i % 3) } else { 1 }
        $fp = "fp-$((50000 + ($i % 1700)))"
        $lines.Add("$ts,REQ-$((910000 + $i)),$src,$user,/api/v1/login,$result,$code,$attempt,$fp")
    }

    for ($j = 0; $j -lt 330; $j++) {
        $ts = [datetime]::SpecifyKind([datetime]"2026-03-06T08:19:02", [DateTimeKind]::Utc).AddMilliseconds($j * 210).ToString("o")
        $lines.Add("$ts,REQ-$((999000 + $j)),185.199.110.42,admin,/api/v1/login,failure,401,$((1 + $j)),fp-attack-7742")
    }

    $lines.Add("2026-03-06T08:20:44.221Z,REQ-999777,185.199.110.42,admin,/api/v1/login,blocked,429,331,fp-attack-7742")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WafAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T04:00:00", [DateTimeKind]::Utc)
    $rules = @("AUTH_RATE_WARN","AUTH_HEADER_ANOMALY","LOW_REPUTATION_IP")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 6).ToString("o")
            rule = $rules[$i % $rules.Count]
            severity = if (($i % 149) -eq 0) { "medium" } else { "low" }
            src_ip = if (($i % 7) -eq 0) { "49.204.22.81" } else { "10.44.8.$(20 + ($i % 140))" }
            path = "/api/v1/login"
            action = "allow"
            note = if (($i % 149) -eq 0) { "short auth spike; no sustained pattern" } else { "baseline auth noise" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T08:19:31Z"
        rule = "AUTH_BRUTEFORCE_DETECTED"
        severity = "critical"
        src_ip = "185.199.110.42"
        path = "/api/v1/login"
        action = "rate_limited"
        note = "high-frequency failed login attempts against single account"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LockoutEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,user,src_ip,failed_attempts,lockout_state,unlock_utc,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T04:00:00", [DateTimeKind]::Utc)
    $users = @("support","ops-admin","devops")

    for ($i = 0; $i -lt 3200; $i++) {
        $ts = $base.AddSeconds($i * 15).ToString("o")
        $user = $users[$i % $users.Count]
        $src = "10.44.8.$(30 + ($i % 110))"
        $fails = 1 + ($i % 4)
        $state = if (($i % 541) -eq 0) { "temporary_lock" } else { "none" }
        $unlock = if ($state -eq "temporary_lock") { $base.AddSeconds($i * 15 + 300).ToString("o") } else { "" }
        $note = if ($state -eq "temporary_lock") { "expected typo cluster" } else { "normal auth behavior" }
        $lines.Add("$ts,$user,$src,$fails,$state,$unlock,$note")
    }

    $lines.Add("2026-03-06T08:20:44.118Z,admin,185.199.110.42,331,hard_lock,2026-03-06T09:20:44Z,sustained password-guess sequence triggered brute-force defense")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SourceContext {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("ip,country,city,asn,provider,reputation,classification")
    $lines.Add("10.44.8.12,private,internal,NA,corp-lan,trusted,internal")
    $lines.Add("10.55.6.31,private,internal,NA,corp-lan,trusted,internal")
    $lines.Add("49.204.22.81,IN,Hyderabad,AS55836,Jio,neutral,employee-home")
    $lines.Add("117.220.14.8,IN,Vijayawada,AS9829,BSNL,neutral,employee-home")
    $lines.Add("185.199.110.42,US,San Francisco,AS54113,Fastly,high-risk,known-credential-attack-source")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source,event_type,severity,user,src_ip,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T04:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4700; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $sev = if (($i % 191) -eq 0) { "medium" } else { "low" }
        $note = if ($sev -eq "medium") { "normal shift-change auth spike" } else { "baseline authentication event" }
        $lines.Add("$ts,siem,auth_activity,$sev,support,10.44.8.12,$note")
    }

    $lines.Add("2026-03-06T08:19:12Z,siem,login_failure_burst,high,admin,185.199.110.42,rapid failure sequence >100 attempts")
    $lines.Add("2026-03-06T08:19:31Z,siem,bruteforce_pattern_detected,critical,admin,185.199.110.42,dictionary-style password guesses against single account")
    $lines.Add("2026-03-06T08:20:44Z,siem,account_lockout,high,admin,185.199.110.42,hard lock applied after sustained failures")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M2-02 Login Storm (Real-World Investigation Pack)

Scenario:
Authentication monitoring detected a sustained login failure storm targeting an admin account.
Evidence includes failed-auth streams, auth API attempts, WAF alerts, account lockout records,
source reputation context, and SIEM correlation timeline.

Task:
Identify the attack type.

Flag format:
CTF{attack_type}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4610
Severity: High
Queue: SOC Triage

Summary:
Admin account login failures spiked abruptly with repeated password guesses.
Security controls eventually locked the account after sustained attempts.

Scope:
- Account: admin
- Endpoint: /api/v1/login
- Window: 2026-03-06 08:19 UTC to 08:21 UTC

Deliverable:
Identify the likely attack type.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate failure cadence, password-guess diversity, and source concentration.
- Distinguish normal auth spikes from sustained attack behavior.
- Use SIEM/WAF lockout and reputation context for final classification.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-FailedAuthLog -OutputPath (Join-Path $bundleRoot "evidence\auth\failed_auth.log")
New-AuthApiAttempts -OutputPath (Join-Path $bundleRoot "evidence\auth\auth_api_attempts.csv")
New-WafAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\waf_auth_alerts.jsonl")
New-LockoutEvents -OutputPath (Join-Path $bundleRoot "evidence\identity\account_lockouts.csv")
New-SourceContext -OutputPath (Join-Path $bundleRoot "evidence\intel\source_context.csv")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
