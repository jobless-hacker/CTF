param()

$ErrorActionPreference = "Stop"

$bundleName = "m2-09-strange-request-pattern"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m2_09_realworld_build"
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

function New-WebAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $agents = @(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "Mozilla/5.0 (X11; Linux x86_64)",
        "CorporateScanner/1.4"
    )
    $paths = @("/login","/health","/assets/main.js","/favicon.ico","/api/v1/ping")

    for ($i = 0; $i -lt 12200; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $src = "10.110.14.$(20 + ($i % 70))"
        $method = if (($i % 3) -eq 0) { "POST" } else { "GET" }
        $path = $paths[$i % $paths.Count]
        $status = if ($path -eq "/login" -and ($i % 5) -eq 0) { 401 } else { 200 }
        $ua = $agents[$i % $agents.Count]
        $bytes = 900 + (($i * 27) % 220000)
        $lines.Add("$ts src=$src method=$method path=""$path"" status=$status bytes=$bytes ua=""$ua"" xff=""""")
    }

    $lines.Add("2026-03-07T16:12:11.420Z src=203.0.113.188 method=GET path=""/login?user=admin%27%20OR%20%271%27=%271&pass=invalid"" status=302 bytes=1281 ua=""Mozilla/5.0 (Windows NT 10.0; Win64; x64)"" xff=""198.18.1.44""")
    $lines.Add("2026-03-07T16:12:14.107Z src=203.0.113.188 method=GET path=""/login?user=%27%20OR%201=1--&pass=x"" status=302 bytes=1294 ua=""Mozilla/5.0 (Windows NT 10.0; Win64; x64)"" xff=""198.18.1.44""")
    $lines.Add("2026-03-07T16:12:17.553Z src=203.0.113.188 method=GET path=""/dashboard"" status=200 bytes=14440 ua=""Mozilla/5.0 (Windows NT 10.0; Win64; x64)"" xff=""198.18.1.44""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WafAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $signals = @("anomaly_score_low","bad_bot_signature","rate_limit_soft","header_policy_mismatch")

    for ($i = 0; $i -lt 4600; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 13).ToString("o")
            waf = "waf-gw-01"
            source_ip = "10.110.14.$(20 + ($i % 70))"
            rule_id = 900000 + ($i % 400)
            rule_name = $signals[$i % $signals.Count]
            uri = "/login"
            action = "allow"
            severity = if (($i % 151) -eq 0) { "medium" } else { "low" }
            status = "closed_false_positive"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T16:12:11Z"
        waf = "waf-gw-01"
        source_ip = "203.0.113.188"
        rule_id = 942100
        rule_name = "SQL Injection Attack Detected"
        uri = "/login?user=admin%27%20OR%20%271%27=%271&pass=invalid"
        action = "log_only"
        severity = "high"
        status = "open"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T16:12:14Z"
        waf = "waf-gw-01"
        source_ip = "203.0.113.188"
        rule_id = 942101
        rule_name = "SQLi Authentication Bypass Pattern"
        uri = "/login?user=%27%20OR%201=1--&pass=x"
        action = "log_only"
        severity = "critical"
        status = "open"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthServiceLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("finance_ro","hr_readonly","ops_maya","audit_reader","deployer")

    for ($i = 0; $i -lt 7800; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("yyyy-MM-dd HH:mm:ss.fff")
        $u = $users[$i % $users.Count]
        $result = if (($i % 9) -eq 0) { "FAIL" } else { "OK" }
        $reason = if ($result -eq "FAIL") { "invalid_credentials" } else { "validated_user_password" }
        $lines.Add("$ts auth-service INFO login user=$u result=$result reason=$reason client=10.110.14.$(20 + ($i % 70))")
    }

    $lines.Add("2026-03-07 16:12:11.427 auth-service WARN login suspicious_input user=""admin' OR '1'='1"" client=203.0.113.188")
    $lines.Add("2026-03-07 16:12:11.429 auth-service ERROR auth_bypass candidate=user_clause_tautology source=legacy_query_builder")
    $lines.Add("2026-03-07 16:12:11.433 auth-service INFO login user=admin result=OK reason=legacy_query_builder client=203.0.113.188")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DatabaseAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $stmts = @(
        "SELECT id FROM users WHERE username=?",
        "SELECT id,role FROM sessions WHERE token=?",
        "SELECT count(*) FROM login_events WHERE day=?",
        "UPDATE sessions SET last_seen=? WHERE user_id=?"
    )

    for ($i = 0; $i -lt 6500; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $stmt = $stmts[$i % $stmts.Count]
        $rows = 1 + ($i % 40)
        $lines.Add("$ts db=auth_core app=auth-service user=svc_auth stmt=""$stmt"" rows=$rows status=ok")
    }

    $lines.Add("2026-03-07T16:12:11.431Z db=auth_core app=auth-service user=svc_auth stmt=""SELECT id,username,role FROM users WHERE username='admin' OR '1'='1' AND password='invalid'"" rows=1 status=ok")
    $lines.Add("2026-03-07T16:12:11.436Z db=auth_core app=auth-service user=svc_auth stmt=""SELECT * FROM users WHERE username='admin' OR '1'='1'"" rows=1 status=ok")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RequestCorpus {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("== Request Sample Corpus ==")
    $lines.Add("")
    for ($i = 0; $i -lt 2600; $i++) {
        $lines.Add("[$i] GET /login HTTP/1.1 | user=normal_user_$($i % 30)")
    }
    $lines.Add("")
    $lines.Add("== Suspicious Requests ==")
    $lines.Add("GET /login?user=admin%27%20OR%20%271%27=%271&pass=invalid HTTP/1.1")
    $lines.Add("Host: portal.company.local")
    $lines.Add("User-Agent: Mozilla/5.0")
    $lines.Add("")
    $lines.Add("GET /login?user=%27%20OR%201=1--&pass=x HTTP/1.1")
    $lines.Add("Host: portal.company.local")
    $lines.Add("User-Agent: Mozilla/5.0")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,host,user,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $event = if (($i % 233) -eq 0) { "web_anomaly_review" } else { "routine_auth_traffic" }
        $sev = if ($event -eq "web_anomaly_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,web-app-01,na,$sev,baseline authentication monitoring")
    }

    $lines.Add("2026-03-07T16:12:11Z,waf_sqli_signal,web-app-01,na,high,SQLi rule match on /login request")
    $lines.Add("2026-03-07T16:12:11Z,auth_bypass_event,auth-service,admin,critical,login granted after tautology payload")
    $lines.Add("2026-03-07T16:12:12Z,db_unsanitized_query,db-auth-01,svc_auth,critical,string-concatenated login query observed")
    $lines.Add("2026-03-07T16:12:15Z,siem_case_opened,siem-automation,na,high,INC-2026-4901 strange request pattern investigation")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecureCodingPolicy {
    param([string]$OutputPath)

    $content = @'
Application Security Standard (Excerpt)

1) Authentication queries must use parameterized statements.
2) String concatenation for SQL construction is prohibited.
3) Input validation must reject tautology and comment-based payloads.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M2-09 Strange Request Pattern (Real-World Investigation Pack)

