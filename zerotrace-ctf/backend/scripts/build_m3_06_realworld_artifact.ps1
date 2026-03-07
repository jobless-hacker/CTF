param()

$ErrorActionPreference = "Stop"

$bundleName = "m3-06-internal-document"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m3_06_realworld_build"
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

function New-ConfidentialDocumentLeak {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("CONFIDENTIAL - INTERNAL USE ONLY")
    $lines.Add("Document: Strategic Program Briefing")
    $lines.Add("Revision: 3.1")
    $lines.Add("Owner: Corp Strategy Office")
    $lines.Add("Date: 2026-03-07")
    $lines.Add("")

    for ($i = 0; $i -lt 5400; $i++) {
        $lines.Add("Section note $($i): operational context and planning detail redacted for training dataset realism.")
    }

    $lines.Add("")
    $lines.Add("CONFIDENTIAL PROJECT")
    $lines.Add("Project Name: Falcon")
    $lines.Add("Launch Date: Q4")
    $lines.Add("Budget Visibility: Restricted")
    $lines.Add("")
    $lines.Add("end_of_document")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DocumentRepositoryIndex {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,repo,doc_id,doc_name,classification,owner,location,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $docs = @("ops_monthly_summary.docx","quarterly_hiring_plan.xlsx","regional_sales_forecast.pptx","legal_review_tracker.docx")

    for ($i = 0; $i -lt 8900; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $doc = $docs[$i % $docs.Count]
        $cls = if (($i % 5) -eq 0) { "internal" } else { "internal" }
        $owner = if (($i % 2) -eq 0) { "strategy_bot" } else { "ops_bot" }
        $lines.Add("$ts,corp-doc-repo,DOC-$((770000 + $i)),$doc,$cls,$owner,/repos/internal/$doc,active")
    }

    $lines.Add("2026-03-07T13:52:11Z,corp-doc-repo,DOC-991906,strategic_program_briefing.txt,confidential,corp_strategy,/repos/confidential/strategic_program_briefing.txt,active")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ShareAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $path = "/shares/internal/documents/doc_$('{0:D4}' -f ($i % 500)).txt"
        $status = if (($i % 133) -eq 0) { 403 } else { 200 }
        $lines.Add("$ts src_ip=10.200.33.$((20 + ($i % 60))) method=GET path=""$path"" status=$status bytes=$((1700 + (($i * 39) % 420000))) ua=""internal-sync-agent""")
    }

    $lines.Add("2026-03-07T13:52:36.442Z src_ip=198.51.100.77 method=GET path=""/shares/public/strategic_program_briefing.txt"" status=200 bytes=932114 ua=""curl/8.5.0""")
    $lines.Add("2026-03-07T13:53:01.119Z src_ip=198.51.100.77 method=GET path=""/shares/public/strategic_program_briefing.txt"" status=200 bytes=932114 ua=""Wget/1.21.4""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-OutboundEmailLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,mail_id,sender,recipient,subject,attachment,classification,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $senders = @("ops@company.com","hr@company.com","finance@company.com","alerts@company.com")
    $subjects = @("weekly update","review request","planning note","status mail")

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $sender = $senders[$i % $senders.Count]
        $subject = $subjects[$i % $subjects.Count]
        $attach = if (($i % 3) -eq 0) { "summary_$('{0:D3}' -f ($i % 200)).pdf" } else { "none" }
        $cls = if ($attach -eq "none") { "internal" } else { "internal" }
        $lines.Add("$ts,MAIL-$((930000 + $i)),$sender,user$($i % 300)@company.com,$subject,$attach,$cls,delivered")
    }

    $lines.Add("2026-03-07T13:52:25Z,MAIL-991906,contractor.temp@company.com,externaldrop@protonmail.com,fwd docs,strategic_program_briefing.txt,confidential,delivered")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DlpDocumentAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $signals = @("confidential_tag_match","external_share_attempt","keyword_density","sensitive_doc_export")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 12).ToString("o")
            system = "dlp-doc-01"
            severity = if (($i % 127) -eq 0) { "medium" } else { "low" }
            signal = $signals[$i % $signals.Count]
            object = "doc_$('{0:D4}' -f ($i % 500)).txt"
            status = "closed_false_positive"
            note = "routine document governance telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T13:52:26Z"
        system = "dlp-doc-01"
        severity = "high"
        signal = "confidential_document_exposed_publicly"
        object = "strategic_program_briefing.txt"
        status = "open"
        note = "document tagged confidential appeared in public share path"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T13:52:37Z"
        system = "dlp-doc-01"
        severity = "critical"
        signal = "external_download_confidential_document"
        object = "strategic_program_briefing.txt"
        status = "open"
        note = "external IP downloaded confidential strategy briefing"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IdentityContext {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("user,department,role,access_scope,status")
    $lines.Add("contractor.temp,operations,contractor,internal-limited,active")
    $lines.Add("strategy_lead,strategy,manager,confidential-docs,active")
    $lines.Add("ops_maya,operations,engineer,ops-docs,active")
    $lines.Add("legal_reader,legal,analyst,legal-docs,active")
    $lines.Add("finance_ro,finance,analyst,finance-docs,active")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 241) -eq 0) { "document_review" } else { "routine_doc_activity" }
        $sev = if ($event -eq "document_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,siem-doc-01,$sev,baseline document protection monitoring")
    }

    $lines.Add("2026-03-07T13:52:25Z,unauthorized_external_share,siem-doc-01,high,confidential doc sent to external recipient")
    $lines.Add("2026-03-07T13:52:36Z,public_confidential_access,siem-doc-01,critical,external download of strategic_program_briefing.txt")
    $lines.Add("2026-03-07T13:52:48Z,incident_opened,siem-doc-01,high,INC-2026-5144 internal document exposure")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DocumentPolicy {
    param([string]$OutputPath)

    $content = @'
Confidential Document Handling Policy (Excerpt)

1) Documents tagged confidential must never be stored in public-access paths.
2) External forwarding of confidential strategy documents is prohibited.
3) Any external access to confidential documents must be treated as a critical incident.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M3-06 Internal Document (Real-World Investigation Pack)

Scenario:
A confidential internal strategy document was exposed externally via unauthorized sharing and public access.

Task:
Analyze the investigation pack and identify the confidential project name.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5144
Severity: High
Queue: SOC + Insider Risk

Summary:
Document protection controls detected confidential strategy material shared externally and retrieved from a public path.

Scope:
- Exposed document: strategic_program_briefing.txt
- Window: 2026-03-07 13:52-13:53 UTC
- Classification: confidential

Deliverable:
Identify the confidential project name from leaked document evidence.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate document repository context, public share access, outbound email traces, DLP alerts, and SIEM timeline.
- Confirm confidential leak and inspect leaked document text.
- Extract the confidential project name as final answer.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ConfidentialDocumentLeak -OutputPath (Join-Path $bundleRoot "evidence\leak\strategic_program_briefing.txt")
New-DocumentRepositoryIndex -OutputPath (Join-Path $bundleRoot "evidence\repo\document_repo_index.csv")
New-ShareAccessLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\public_share_access.log")
New-OutboundEmailLog -OutputPath (Join-Path $bundleRoot "evidence\mail\outbound_mail_log.csv")
New-DlpDocumentAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_document_alerts.jsonl")
New-IdentityContext -OutputPath (Join-Path $bundleRoot "evidence\identity\identity_context.csv")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-DocumentPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\confidential_document_policy.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
