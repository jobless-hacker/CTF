param()

$ErrorActionPreference = "Stop"

$bundleName = "m3-01-public-spreadsheet"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m3_01_realworld_build"
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

function New-CustomerContactsSnapshot {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("customer_id,name,email,phone,city,segment,last_updated_utc")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)
    $cities = @("Hyderabad","Bengaluru","Mumbai","Pune","Chennai","Delhi")

    for ($i = 0; $i -lt 12800; $i++) {
        $id = "CUST-$('{0:D6}' -f (100000 + $i))"
        $name = "Customer_$('{0:D5}' -f $i)"
        $email = "customer$('{0:D5}' -f $i)@example.net"
        $phone = "9$('{0:D9}' -f (110000000 + $i))"
        $city = $cities[$i % $cities.Count]
        $seg = if (($i % 4) -eq 0) { "retail" } elseif (($i % 4) -eq 1) { "wholesale" } elseif (($i % 4) -eq 2) { "enterprise" } else { "online" }
        $ts = $base.AddMinutes($i).ToString("o")
        $lines.Add("$id,$name,$email,$phone,$city,$seg,$ts")
    }

    $lines.Add("CUST-991801,Alice,alice@example.com,5551112222,Hyderabad,retail,2026-03-07T09:41:02Z")
    $lines.Add("CUST-991802,Bob,bob@company.com,5552223333,Hyderabad,enterprise,2026-03-07T09:41:06Z")
    $lines.Add("CUST-991803,Charlie,charlie@corp.com,5553334444,Bengaluru,wholesale,2026-03-07T09:41:08Z")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudObjectListing {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,bucket,object_key,size_bytes,acl,owner,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 9200; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $obj = "exports/2026-03/customer_batch_$('{0:D4}' -f ($i % 250)).csv"
        $acl = if (($i % 33) -eq 0) { "private" } else { "private" }
        $cls = if (($i % 2) -eq 0) { "internal" } else { "restricted" }
        $lines.Add("$ts,crm-data-bucket,$obj,$((18000 + (($i * 77) % 190000))),$acl,crm-exporter,$cls")
    }

    $lines.Add("2026-03-07T09:40:59Z,crm-data-bucket,shared/public/customer_contacts_snapshot.csv,874212,public-read,crm-exporter,restricted-pii")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ShareAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("10.140.22.11","10.140.22.14","10.140.22.19","104.16.32.18","13.107.4.50")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $ip = $ips[$i % $ips.Count]
        $status = if (($i % 91) -eq 0) { 304 } else { 200 }
        $bytes = 2000 + (($i * 57) % 680000)
        $lines.Add("$ts src_ip=$ip method=GET path=""/shared/reports/monthly_summary_$($i % 20).csv"" status=$status bytes=$bytes ua=""Mozilla/5.0""")
    }

    $lines.Add("2026-03-07T09:41:12.449Z src_ip=185.199.110.42 method=GET path=""/shared/public/customer_contacts_snapshot.csv"" status=200 bytes=874212 ua=""curl/8.5.0""")
    $lines.Add("2026-03-07T09:42:01.002Z src_ip=185.199.110.42 method=GET path=""/shared/public/customer_contacts_snapshot.csv"" status=200 bytes=874212 ua=""Wget/1.21.4""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DlpAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $signals = @("email_pattern_detected","phone_pattern_detected","bulk_contact_export","high_record_volume")

    for ($i = 0; $i -lt 4200; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 14).ToString("o")
            system = "dlp-core-01"
            severity = if (($i % 131) -eq 0) { "medium" } else { "low" }
            signal = $signals[$i % $signals.Count]
            object = "reports/monthly_summary.csv"
            status = "closed_false_positive"
            note = "routine export monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T09:41:01Z"
        system = "dlp-core-01"
        severity = "high"
        signal = "public_acl_on_restricted_data"
        object = "shared/public/customer_contacts_snapshot.csv"
        status = "open"
        note = "restricted contact dataset exposed with public-read ACL"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T09:41:13Z"
        system = "dlp-core-01"
        severity = "critical"
        signal = "external_bulk_download_detected"
        object = "shared/public/customer_contacts_snapshot.csv"
        status = "open"
        note = "external IP retrieved full contact export"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CrmExportAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,export_id,requested_by,source_table,row_count,output_file,destination,approval_status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $tables = @("customers","orders","service_requests","invoice_contacts")

    for ($i = 0; $i -lt 3300; $i++) {
        $ts = $base.AddMinutes($i).ToString("o")
        $table = $tables[$i % $tables.Count]
        $file = "exports/$table-$('{0:D4}' -f ($i % 200)).csv"
        $approval = if (($i % 7) -eq 0) { "approved" } else { "approved" }
        $lines.Add("$ts,EXP-$((700000 + $i)),crm_bot,$table,$((200 + (($i * 9) % 10000))),$file,internal,$approval")
    }

    $lines.Add("2026-03-07T09:40:55Z,EXP-991801,crm_bot,customers,12803,customer_contacts_snapshot.csv,shared/public,not_approved")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $event = if (($i % 223) -eq 0) { "data_exposure_review" } else { "routine_data_pipeline" }
        $sev = if ($event -eq "data_exposure_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,siem-core-01,$sev,baseline CRM data operations")
    }

    $lines.Add("2026-03-07T09:40:59Z,public_object_detected,siem-core-01,high,customer_contacts_snapshot.csv found in public path")
    $lines.Add("2026-03-07T09:41:12Z,external_download,siem-core-01,critical,external IP downloaded contact snapshot")
    $lines.Add("2026-03-07T09:41:18Z,data_leak_case_opened,siem-core-01,high,INC-2026-4972 public spreadsheet exposure")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DataPolicy {
    param([string]$OutputPath)

    $content = @'
Customer Data Handling Policy (Excerpt)

1) Contact exports containing email + phone fields are classified as restricted.
2) Restricted exports must not be placed in public-readable storage paths.
3) Public sharing of customer contact datasets requires explicit legal and security approval.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M3-01 Public Spreadsheet (Real-World Investigation Pack)

Scenario:
A restricted CRM contact export was accidentally published to a public location and externally downloaded.

Task:
Analyze the investigation pack and identify the email belonging to Bob.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4972
Severity: High
Queue: SOC + Data Protection

Summary:
Monitoring flagged a public CRM contact spreadsheet and subsequent external downloads from unknown IPs.

Scope:
- Storage object: shared/public/customer_contacts_snapshot.csv
- Leak window: 2026-03-07 09:40-09:42 UTC
- Dataset type: customer contact information

Deliverable:
Identify the email belonging to Bob from the leaked dataset.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate storage ACL change, share access events, DLP alerts, and CRM export audit.
- Confirm leaked dataset context and inspect the contact snapshot content.
- Extract Bob's email as the final answer.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-CustomerContactsSnapshot -OutputPath (Join-Path $bundleRoot "evidence\leak\customer_contacts_snapshot.csv")
New-CloudObjectListing -OutputPath (Join-Path $bundleRoot "evidence\cloud\object_listing.csv")
New-ShareAccessLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\public_share_access.log")
New-DlpAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_exposure_alerts.jsonl")
New-CrmExportAudit -OutputPath (Join-Path $bundleRoot "evidence\app\crm_export_audit.csv")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-DataPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\customer_data_policy.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
