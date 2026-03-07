param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-07-mis-sent-email"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_07_realworld_build"
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

function New-MailGatewayLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:10:00", [DateTimeKind]::Utc)
    $senders = @(
        "support.ops@company.local",
        "billing.ops@company.local",
        "success.team@company.local",
        "alerts@company.local"
    )
    $internalRecipients = @(
        "ops.review@company.local",
        "billing.review@company.local",
        "finance.audit@company.local",
        "support.manager@company.local"
    )
    $approvedExternal = @(
        "vendor.intake@trusted-logistics.com",
        "payroll.contractor@securepayroll.net"
    )

    for ($i = 0; $i -lt 4700; $i++) {
        $ts = $base.AddSeconds($i * 7)
        $stamp = $ts.ToString("yyyy-MM-ddTHH:mm:ssZ")
        $sender = $senders[$i % $senders.Count]
        $queueId = ("{0:X10}" -f (200000000 + $i))
        $msgId = "<20260306.$(200000 + $i).$((7200 + $i) % 9999)@company.local>"

        $recipient = if (($i % 10) -eq 0) {
            $approvedExternal[$i % $approvedExternal.Count]
        } else {
            $internalRecipients[$i % $internalRecipients.Count]
        }

        $recipientRelay = if ($recipient -like "*@company.local") {
            "mailbox.company.local[10.20.1.$(20 + ($i % 60))]:25"
        } else {
            "mx.external.partner[$(198 + ($i % 3)).51.100.$(20 + ($i % 80))]:25"
        }

        $status = if (($i % 73) -eq 0) { "deferred (451 4.4.1 temporary lookup failure)" } else { "sent (250 2.0.0 Ok queued as R$((50000 + $i) % 90000))" }
        $dsn = if ($status.StartsWith("deferred")) { "4.4.1" } else { "2.0.0" }

        $lines.Add("$stamp smtp-gateway-01 postfix/smtpd[10$((1100 + $i) % 9000)]: ${queueId}: client=mail-app-01[10.55.8.$(10 + ($i % 40))], sasl_method=PLAIN, sasl_username=$sender")
        $lines.Add("$stamp smtp-gateway-01 postfix/cleanup[11$((1100 + $i) % 9000)]: ${queueId}: message-id=$msgId")
        $lines.Add("$stamp smtp-gateway-01 postfix/smtp[12$((1100 + $i) % 9000)]: ${queueId}: to=<$recipient>, relay=$recipientRelay, delay=0.$((2 + $i) % 9), delays=0.01/0.01/0.12/0.34, dsn=$dsn, status=$status")
    }

    # Incident mail flow
    $lines.Add("2026-03-06T04:38:57Z smtp-gateway-01 postfix/smtpd[4211]: 7B9D1A4C2E: client=mail-app-01[10.55.8.23], sasl_method=PLAIN, sasl_username=support.ops@company.local")
    $lines.Add("2026-03-06T04:38:58Z smtp-gateway-01 postfix/cleanup[4216]: 7B9D1A4C2E: message-id=<20260306.100817.4421@company.local>")
    $lines.Add("2026-03-06T04:38:58Z smtp-gateway-01 postfix/qmgr[3310]: 7B9D1A4C2E: from=<support.ops@company.local>, size=842913, nrcpt=2 (queue active)")
    $lines.Add("2026-03-06T04:39:02Z smtp-gateway-01 dlp-engine[5111]: queue_id=7B9D1A4C2E policy='Outbound structured data review' mode=audit_only action=notify classification='contact_information,postal_address,national_id'")
    $lines.Add("2026-03-06T04:39:04Z smtp-gateway-01 postfix/smtp[4290]: 7B9D1A4C2E: to=<records.review@customerdocs.co>, relay=mx.customerdocs.co[203.0.113.77]:25, delay=1.3, delays=0.05/0.03/0.41/0.81, dsn=2.0.0, status=sent (250 2.0.0 Ok: queued as 8D102A73)")
    $lines.Add("2026-03-06T04:39:04Z smtp-gateway-01 postfix/local[4299]: 7B9D1A4C2E: to=<support.manager@company.local>, relay=local, delay=0.7, delays=0.05/0.03/0.08/0.54, dsn=2.0.0, status=sent (delivered to mailbox)")
    $lines.Add("2026-03-06T04:39:05Z smtp-gateway-01 postfix/qmgr[3310]: 7B9D1A4C2E: removed")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DlpAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:15:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $sev = if (($i % 18) -eq 0) { "medium" } else { "low" }
        $policyMode = if (($i % 41) -eq 0) { "block_with_override" } else { "audit_only" }
        $final = if ($policyMode -eq "block_with_override") { "blocked_or_overridden" } else { "delivered_notify" }
        $recipient = if (($i % 11) -eq 0) { "vendor.intake@trusted-logistics.com" } else { "ops.review@company.local" }
        $entry = [ordered]@{
            alert_id = "DLP-20260306-$($i + 1000)"
            timestamp = $ts
            sender = "support.ops@company.local"
            recipient = $recipient
            policy_name = "Outbound structured data review"
            matched_classifiers = @("contact_information")
            severity = $sev
            policy_mode = $policyMode
            final_action = $final
            resolution = if (($i % 7) -eq 0) { "false_positive_test_data" } else { "" }
        }
        $lines.Add(($entry | ConvertTo-Json -Depth 6 -Compress))
    }

    $incident = [ordered]@{
        alert_id = "DLP-20260306-8431"
        timestamp = "2026-03-06T04:39:02Z"
        sender = "support.ops@company.local"
        recipients = @("records.review@customerdocs.co","support.manager@company.local")
        external_recipient_count = 1
        policy_name = "Outbound structured data review"
        matched_classifiers = @("contact_information","postal_address","national_id")
        severity = "high"
        policy_mode = "audit_only"
        final_action = "delivered_notify"
        message_id = "<20260306.100817.4421@company.local>"
        queue_id = "7B9D1A4C2E"
        attachment = "march_review.xlsx"
        attachment_sha256 = "3f7d4bc4cc948b4f6a2da70fe4b3b57e96f18fd7f68cf1ddaa33fdd181100e29"
        note = "Recipient domain resembles internal review alias but is external."
    }
    $lines.Add(($incident | ConvertTo-Json -Depth 8 -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-MessageTrace {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("date_utc,sender,recipient,subject,status,message_id,message_size_kb,direction,recipient_scope,tls,final_action")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:20:00", [DateTimeKind]::Utc)
    $subjects = @("Daily case sync","Review checklist","Data cleanup run","Support export summary")
    $internalRecipients = @("ops.review@company.local","billing.review@company.local","support.manager@company.local")
    $externalAllowed = @("vendor.intake@trusted-logistics.com","payroll.contractor@securepayroll.net")

    for ($i = 0; $i -lt 9100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $subject = $subjects[$i % $subjects.Count]
        $sender = "support.ops@company.local"
        $recipient = if (($i % 12) -eq 0) { $externalAllowed[$i % $externalAllowed.Count] } else { $internalRecipients[$i % $internalRecipients.Count] }
        $scope = if ($recipient -like "*@company.local") { "internal" } else { "external_approved" }
        $status = if (($i % 97) -eq 0) { "Pending" } else { "Delivered" }
        $action = if ($status -eq "Pending") { "retrying" } else { "delivered" }
        $messageId = "<trace.$(300000 + $i)@company.local>"
        $size = 120 + (($i * 3) % 1800)
        $lines.Add("$ts,$sender,$recipient,$subject,$status,$messageId,$size,Sent,$scope,true,$action")
    }

    # Incident rows (one row per recipient)
    $lines.Add("2026-03-06T04:39:04Z,support.ops@company.local,records.review@customerdocs.co,March review file,Delivered,<20260306.100817.4421@company.local>,823,Sent,external_unapproved,true,delivered")
    $lines.Add("2026-03-06T04:39:04Z,support.ops@company.local,support.manager@company.local,March review file,Delivered,<20260306.100817.4421@company.local>,823,Sent,internal,true,delivered")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-MailboxAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,operation,mailbox,user,client_ip,client_app,subject,recipient_count,external_recipient_count,message_id,result")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4300; $i++) {
        $ts = $base.AddSeconds($i * 11).ToString("o")
        $op = if (($i % 6) -eq 0) { "SendAs" } else { "Send" }
        $subject = if (($i % 5) -eq 0) { "Ops handoff" } else { "Support digest" }
        $extCount = if (($i % 17) -eq 0) { 1 } else { 0 }
        $msgId = "<audit.$(400000 + $i)@company.local>"
        $result = if (($i % 51) -eq 0) { "SucceededWithWarning" } else { "Succeeded" }
        $lines.Add("$ts,$op,support.ops@company.local,support.ops@company.local,10.55.8.$(20 + ($i % 40)),OutlookWeb,$subject,1,$extCount,$msgId,$result")
    }

    $lines.Add("2026-03-06T04:38:57Z,Send,support.ops@company.local,support.ops@company.local,10.55.8.23,OutlookWeb,March review file,2,1,<20260306.100817.4421@company.local>,Succeeded")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source,event_type,severity,entity,status,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:05:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6500; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $event = if (($i % 15) -eq 0) { "dlp_match_low_confidence" } else { "mail_delivery_success" }
        $sev = if ($event -eq "dlp_match_low_confidence") { 25 } else { 5 }
        $status = if ($event -eq "dlp_match_low_confidence") { "closed_false_positive" } else { "informational" }
        $entity = if ($event -eq "dlp_match_low_confidence") { "support.ops@company.local" } else { "smtp-gateway-01" }
        $note = if ($event -eq "dlp_match_low_confidence") { "template data hit" } else { "normal message delivery" }
        $lines.Add("$ts,siem,$event,$sev,$entity,$status,$note")
    }

    $lines.Add("2026-03-06T04:39:02Z,dlp-engine,outbound_sensitive_attachment,91,<20260306.100817.4421@company.local>,open,attachment classified with contact and address data")
    $lines.Add("2026-03-06T04:39:04Z,smtp-gateway,external_delivery_after_dlp_audit_only,93,records.review@customerdocs.co,open,message delivered to non-allowlisted external domain")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-07 Mis-sent Email (Real-World Investigation Pack)

Scenario:
A support mailbox sent a spreadsheet that contained customer contact records.
The destination appears visually similar to an internal review alias but is an external domain.
The pack includes full mail headers, SMTP gateway logs, mailbox audit data, DLP alerts,
message trace exports, SIEM normalization, and allowlist context.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4447
Severity: High
Queue: Data Protection + Messaging Operations

Summary:
Outbound mail monitoring flagged a spreadsheet sent from support.ops@company.local.
The destination was records.review@customerdocs.co, which is not an approved external partner.
DLP detected sensitive content but policy was in audit-only mode.

Scope:
- Message-ID: <20260306.100817.4421@company.local>
- Queue ID: 7B9D1A4C2E
- Window: 2026-03-06 04:38 UTC to 04:41 UTC

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- SMTP telemetry is noisy; many normal outbound support messages exist.
- Some DLP alerts are low-confidence or test-data false positives.
- Correlate Message-ID and queue ID across EML, gateway, DLP, and message trace.
- Validate whether recipient domain is internal, approved external, or unapproved external.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$eml = @'
Return-Path: <support.ops@company.local>
Received: from mail-app-01.company.local (mail-app-01.company.local [10.55.8.23])
        by smtp-gateway-01.company.local (Postfix) with ESMTPSA id 7B9D1A4C2E
        for <records.review@customerdocs.co>; Fri, 06 Mar 2026 10:08:57 +0530 (IST)
Received: from smtp-gateway-01.company.local (smtp-gateway-01.company.local [10.60.1.12])
        by mx.customerdocs.co with ESMTPS id 8D102A73
        for <records.review@customerdocs.co>; Fri, 06 Mar 2026 10:09:04 +0530 (IST)
From: support.ops@company.local
To: records.review@customerdocs.co
Cc: support.manager@company.local
Subject: March review file
Date: Fri, 06 Mar 2026 10:08:17 +0530
Message-ID: <20260306.100817.4421@company.local>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="===============441203=="

--===============441203==
Content-Type: text/plain; charset="utf-8"

Sharing the latest review sheet from yesterday's export.
Please confirm the contact and location columns marked for cleanup before today's import window.

--===============441203==
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; name="march_review.xlsx"
Content-Disposition: attachment; filename="march_review.xlsx"

[binary attachment omitted]
--===============441203==--
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\mail\message.eml") -Content $eml

$attachmentManifest = @'
message_id,attachment_name,file_size_bytes,file_sha256,classifiers_detected,rows_estimated
<20260306.100817.4421@company.local>,march_review.xlsx,842913,3f7d4bc4cc948b4f6a2da70fe4b3b57e96f18fd7f68cf1ddaa33fdd181100e29,"contact_information;postal_address;national_id",1842
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\mail\attachment_manifest.csv") -Content $attachmentManifest

$allowList = @'
type,value,owner,notes
internal_domain,company.local,messaging-team,all company mailboxes
approved_external_domain,trusted-logistics.com,procurement,contracted logistics provider
approved_external_domain,securepayroll.net,finance,approved payroll processor
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\lookups\approved_recipient_domains.csv") -Content $allowList

New-MailGatewayLog -OutputPath (Join-Path $bundleRoot "evidence\security\mail_gateway_log.txt")
New-DlpAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_alerts.jsonl")
New-MessageTrace -OutputPath (Join-Path $bundleRoot "evidence\trace\message_trace_results.csv")
New-MailboxAudit -OutputPath (Join-Path $bundleRoot "evidence\trace\mailbox_audit_events.csv")
New-SiemEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\normalized_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
