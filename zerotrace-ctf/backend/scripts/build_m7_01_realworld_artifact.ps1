param()

$ErrorActionPreference = "Stop"

$bundleName = "m7-01-suspicious-login-query"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m7_01_realworld_build"
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

function New-AccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $clientIps = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78","157.49.12.90")
    $paths = @("/","/about","/pricing","/contact","/login","/products","/docs")
    $agents = @(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "Mozilla/5.0 (X11; Linux x86_64)",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
    )

    for ($i = 0; $i -lt 9600; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
        $ip = $clientIps[$i % $clientIps.Count]
        $path = $paths[$i % $paths.Count]
        $status = if (($i % 71) -eq 0) { 304 } else { 200 }
        $bytes = 450 + (($i * 17) % 14000)
        $ua = $agents[$i % $agents.Count]
        $lines.Add("$ip - - [$ts] `"GET $path HTTP/1.1`" $status $bytes `"-`" `"$ua`"")
    }

    $attackTs = [datetime]::SpecifyKind([datetime]"2026-03-08T10:14:22", [DateTimeKind]::Utc).ToString("dd/MMM/yyyy:HH:mm:ss +0000")
    $attackPath = "/login?user=admin'+OR+'1'='1&pass=test"
    $lines.Add("185.191.171.41 - - [$attackTs] `"GET $attackPath HTTP/1.1`" 401 932 `"-`" `"sqlmap/1.7.2#stable (http://sqlmap.org)`"")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WafLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")
    $rules = @("920350","921180","930120","949110")

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $ip = $ips[$i % $ips.Count]
        $rule = $rules[$i % $rules.Count]
        $sev = if (($i % 211) -eq 0) { "NOTICE" } else { "INFO" }
        $lines.Add("$ts waf=node-waf-01 src=$ip rule=$rule severity=$sev action=ALLOW msg=`"baseline request inspection`"")
    }

    $lines.Add("2026-03-08T10:14:22Z waf=node-waf-01 src=185.191.171.41 rule=942100 severity=CRITICAL action=BLOCK msg=`"SQL Injection Attack Detected via libinjection`" uri=`"/login?user=admin'+OR+'1'='1&pass=test`"")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthServiceLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("alice","bob","charlie","dev01","support01")
    $srcIps = @("103.22.1.14","110.227.88.10","49.205.12.32","125.16.44.78")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $user = $users[$i % $users.Count]
        $src = $srcIps[$i % $srcIps.Count]
        $result = if (($i % 13) -eq 0) { "login_failed" } else { "login_success" }
        $latency = 14 + ($i % 60)
        $lines.Add("$ts auth-api result=$result username=$user src_ip=$src latency_ms=$latency reason=normal_auth_flow")
    }

    $lines.Add("2026-03-08T10:14:22Z auth-api result=login_failed username=admin'+OR+'1'='1 src_ip=185.191.171.41 latency_ms=9 reason=suspicious_query_parameter")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DbAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $apps = @("auth-service","portal-api","catalog-api")

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $app = $apps[$i % $apps.Count]
        $query = "SELECT id, role FROM users WHERE username = ?"
        $rows = ($i % 3)
        $lines.Add("$ts db-audit app=$app query=`"$query`" param_style=prepared rows=$rows status=ok")
    }

    $lines.Add("2026-03-08T10:14:22Z db-audit app=auth-service query=`"SELECT id, role FROM users WHERE username='admin' OR '1'='1'`" param_style=raw_string rows=4 status=blocked note=classic_sql_injection_pattern")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WebAttackAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("auth-anomaly-watch","waf-baseline-watch","request-pattern-watch","input-validation-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "web-" + ("{0:D8}" -f (98800000 + $i))
            severity = if (($i % 179) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine web attack monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T10:14:23Z"
        alert_id = "web-98869995"
        severity = "critical"
        type = "auth_bypass_attempt_detected"
        status = "open"
        source_ip = "185.191.171.41"
        endpoint = "/login"
        attack_vector = "sqli"
        payload = "admin'+OR+'1'='1"
        detail = "login parameter shows classic SQL injection auth bypass pattern"
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
        $evt = if (($i % 263) -eq 0) { "web-auth-review" } else { "normal-web-monitoring" }
        $sev = if ($evt -eq "web-auth-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-web-01,$sev,application authentication baseline")
    }

    $lines.Add("2026-03-08T10:14:23Z,web_injection_pattern_confirmed,siem-web-01,high,correlated waf/auth/db evidence indicates SQL injection pattern")
    $lines.Add("2026-03-08T10:14:28Z,vulnerability_classified,siem-web-01,critical,vulnerability classified as sqli")
    $lines.Add("2026-03-08T10:14:40Z,incident_opened,siem-web-01,high,INC-2026-5701 suspicious login query investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Web Authentication Attack Detection Policy (Excerpt)

1) Login parameter tampering using SQL operators is high-risk.
2) Correlate access logs, WAF, auth service, and DB audit trails.
3) SOC must identify and report the exploited vulnerability class.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Suspicious Login Query Triage Runbook (Excerpt)

1) Inspect request parameters for injection payload markers.
2) Validate detection hits in WAF and auth service logs.
3) Confirm backend query impact in database audit logs.
4) Use alerts and SIEM to classify attack vector.
5) Submit vulnerability class and open remediation ticket.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed tooling: sqlmap-like probing against login forms
Common payload marker: OR '1'='1
Primary vulnerability class in this pattern: sqli
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M7-01 Suspicious Login Query (Real-World Investigation Pack)

Scenario:
Login endpoint traffic includes crafted parameters suggesting authentication bypass.

Task:
Analyze the investigation pack and identify the exploited vulnerability class.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5701
Severity: High
Queue: SOC + AppSec

Summary:
Web authentication telemetry indicates a crafted login query and likely bypass attempt.

Scope:
- Endpoint: /login
- Suspect source: 185.191.171.41
- Objective: identify exploited vulnerability class
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate access logs, WAF logs, auth service logs, DB audit records, security alerts, SIEM timeline, policy, runbook, and threat intel.
- Determine the vulnerability class used in the login attack.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-AccessLog -OutputPath (Join-Path $bundleRoot "evidence\network\access.log")
New-WafLog -OutputPath (Join-Path $bundleRoot "evidence\network\waf.log")
New-AuthServiceLog -OutputPath (Join-Path $bundleRoot "evidence\application\auth_service.log")
New-DbAuditLog -OutputPath (Join-Path $bundleRoot "evidence\database\query_audit.log")
New-WebAttackAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\web_attack_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\web_auth_attack_detection_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\suspicious_login_query_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
