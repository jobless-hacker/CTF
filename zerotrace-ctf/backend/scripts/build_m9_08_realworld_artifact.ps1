param()

$ErrorActionPreference = "Stop"

$bundleName = "m9-08-email-exposure"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m9_08_realworld_build"
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

function New-MailGatewayLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $domains = @("notify.example.com","alerts.example.net","mailer.service.io","updates.company.com")

    for ($i = 0; $i -lt 6900; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $msg = "MSG" + ("{0:D8}" -f (90000000 + $i))
        $src = "198.51.100." + (($i % 180) + 20)
        $from = "sender" + ($i % 800) + "@" + $domains[$i % $domains.Count]
        $to = "user" + ($i % 1200) + "@company.com"
        $status = if (($i % 199) -eq 0) { "quarantine" } else { "delivered" }
        $lines.Add("$ts gateway msg_id=$msg src_ip=$src from=$from to=$to status=$status")
    }

    $lines.Add("2026-03-07T22:18:41Z gateway msg_id=MSG99998888 src_ip=203.0.113.88 from=security-update@notice-mail.net to=it-admin@company.com status=quarantine note=suspicious_source")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SmtpTraceLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hosts = @("mx1.company.com","mx2.company.com","smtp-relay-1.company.com")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $src = "198.51.100." + (($i % 150) + 10)
        $dst = $hosts[$i % $hosts.Count]
        $queue = "Q" + ("{0:D7}" -f (5000000 + $i))
        $lines.Add("$ts smtp_trace queue_id=$queue src_ip=$src dst_host=$dst helo=mail-node" + ($i % 300) + " action=accept")
    }

    $lines.Add("2026-03-07T22:18:44Z smtp_trace queue_id=Q9000001 src_ip=203.0.113.88 dst_host=mx2.company.com helo=unknown-sender action=accept note=linked_target_message")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HeaderParseJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            message_id = "<msg" + (100000 + $i) + "@mail.example.com>"
            received_chain = @(
                "from relay-" + ($i % 200) + ".example.net by mx1.company.com",
                "from edge-" + ($i % 120) + ".example.net by relay-" + ($i % 200) + ".example.net"
            )
            source_ip = "198.51.100." + (($i % 200) + 10)
            risk = if (($i % 177) -eq 0) { "medium" } else { "low" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T22:18:47Z"
        message_id = "<target-incident@notice-mail.net>"
        received_chain = @(
            "from suspicious-relay.notice-mail.net by mx2.company.com",
            "from 203.0.113.88 by suspicious-relay.notice-mail.net"
        )
        source_ip = "203.0.113.88"
        risk = "high"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SpfDkimDmarcAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $msg = "MSG" + ("{0:D8}" -f (93000000 + $i))
        $spf = if (($i % 40) -eq 0) { "softfail" } else { "pass" }
        $dkim = if (($i % 51) -eq 0) { "fail" } else { "pass" }
        $dmarc = if (($spf -eq "pass" -and $dkim -eq "pass")) { "pass" } else { "quarantine" }
        $lines.Add("$ts auth_audit msg_id=$msg spf=$spf dkim=$dkim dmarc=$dmarc disposition=logged")
    }

    $lines.Add("2026-03-07T22:18:50Z auth_audit msg_id=MSG99998888 spf=softfail dkim=fail dmarc=quarantine disposition=investigate src_ip=203.0.113.88")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 233) -eq 0) { "mail-header-quality-check" } else { "mail-osint-heartbeat" }
        $sev = if ($evt -eq "mail-header-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,osint-mail-siem-01,$sev,email header enrichment heartbeat")
    }

    $lines.Add("2026-03-07T22:18:54Z,sending_ip_confirmed,osint-mail-siem-01,high,target message sending IP identified as 203.0.113.88")
    $lines.Add("2026-03-07T22:19:00Z,ctf_answer_ready,osint-mail-siem-01,high,submit sending IP 203.0.113.88")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EmailHeaderTxt {
    param([string]$OutputPath)

    $content = @'
Received: from 203.0.113.88
by mail.server.com
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
OSINT Case Notes (Extract)

Objective:
Identify the sending IP from target suspicious email headers.

Validation rule:
Correlate gateway logs, SMTP trace, parsed headers, and SIEM timeline.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Target email campaign infrastructure pivot:
203.0.113.88
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M9-08 Email Exposure (Real-World Investigation Pack)

Scenario:
An email investigation requires identifying the source infrastructure from header traces.

Task:
Analyze the evidence pack and identify the sending IP.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5908
Severity: Medium
Queue: SOC OSINT

Summary:
Extract sending IP from suspicious email chain and associated telemetry.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate mail gateway logs, SMTP trace logs, parsed header records,
  SPF/DKIM/DMARC audit data, SIEM timeline, and intel notes.
- Identify sending IP for target message.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-EmailHeaderTxt -OutputPath (Join-Path $bundleRoot "evidence\email_header.txt")
New-MailGatewayLog -OutputPath (Join-Path $bundleRoot "evidence\mail\mail_gateway.log")
New-SmtpTraceLog -OutputPath (Join-Path $bundleRoot "evidence\mail\smtp_trace.log")
New-HeaderParseJsonl -OutputPath (Join-Path $bundleRoot "evidence\mail\header_parse.jsonl")
New-SpfDkimDmarcAudit -OutputPath (Join-Path $bundleRoot "evidence\mail\auth_audit.log")
New-TimelineEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CaseNotes -OutputPath (Join-Path $bundleRoot "evidence\mail\case_notes.txt")
New-IntelSnapshot -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
