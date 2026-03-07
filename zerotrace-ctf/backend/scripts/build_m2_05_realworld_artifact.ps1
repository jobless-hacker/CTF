param()

$ErrorActionPreference = "Stop"

$bundleName = "m2-05-midnight-upload"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m2_05_realworld_build"
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

function New-NetflowEgress {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,dst_port,proto,bytes_out,session_id,process,user,classification")

    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $dstPool = @("52.112.24.11","13.107.42.12","172.67.22.10","20.190.188.20","104.18.19.5","10.80.12.22")
    $procPool = @("chrome.exe","onedrive.exe","teams.exe","backup-agent","excel.exe")
    $userPool = @("ops_maya","sre_oncall","finance_ro","hr_readonly","build_agent")

    for ($i = 0; $i -lt 11800; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $dst = $dstPool[$i % $dstPool.Count]
        $proc = $procPool[$i % $procPool.Count]
        $user = $userPool[$i % $userPool.Count]
        $class = if ($dst.StartsWith("10.")) { "internal" } else { "approved_external" }
        $bytes = 8000 + (($i * 137) % 220000)
        $lines.Add("$ts,10.60.14.$((20 + ($i % 50))),$dst,443,tcp,$bytes,S-$((500000 + $i)),$proc,$user,$class")
    }

    $lines.Add("2026-03-06T23:51:07Z,10.60.14.22,198.51.100.7,443,tcp,48622110,S-991401,excel.exe,sarah.k,unapproved_external")
    $lines.Add("2026-03-06T23:51:19Z,10.60.14.22,198.51.100.7,443,tcp,52219033,S-991401,excel.exe,sarah.k,unapproved_external")
    $lines.Add("2026-03-06T23:51:32Z,10.60.14.22,198.51.100.7,443,tcp,40118349,S-991401,excel.exe,sarah.k,unapproved_external")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProxyEgressLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $sites = @(
        "https://outlook.office.com/mail/api/sync",
        "https://teams.microsoft.com/metrics",
        "https://drive.company.local/upload",
        "https://hrms.company.local/api/v1/report",
        "https://api.github.com/repos/org/app"
    )
    $users = @("ops_maya","deployer","sre_oncall","finance_ro","hr_readonly")

    for ($i = 0; $i -lt 9300; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $url = $sites[$i % $sites.Count]
        $user = $users[$i % $users.Count]
        $method = if (($i % 4) -eq 0) { "POST" } else { "GET" }
        $status = if (($i % 37) -eq 0) { 429 } else { 200 }
        $bytes = 1024 + (($i * 59) % 940000)
        $lines.Add("$ts src=10.60.14.$((20 + ($i % 50))) user=$user method=$method url=""$url"" status=$status bytes_out=$bytes ua=""Mozilla/5.0 corporate-agent""")
    }

    $lines.Add("2026-03-06T23:51:11.119Z src=10.60.14.22 user=sarah.k method=POST url=""https://198.51.100.7/upload"" status=200 bytes_out=48622110 content_disposition=""attachment; filename=payroll.xlsx"" ua=""Microsoft Office/16.0""")
    $lines.Add("2026-03-06T23:51:24.441Z src=10.60.14.22 user=sarah.k method=POST url=""https://198.51.100.7/upload/chunk2"" status=200 bytes_out=52219033 content_disposition=""attachment; filename=payroll.xlsx"" ua=""Microsoft Office/16.0""")
    $lines.Add("2026-03-06T23:51:37.873Z src=10.60.14.22 user=sarah.k method=POST url=""https://198.51.100.7/upload/chunk3"" status=200 bytes_out=40118349 content_disposition=""attachment; filename=payroll.xlsx"" ua=""Microsoft Office/16.0""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FileAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,user,file_path,operation,process,outcome,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $files = @(
        "\\filesrv\finance\budget_q1.xlsx",
        "\\filesrv\finance\invoice_registry.xlsx",
        "\\filesrv\hr\leave_calendar.xlsx",
        "\\filesrv\ops\runbook.docx",
        "\\filesrv\shared\meeting_notes.txt"
    )
    $users = @("finance_ro","ops_maya","hr_readonly","deployer","sre_oncall")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $file = $files[$i % $files.Count]
        $user = $users[$i % $users.Count]
        $op = if (($i % 5) -eq 0) { "read" } elseif (($i % 5) -eq 1) { "copy" } else { "open" }
        $proc = if (($i % 2) -eq 0) { "excel.exe" } else { "explorer.exe" }
        $class = if ($file -like "*finance*") { "internal-sensitive" } else { "internal-normal" }
        $lines.Add("$ts,fin-wks-22,$user,$file,$op,$proc,success,$class")
    }

    $lines.Add("2026-03-06T23:50:41Z,fin-wks-22,sarah.k,\\filesrv\\finance\\payroll.xlsx,open,excel.exe,success,restricted-pii")
    $lines.Add("2026-03-06T23:50:53Z,fin-wks-22,sarah.k,\\filesrv\\finance\\payroll.xlsx,copy,excel.exe,success,restricted-pii")
    $lines.Add("2026-03-06T23:51:05Z,fin-wks-22,sarah.k,\\filesrv\\finance\\payroll.xlsx,upload_prepare,excel.exe,success,restricted-pii")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DlpAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $types = @("keyword_match","bulk_attachment","ssn_pattern","high_entropy_text")
    $statuses = @("closed_false_positive","informational","reviewed_benign")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 14).ToString("o")
            host = "fin-wks-22"
            user = if (($i % 2) -eq 0) { "finance_ro" } else { "hr_readonly" }
            severity = if (($i % 97) -eq 0) { "medium" } else { "low" }
            alert_type = $types[$i % $types.Count]
            destination = "approved_saas"
            file = if (($i % 3) -eq 0) { "budget_q1.xlsx" } else { "na" }
            status = $statuses[$i % $statuses.Count]
            note = "routine office transfer telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T23:51:14Z"
        host = "fin-wks-22"
        user = "sarah.k"
        severity = "high"
        alert_type = "restricted_pii_exfiltration"
        destination = "198.51.100.7"
        file = "payroll.xlsx"
        status = "open"
        note = "124 employee payroll records matched in outbound payload"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T23:51:39Z"
        host = "fin-wks-22"
        user = "sarah.k"
        severity = "critical"
        alert_type = "after_hours_sensitive_upload"
        destination = "198.51.100.7"
        file = "payroll.xlsx"
        status = "open"
        note = "transfer outside approved data movement window"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-UserContext {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("user,department,role,endpoint,manager,normal_work_hours,external_upload_privilege")
    $lines.Add("sarah.k,finance,payroll_analyst,fin-wks-22,finance_manager,08:00-19:00,no")
    $lines.Add("finance_ro,finance,analyst,fin-wks-11,finance_manager,08:00-19:00,no")
    $lines.Add("ops_maya,operations,engineer,ops-wks-07,ops_manager,24x7,limited")
    $lines.Add("deployer,platform,automation,ci-node-03,platform_manager,24x7,approved_endpoints_only")
    $lines.Add("hr_readonly,hr,staff,hr-wks-05,hr_manager,08:00-19:00,no")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TransferPolicy {
    param([string]$OutputPath)

    $content = @'
Data Egress and Off-Hours Transfer Policy (Excerpt)

1) Files classified as "restricted-pii" must not be sent to unapproved external destinations.
2) Finance payroll exports are permitted only through approved secure gateway.
3) Standard user endpoints are not permitted to upload payroll datasets externally.
4) Off-hours (22:00-06:00 UTC) uploads of sensitive files require incident manager approval.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,host,user,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4900; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 211) -eq 0) { "large_file_transfer_review" } else { "routine_transfer"
        }
        $sev = if ($event -eq "large_file_transfer_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,fin-wks-$((10 + ($i % 15))),finance_ro,$sev,baseline corporate file sync")
    }

    $lines.Add("2026-03-06T23:50:53Z,file_opened,fin-wks-22,sarah.k,medium,payroll.xlsx opened from finance share")
    $lines.Add("2026-03-06T23:51:11Z,unusual_outbound_transfer,fin-wks-22,sarah.k,high,large upload to 198.51.100.7")
    $lines.Add("2026-03-06T23:51:14Z,dlp_alert,fin-wks-22,sarah.k,high,restricted pii pattern triggered on payroll.xlsx")
    $lines.Add("2026-03-06T23:51:39Z,policy_violation,fin-wks-22,sarah.k,critical,off-hours external upload of restricted-pii file")
    $lines.Add("2026-03-06T23:52:01Z,siem_case_opened,soc-automation,fin-wks-22,high,INC-2026-4721 created")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M2-05 Midnight Upload (Real-World Investigation Pack)

