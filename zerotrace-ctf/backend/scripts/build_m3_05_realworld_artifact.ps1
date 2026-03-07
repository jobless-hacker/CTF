param()

$ErrorActionPreference = "Stop"

$bundleName = "m3-05-pastebin-leak"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m3_05_realworld_build"
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

function New-PasteCapture {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("== Archived Paste Snapshot ==")
    $lines.Add("source: hxxp://paste-share.example/raw/984421")
    $lines.Add("captured_utc: 2026-03-07T12:08:11Z")
    $lines.Add("")
    for ($i = 0; $i -lt 6200; $i++) {
        $lines.Add("note_$($i): random text fragment for context and noise")
    }
    $lines.Add("")
    $lines.Add("Company Credentials")
    $lines.Add("vpn_user: corpvpn")
    $lines.Add("vpn_pass: vpnAccess2025")
    $lines.Add("smtp_user: alerts-bot")
    $lines.Add("smtp_pass: redacted")
    $lines.Add("")
    $lines.Add("end_of_capture")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-OsintFeed {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $cats = @("credential_mention","domain_mention","email_mention","low_quality_noise")

    for ($i = 0; $i -lt 6800; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 11).ToString("o")
            feed = "paste-monitor-v2"
            source = "paste-site-$($i % 30).example"
            category = $cats[$i % $cats.Count]
            score = if (($i % 151) -eq 0) { 65 } else { 12 + ($i % 30) }
            status = "reviewed_false_positive"
            snippet = "generic leaked text pattern"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T12:08:12Z"
        feed = "paste-monitor-v2"
        source = "paste-share.example/raw/984421"
        category = "credential_mention"
        score = 98
        status = "open"
        snippet = "vpn_user: corpvpn; vpn_pass: vpnAccess2025"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-VpnAuthAttempts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,vpn_gateway,username,src_ip,result,reason,mfa")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("ops_maya","deployer","audit_reader","finance_ro","hr_readonly")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $u = $users[$i % $users.Count]
        $res = if (($i % 10) -eq 0) { "FAIL" } else { "SUCCESS" }
        $reason = if ($res -eq "FAIL") { "invalid_password" } else { "policy_ok" }
        $mfa = if ($res -eq "SUCCESS") { "passed" } else { "not_invoked" }
        $lines.Add("$ts,vpn-gw-01,$u,10.190.12.$((20 + ($i % 60))),$res,$reason,$mfa")
    }

    $lines.Add("2026-03-07T12:09:10Z,vpn-gw-01,corpvpn,203.0.113.188,FAIL,invalid_password,not_invoked")
    $lines.Add("2026-03-07T12:09:36Z,vpn-gw-01,corpvpn,203.0.113.188,FAIL,invalid_password,not_invoked")
    $lines.Add("2026-03-07T12:10:02Z,vpn-gw-01,corpvpn,203.0.113.188,FAIL,account_locked,not_invoked")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IdentityDirectory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("username,owner_team,account_type,mfa_required,status,last_rotated_utc")
    $lines.Add("corpvpn,network-security,service_vpn,yes,active,2026-02-27T08:00:00Z")
    $lines.Add("ops_maya,operations,human,yes,active,2026-02-28T08:00:00Z")
    $lines.Add("deployer,platform,service,yes,active,2026-02-28T08:00:00Z")
    $lines.Add("audit_reader,audit,service,yes,active,2026-02-20T08:00:00Z")
    $lines.Add("finance_ro,finance,human,yes,active,2026-02-21T08:00:00Z")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DlpLeakAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $signals = @("credential_keyword","password_pattern","external_paste_reference","secret_density")

    for ($i = 0; $i -lt 4100; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 13).ToString("o")
            system = "dlp-intel-01"
            severity = if (($i % 149) -eq 0) { "medium" } else { "low" }
            signal = $signals[$i % $signals.Count]
            source = "paste-site-$($i % 25).example"
            status = "closed_false_positive"
            note = "routine leak-intel monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T12:08:13Z"
        system = "dlp-intel-01"
        severity = "high"
        signal = "vpn_credential_leak"
        source = "paste-share.example/raw/984421"
        status = "open"
        note = "detected vpn_user and vpn_pass pair in public paste"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T12:09:10Z"
        system = "dlp-intel-01"
        severity = "critical"
        signal = "credential_abuse_attempt"
        source = "vpn-gw-01"
        status = "open"
        note = "failed auth attempts observed using leaked vpn username"
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
        $event = if (($i % 227) -eq 0) { "leak_intel_review" } else { "routine_external_intel" }
        $sev = if ($event -eq "leak_intel_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,siem-intel-01,$sev,baseline credential leak monitoring")
    }

    $lines.Add("2026-03-07T12:08:12Z,paste_hit_detected,siem-intel-01,high,public paste contains vpn credential pattern")
    $lines.Add("2026-03-07T12:09:10Z,vpn_bruteforce_attempt,siem-intel-01,critical,leaked VPN username used from external IP")
    $lines.Add("2026-03-07T12:09:20Z,incident_opened,siem-intel-01,high,INC-2026-5112 pastebin credential leak")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CredentialPolicy {
    param([string]$OutputPath)

    $content = @'
Credential Handling Policy (Excerpt)

1) VPN account identifiers and passwords must never appear on public paste platforms.
2) Any detected credential leak requires immediate rotation and incident response.
3) Repeated external auth attempts with leaked usernames must trigger account lock and SOC escalation.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M3-05 Pastebin Leak (Real-World Investigation Pack)

Scenario:
A public paste-style leak appears to expose VPN credentials and is followed by suspicious authentication attempts.

Task:
Analyze the investigation pack and identify the VPN username.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5112
Severity: High
Queue: SOC + Threat Intel

Summary:
Leak monitoring flagged a credential-bearing paste, and VPN gateway logs show immediate abuse attempts from external IP.

Scope:
- Leak source: paste-share.example/raw/984421
- Window: 2026-03-07 12:08-12:10 UTC
- System impacted: vpn-gw-01

Deliverable:
Identify the leaked VPN username.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate paste snapshot, OSINT feed, VPN auth attempts, identity directory context, DLP alerts, and SIEM timeline.
- Confirm credential leak and associated abuse pattern.
- Extract the leaked VPN username from evidence.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-PasteCapture -OutputPath (Join-Path $bundleRoot "evidence\leak\paste_capture_20260307.txt")
New-OsintFeed -OutputPath (Join-Path $bundleRoot "evidence\intel\osint_paste_feed.jsonl")
New-VpnAuthAttempts -OutputPath (Join-Path $bundleRoot "evidence\vpn\vpn_auth_attempts.csv")
New-IdentityDirectory -OutputPath (Join-Path $bundleRoot "evidence\identity\directory_accounts.csv")
New-DlpLeakAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_leak_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CredentialPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\credential_handling_policy.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
