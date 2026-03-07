param()

$ErrorActionPreference = "Stop"

$bundleName = "m4-10-ransomware-lockdown"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m4_10_realworld_build"
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

function New-EndpointSecurityLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hostName = "fin-app-01"
    $events = @("process_start","file_open","registry_read","network_connect","thread_create")

    for ($i = 0; $i -lt 9300; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $evt = $events[$i % $events.Count]
        $sev = if (($i % 181) -eq 0) { "warn" } else { "info" }
        $lines.Add("$ts host=$hostName severity=$sev event=$evt process=svc_worker_$($i % 30).exe outcome=allowed")
    }

    $lines.Add("2026-03-08T01:41:18.020Z host=fin-app-01 severity=critical event=file_encrypt_burst process=locker.exe encrypted_files=4821")
    $lines.Add("2026-03-08T01:41:19.100Z host=fin-app-01 severity=critical event=ransom_note_drop process=locker.exe path=C:\\\\README_RECOVER_FILES.txt")
    $lines.Add("2026-03-08T01:41:21.007Z host=fin-app-01 severity=critical event=service_disruption process=locker.exe impact=users_cannot_access_documents")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FileAccessFailures {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,file_path,operation,result,error")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 8800; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $path = "D:\\shares\\dept_$($i % 40)\\doc_$($i % 600).xlsx"
        $op = if (($i % 2) -eq 0) { "read" } else { "write" }
        $res = if (($i % 173) -eq 0) { "fail" } else { "ok" }
        $err = if ($res -eq "ok") { "-" } else { "temporary_file_lock" }
        $lines.Add("$ts,fin-app-01,$path,$op,$res,$err")
    }

    $lines.Add("2026-03-08T01:41:20Z,fin-app-01,D:\\shares\\finance\\quarterly_plans.xlsx,read,fail,file_encrypted")
    $lines.Add("2026-03-08T01:41:21Z,fin-app-01,D:\\shares\\hr\\payroll_2026.xlsx,read,fail,file_encrypted")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BackupRestoreLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $status = if (($i % 157) -eq 0) { "warning" } else { "ok" }
        $detail = if ($status -eq "ok") { "incremental backup verified" } else { "minor checksum mismatch on temp chunk" }
        $lines.Add("$ts backup-job=nightly-prod status=$status detail='$detail'")
    }

    $lines.Add("2026-03-08T01:41:22Z backup-job=nightly-prod status=failed detail='restore test failed: encrypted payload detected'")
    $lines.Add("2026-03-08T01:41:23Z backup-job=nightly-prod status=failed detail='recovery blocked until clean snapshot chosen'")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ServiceAvailabilityChecks {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,service,endpoint,status_code,result,error")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("files-api","doc-preview","search-index","user-portal")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $svc = $services[$i % $services.Count]
        $code = if (($i % 163) -eq 0) { 503 } else { 200 }
        $res = if ($code -eq 200) { "pass" } else { "retry" }
        $err = if ($code -eq 200) { "-" } else { "transient_unavailable" }
        $lines.Add("$ts,$svc,/health,$code,$res,$err")
    }

    $lines.Add("2026-03-08T01:41:20Z,files-api,/health,503,fail,data_unavailable_due_to_encryption")
    $lines.Add("2026-03-08T01:41:21Z,doc-preview,/health,503,fail,data_unavailable_due_to_encryption")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RansomNoteFile {
    param([string]$OutputPath)

    $content = @'
All your important files are encrypted.

Do not try to modify files.
Send 5 BTC to restore access.

Contact: recover-secure@protonmail.com
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-EDRAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("suspicious_script","registry_anomaly","file_io_spike","process_injection")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "edr-" + ("{0:D8}" -f (99000000 + $i))
            severity = if (($i % 173) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine endpoint fluctuation"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T01:41:19Z"
        alert_id = "edr-99988007"
        severity = "critical"
        type = "ransomware_activity"
        status = "open"
        detail = "mass encryption behavior detected on fin-app-01"
        primary_impact = "availability"
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
        $evt = if (($i % 317) -eq 0) { "endpoint_health_review" } else { "routine_endpoint_monitoring" }
        $sev = if ($evt -eq "endpoint_health_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-edr-01,$sev,background endpoint telemetry")
    }

    $lines.Add("2026-03-08T01:41:19Z,ransomware_detected,siem-edr-01,critical,mass file encryption and ransom note drop")
    $lines.Add("2026-03-08T01:41:21Z,business_data_unavailable,siem-edr-01,high,users cannot access encrypted files")
    $lines.Add("2026-03-08T01:41:25Z,impact_classified,siem-edr-01,high,primary impact classified as availability")
    $lines.Add("2026-03-08T01:41:30Z,incident_opened,siem-edr-01,high,INC-2026-5433 ransomware lockdown")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Ransomware Response Policy (Excerpt)

1) If files are encrypted and business processes cannot access them, impact is availability.
2) Prioritize containment and recovery of service access.
3) Classify CIA primary impact before remediation planning.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Ransomware Outage Runbook (Excerpt)

1) Confirm encryption behavior and ransom-note evidence.
2) Validate service and file accessibility impact.
3) Classify primary security impact category.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M4-10 Ransomware Lockdown (Real-World Investigation Pack)

Scenario:
A ransomware incident disrupted production workloads and restricted access to business data.

Task:
Analyze the investigation pack and identify the primary impact caused by the attack.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5433
Severity: Critical
Queue: SOC + IR + SRE

Summary:
Endpoint and service telemetry indicate encryption activity and broad business disruption.

Scope:
- Host: fin-app-01
- Window: 2026-03-08 01:41 UTC
- Goal: identify primary security impact category
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate endpoint security logs, file access failures, ransom note evidence, backup restore failures, service availability checks, EDR alerts, policy/runbook context, and SIEM timeline.
- Determine the primary impact category.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-EndpointSecurityLog -OutputPath (Join-Path $bundleRoot "evidence\endpoint\endpoint_security.log")
New-FileAccessFailures -OutputPath (Join-Path $bundleRoot "evidence\storage\file_access_failures.csv")
New-BackupRestoreLog -OutputPath (Join-Path $bundleRoot "evidence\backup\backup_restore.log")
New-ServiceAvailabilityChecks -OutputPath (Join-Path $bundleRoot "evidence\service\service_availability_checks.csv")
New-RansomNoteFile -OutputPath (Join-Path $bundleRoot "evidence\ransomware\ransom_note.txt")
New-EDRAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\edr_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\ransomware_response_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\ransomware_outage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