Scenario:
SOC monitoring detected abnormal high-volume outbound transfer activity from a finance workstation during off-hours.

Task:
Analyze the investigation pack and identify the file that was exfiltrated.

Flag format:
CTF{filename}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4721
Severity: High
Queue: SOC Triage

Summary:
Outbound data transfer spikes were detected at ~23:51 UTC from finance endpoint `fin-wks-22` to unapproved external IP `198.51.100.7`.

Scope:
- Endpoint: fin-wks-22
- User in context: sarah.k
- Detection window: 2026-03-06 23:50 to 23:53 UTC

Deliverable:
Identify the file that was exfiltrated.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate network flow, proxy upload metadata, endpoint file access, and DLP alerts.
- Validate user privileges and transfer policy constraints.
- Determine exact filename of the exfiltrated artifact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-NetflowEgress -OutputPath (Join-Path $bundleRoot "evidence\network\netflow_egress.csv")
New-ProxyEgressLog -OutputPath (Join-Path $bundleRoot "evidence\network\proxy_egress.log")
New-FileAudit -OutputPath (Join-Path $bundleRoot "evidence\endpoint\file_access_audit.csv")
New-DlpAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_alerts.jsonl")
New-UserContext -OutputPath (Join-Path $bundleRoot "evidence\identity\user_context.csv")
New-TransferPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\data_egress_policy.txt")
New-TimelineEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
