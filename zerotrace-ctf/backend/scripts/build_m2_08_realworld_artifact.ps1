param()

$ErrorActionPreference = "Stop"

$bundleName = "m2-08-internal-audit-trail"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m2_08_realworld_build"
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

function New-PortalAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,user,department,resource,action,result,source_ip,session_id,risk")

    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("finance_ro","hr_readonly","ops_maya","audit_reader","comp_ben")
    $resources = @(
        "finance/budget_q1.xlsx",
        "hr/leave_plan.xlsx",
        "finance/vendor_invoices.xlsx",
        "audit/compliance_2026.docx",
        "finance/reimbursement_log.csv"
    )

    for ($i = 0; $i -lt 10800; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $user = $users[$i % $users.Count]
        $resource = $resources[$i % $resources.Count]
        $dept = if ($user -like "finance*") { "finance" } elseif ($user -like "hr*") { "hr" } elseif ($user -like "audit*") { "audit" } elseif ($user -like "ops*") { "ops" } else { "compliance" }
        $action = if (($i % 5) -eq 0) { "open" } elseif (($i % 5) -eq 1) { "view" } elseif (($i % 5) -eq 2) { "export" } else { "read" }
        $result = if (($i % 131) -eq 0) { "denied" } else { "success" }
        $risk = if ($result -eq "denied") { "medium" } else { "low" }
        $lines.Add("$ts,payroll-portal-01,$user,$dept,$resource,$action,$result,10.90.12.$((20 + ($i % 60))),S-$((701000 + $i)),$risk")
    }

    $lines.Add("2026-03-07T15:41:12Z,payroll-portal-01,alice,marketing,payroll/salary_records.xlsx,open,success,10.90.12.44,S-991811,high")
    $lines.Add("2026-03-07T15:41:33Z,payroll-portal-01,alice,marketing,payroll/salary_records.xlsx,export,success,10.90.12.44,S-991811,critical")
    $lines.Add("2026-03-07T15:41:44Z,payroll-portal-01,alice,marketing,payroll/salary_records.xlsx,download,success,10.90.12.44,S-991811,critical")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FileServerAccess {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,fileserver,user,file_path,operation,process,outcome,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $files = @(
        "\\fs-fin\finance\budget_q1.xlsx",
        "\\fs-fin\finance\invoice_ledger.xlsx",
        "\\fs-hr\hr\leave-register.xlsx",
        "\\fs-audit\audit\evidence_2026.docx",
        "\\fs-fin\finance\bonus_approvals.xlsx"
    )
    $users = @("finance_ro","hr_readonly","audit_reader","ops_maya")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $file = $files[$i % $files.Count]
        $user = $users[$i % $users.Count]
        $op = if (($i % 4) -eq 0) { "open" } elseif (($i % 4) -eq 1) { "read" } elseif (($i % 4) -eq 2) { "copy" } else { "close" }
        $cls = if ($file -like "\\fs-fin\finance\*") { "internal-sensitive" } else { "internal-normal" }
        $lines.Add("$ts,fs-core-01,$user,$file,$op,explorer.exe,success,$cls")
    }

    $lines.Add("2026-03-07T15:41:28Z,fs-core-01,alice,\\fs-fin\\payroll\\salary_records.xlsx,open,excel.exe,success,restricted-payroll")
    $lines.Add("2026-03-07T15:41:37Z,fs-core-01,alice,\\fs-fin\\payroll\\salary_records.xlsx,copy,excel.exe,success,restricted-payroll")
    $lines.Add("2026-03-07T15:41:46Z,fs-core-01,alice,\\fs-fin\\payroll\\salary_records.xlsx,download_prepare,excel.exe,success,restricted-payroll")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IdentityDirectory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("user,department,job_role,manager,location,payroll_data_access,privileged_groups")
    $lines.Add("alice,marketing,campaign_analyst,marketing_lead,HYD,no,marketing_read")
    $lines.Add("finance_ro,finance,analyst,finance_manager,HYD,yes,finance_read")
    $lines.Add("hr_readonly,hr,staff,hr_manager,HYD,no,hr_read")
    $lines.Add("audit_reader,audit,auditor,audit_manager,HYD,conditional,audit_read")
    $lines.Add("ops_maya,ops,engineer,ops_manager,HYD,no,ops_admin")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AccessApprovalRegistry {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("request_id,requester,resource,requested_on_utc,approved_by,status,expires_on_utc")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $requesters = @("finance_ro","audit_reader","ops_maya","comp_ben")
    $resources = @("finance/budget_q1.xlsx","finance/invoice_ledger.xlsx","audit/evidence_2026.docx","hr/leave-register.xlsx")

    for ($i = 0; $i -lt 3300; $i++) {
        $reqTime = $base.AddMinutes($i * 2)
        $expTime = $reqTime.AddHours(8)
        $r = $requesters[$i % $requesters.Count]
        $res = $resources[$i % $resources.Count]
        $lines.Add("REQ-$((820000 + $i)),$r,$res,$($reqTime.ToString('o')),data_governance,approved,$($expTime.ToString('o'))")
    }

    $lines.Add("REQ-991811,alice,payroll/salary_records.xlsx,2026-03-07T15:40:59Z,NA,not_approved,NA")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-UebaAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $signals = @("off_pattern_access","volume_anomaly","cross_dept_resource","sensitive_export")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 12).ToString("o")
            host = "payroll-portal-01"
            user = if (($i % 2) -eq 0) { "finance_ro" } else { "audit_reader" }
            severity = if (($i % 141) -eq 0) { "medium" } else { "low" }
            signal = $signals[$i % $signals.Count]
            resource = "finance/budget_q1.xlsx"
            status = "closed_false_positive"
            note = "baseline department-aligned access"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T15:41:33Z"
        host = "payroll-portal-01"
        user = "alice"
        severity = "high"
        signal = "cross_dept_sensitive_access"
        resource = "payroll/salary_records.xlsx"
        status = "open"
        note = "marketing account accessed payroll resource without approval"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T15:41:44Z"
        host = "payroll-portal-01"
        user = "alice"
        severity = "critical"
        signal = "sensitive_export_detected"
        resource = "payroll/salary_records.xlsx"
        status = "open"
        note = "restricted payroll export performed by unauthorized department"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PortalQueries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("finance_ro","audit_reader","ops_maya","hr_readonly")
    $queries = @(
        "SELECT * FROM budgets WHERE fiscal_year=2026 LIMIT 100",
        "SELECT * FROM invoices WHERE status='pending' LIMIT 200",
        "SELECT * FROM leave_plan WHERE quarter='Q2'",
        "SELECT * FROM compliance_checklist WHERE region='IN'"
    )

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $u = $users[$i % $users.Count]
        $q = $queries[$i % $queries.Count]
        $rows = 10 + (($i * 7) % 800)
        $lines.Add("$ts host=payroll-db-01 user=$u stmt=""$q"" rows=$rows status=ok")
    }

    $lines.Add("2026-03-07T15:41:31.103Z host=payroll-db-01 user=alice stmt=""SELECT * FROM salary_records WHERE month='2026-02'"" rows=124 status=ok")
    $lines.Add("2026-03-07T15:41:42.641Z host=payroll-db-01 user=alice stmt=""SELECT employee_id,net_salary,bank_acct FROM salary_records"" rows=124 status=ok")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,host,user,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 217) -eq 0) { "access_review" } else { "routine_access" }
        $sev = if ($event -eq "access_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,payroll-portal-01,finance_ro,$sev,baseline payroll portal monitoring")
    }

    $lines.Add("2026-03-07T15:41:12Z,cross_department_access,payroll-portal-01,alice,high,marketing account accessed payroll/salary_records.xlsx")
    $lines.Add("2026-03-07T15:41:33Z,unauthorized_export,payroll-portal-01,alice,critical,payroll data export without approved request")
    $lines.Add("2026-03-07T15:41:44Z,insider_risk_alert,payroll-portal-01,alice,critical,UEBA + DLP signals indicate insider misuse")
    $lines.Add("2026-03-07T15:41:58Z,siem_case_opened,siem-automation,alice,high,INC-2026-4868 internal audit trail incident")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DataAccessPolicy {
    param([string]$OutputPath)

    $content = @'
Payroll Data Access Policy (Excerpt)

1) Payroll datasets are restricted to Finance Payroll team only.
2) Cross-department access requires pre-approved data governance request.
3) Export of payroll records by non-finance accounts is prohibited.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M2-08 Internal Audit Trail (Real-World Investigation Pack)