Scenario:
Security monitoring detected unusual authentication requests that appear to bypass login logic.

Task:
Analyze the investigation pack and identify the vulnerability being exploited.

Flag format:
CTF{vulnerability}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4901
Severity: High
Queue: SOC + AppSec

Summary:
Web and auth telemetry indicate suspicious login requests on `web-app-01` that resulted in unexpected successful authentication.

Scope:
- App host: web-app-01
- Auth service: auth-service
- DB host: db-auth-01
- Window: 2026-03-07 16:12 UTC

Deliverable:
Identify the vulnerability being exploited.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate web access patterns, WAF detections, auth behavior, and SQL query traces.
- Distinguish benign malformed requests from exploit payloads.
- Determine the vulnerability class used for authentication bypass.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-WebAccessLog -OutputPath (Join-Path $bundleRoot "evidence\web\web_access.log")
New-WafAlerts -OutputPath (Join-Path $bundleRoot "evidence\web\waf_alerts.jsonl")
New-AuthServiceLog -OutputPath (Join-Path $bundleRoot "evidence\app\auth_service.log")
New-DatabaseAudit -OutputPath (Join-Path $bundleRoot "evidence\db\db_audit.log")
New-RequestCorpus -OutputPath (Join-Path $bundleRoot "evidence\web\raw_request_corpus.txt")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-SecureCodingPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\secure_coding_standard.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
