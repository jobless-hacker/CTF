param()

$ErrorActionPreference = "Stop"

$bundleName = "m7-08-command-injection"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m7_08_realworld_build"
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

function New-GatewayAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.24.18.15","49.205.33.77","125.16.88.12","110.227.55.41")
    $paths = @("/ping?host=8.8.8.8","/health","/status","/help")

    for ($i = 0; $i -lt 7200; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $reqId = "req-" + ("{0:D7}" -f (9910000 + $i))
        $ip = $ips[$i % $ips.Count]
        $path = $paths[$i % $paths.Count]
        $status = if (($i % 137) -eq 0) { 304 } else { 200 }
        $bytes = 900 + (($i * 23) % 18000)
        $lines.Add("$ts api-gw request_id=$reqId src_ip=$ip method=GET path=$path status=$status bytes=$bytes service=diagnostics")
    }

    $lines.Add("2026-03-08T11:20:44Z api-gw request_id=req-9918123 src_ip=185.243.115.9 method=GET path=/ping?host=8.8.8.8;cat /etc/passwd status=200 bytes=1872 service=diagnostics note=possible_command_injection")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AppRequestParamsLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hosts = @("8.8.8.8","1.1.1.1","9.9.9.9","208.67.222.222")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $reqId = "req-" + ("{0:D7}" -f (9910000 + $i))
        $h = $hosts[$i % $hosts.Count]
        $lines.Add("$ts app-params request_id=$reqId endpoint=/ping raw_query=host=$h sanitized_host=$h validator=pass")
    }

    $lines.Add("2026-03-08T11:20:44Z app-params request_id=req-9918123 endpoint=/ping raw_query=host=8.8.8.8;cat /etc/passwd sanitized_host=8.8.8.8 validator=fail reason=metacharacter_detected injected_command=cat")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WafLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.24.18.15","49.205.33.77","125.16.88.12","110.227.55.41")

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $ip = $ips[$i % $ips.Count]
        $sev = if (($i % 241) -eq 0) { "NOTICE" } else { "INFO" }
        $lines.Add("$ts waf=node-waf-08 src=$ip action=ALLOW severity=$sev rule=932100 msg=`"request parameter profile baseline`"")
    }

    $lines.Add("2026-03-08T11:20:44Z waf=node-waf-08 src=185.243.115.9 action=ALERT severity=CRITICAL rule=932180 msg=`"command injection pattern detected`" endpoint=`"/ping`" token=`";cat`" request_id=req-9918123")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ExecAuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hosts = @("8.8.8.8","1.1.1.1","9.9.9.9","208.67.222.222")

    for ($i = 0; $i -lt 5300; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $reqId = "req-" + ("{0:D7}" -f (9910000 + $i))
        $h = $hosts[$i % $hosts.Count]
        $lines.Add("$ts exec-audit request_id=$reqId command=`"/bin/ping -c 1 $h`" status=ok")
    }

    $lines.Add("2026-03-08T11:20:45Z exec-audit request_id=req-9918123 command=`"/bin/sh -c ping -c 1 8.8.8.8;cat /etc/passwd`" status=blocked parsed_injected_command=cat")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("input-anomaly-watch","metachar-watch","endpoint-risk-watch","runtime-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "cinj-" + ("{0:D8}" -f (66800000 + $i))
            severity = if (($i % 193) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine command endpoint monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T11:20:46Z"
        alert_id = "cinj-66859999"
        severity = "critical"
        type = "command_injection_detected"
        status = "open"
        request_id = "req-9918123"
        endpoint = "/ping"
        injected_command = "cat"
        source_ip = "185.243.115.9"
        detail = "command separator and command token identified in host parameter"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 263) -eq 0) { "command-endpoint-review" } else { "normal-endpoint-monitoring" }
        $sev = if ($evt -eq "command-endpoint-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-web-08,$sev,ping endpoint telemetry baseline review")
    }

    $lines.Add("2026-03-08T11:20:46Z,command_injection_confirmed,siem-web-08,high,correlated gateway/waf/exec evidence confirms command injection")
    $lines.Add("2026-03-08T11:20:50Z,injected_command_identified,siem-web-08,critical,injected command identified as cat")
    $lines.Add("2026-03-08T11:21:00Z,incident_opened,siem-web-08,high,INC-2026-5708 command injection investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RequestCapture {
    param([string]$OutputPath)

    $content = @'
GET /ping?host=8.8.8.8;cat /etc/passwd HTTP/1.1
Host: app.example.local
User-Agent: Mozilla/5.0
X-Request-Id: req-9918123
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Command Execution Endpoint Security Policy (Excerpt)

1) User-supplied parameters must never be concatenated into shell command strings.
2) Input validation must block command separators and command tokens.
3) SOC/AppSec must identify and report the extracted injected command token.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Command Injection Triage Runbook (Excerpt)

1) Pivot suspicious request id across gateway, WAF, and app parameter logs.
2) Validate raw query contains metacharacter separator.
3) Confirm injected command token from execution audit and detection feeds.
4) Submit command token and open containment ticket.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed abuse pattern: command injection via diagnostics endpoints.
Common tokenized command in this campaign: cat
Current incident normalized command indicator: cat
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M7-08 Command Injection (Real-World Investigation Pack)

Scenario:
Web diagnostics endpoint telemetry indicates a crafted input parameter attempted shell command injection.

Task:
Analyze the investigation pack and identify the injected command.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5708
Severity: High
Queue: SOC + AppSec

Summary:
Potential command injection attempt observed on diagnostics endpoint.

Scope:
- Endpoint: /ping
- Suspicious request: req-9918123
- Objective: identify injected command token
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate gateway access, app request parameters, WAF logs, execution audit, request capture, security alerts, SIEM timeline, and policy/runbook context.
- Determine the injected command token.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-GatewayAccessLog -OutputPath (Join-Path $bundleRoot "evidence\web\gateway_access.log")
New-AppRequestParamsLog -OutputPath (Join-Path $bundleRoot "evidence\web\app_request_params.log")
New-WafLog -OutputPath (Join-Path $bundleRoot "evidence\web\waf.log")
New-ExecAuditLog -OutputPath (Join-Path $bundleRoot "evidence\host\exec_audit.log")
New-RequestCapture -OutputPath (Join-Path $bundleRoot "evidence\web\request_capture.txt")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\command_injection_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\command_execution_endpoint_security_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\command_injection_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