Scenario:
Audit telemetry indicates confidential payroll data was accessed and exported by a user outside the authorized department.

Task:
Analyze the investigation pack and identify the insider account.

Flag format:
CTF{username}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4868
Severity: High
Queue: SOC + Insider Risk

Summary:
Cross-department payroll access activity was detected on `payroll-portal-01`, followed by sensitive export events.

Scope:
- Host: payroll-portal-01
- Investigative window: 2026-03-07 15:41 UTC
- Sensitive resource: payroll/salary_records.xlsx

Deliverable:
Identify the insider account.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate audit portal logs, file server events, database query logs, UEBA alerts, and identity policy context.
- Validate whether access was approved in governance registry.
- Determine the insider account responsible for the unauthorized payroll access/export.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-PortalAudit -OutputPath (Join-Path $bundleRoot "evidence\audit\portal_audit.csv")
New-FileServerAccess -OutputPath (Join-Path $bundleRoot "evidence\audit\fileserver_access.csv")
New-PortalQueries -OutputPath (Join-Path $bundleRoot "evidence\audit\db_query.log")
New-UebaAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\ueba_alerts.jsonl")
New-IdentityDirectory -OutputPath (Join-Path $bundleRoot "evidence\identity\directory_context.csv")
New-AccessApprovalRegistry -OutputPath (Join-Path $bundleRoot "evidence\identity\access_approval_registry.csv")
New-DataAccessPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\payroll_data_access_policy.txt")
New-TimelineEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
