param()

$ErrorActionPreference = "Stop"

$bundleName = "m5-05-suid-binary"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m5_05_realworld_build"
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

function New-SuidInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,node,file_path,mode,owner,group,size_bytes,risk_tag")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $safeBins = @(
        "/usr/bin/passwd",
        "/usr/bin/su",
        "/usr/bin/chfn",
        "/usr/bin/chsh",
        "/usr/bin/newgrp",
        "/usr/lib/policykit-1/polkit-agent-helper-1"
    )

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $node = "lin-sec-{0:D2}" -f (1 + ($i % 8))
        $bin = $safeBins[$i % $safeBins.Count]
        $size = 25000 + (($i * 13) % 180000)
        $tag = if (($i % 411) -eq 0) { "review" } else { "baseline"
        }
        $lines.Add("$ts,$node,$bin,-rwsr-xr-x,root,root,$size,$tag")
    }

    $lines.Add("2026-03-08T04:12:10Z,lin-sec-03,/usr/bin/find,-rwsr-xr-x,root,root,199856,high_risk")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PermissionSnapshot {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("### suid scan snapshot from lin-sec-03")

    for ($i = 0; $i -lt 6800; $i++) {
        $user = if (($i % 4) -eq 0) { "root" } else { "sys" }
        $group = if (($i % 3) -eq 0) { "root" } else { "adm" }
        $path = "/opt/tools/tool_{0:D5}" -f $i
        $lines.Add("-rwxr-xr-x 1 $user $group $((1200 + ($i % 88000))) Mar 08 03:$("{0:D2}" -f ($i % 60)) $path")
    }

    $lines.Add("-rwsr-xr-x 1 root root 68248 Mar 08 04:11 /usr/bin/passwd")
    $lines.Add("-rwsr-xr-x 1 root root 55792 Mar 08 04:11 /usr/bin/su")
    $lines.Add("-rwsr-xr-x 1 root root 199856 Mar 08 04:12 /usr/bin/find")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ExecAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $acct = if (($i % 9) -eq 0) { "opsadmin" } else { "deploy" }
        $cmd = if (($i % 37) -eq 0) { "/usr/bin/id" } else { "/usr/bin/ls /var/log" }
        $lines.Add("$ts auditd type=EXECVE user=$acct node=lin-sec-03 command=""$cmd"" euid=1001 result=success")
    }

    $lines.Add("2026-03-08T04:12:22Z auditd type=EXECVE user=deploy node=lin-sec-03 command=""/usr/bin/find /tmp -name '*.tmp' -exec /bin/sh -p -c id \;"" euid=0 result=success")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PrivEscAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("binary_permission_watch","suid_baseline_check","execve_risk_watch","euid_shift_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "prv-" + ("{0:D8}" -f (91000000 + $i))
            severity = if (($i % 193) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine permission drift telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T04:12:22Z"
        alert_id = "prv-99955005"
        severity = "critical"
        type = "suid_binary_abuse"
        status = "open"
        detail = "privilege escalation pattern detected via risky suid binary"
        risky_binary = "find"
        node = "lin-sec-03"
    }) | ConvertTo-Json -Compress))
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $evt = if (($i % 277) -eq 0) { "privesc_review" } else { "routine_binary_monitoring" }
        $sev = if ($evt -eq "privesc_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-privesc-01,$sev,binary permission telemetry baseline")
    }

    $lines.Add("2026-03-08T04:12:10Z,suid_scan_flagged,siem-privesc-01,high,/usr/bin/find marked as high-risk suid binary")
    $lines.Add("2026-03-08T04:12:22Z,euid_escalation_detected,siem-privesc-01,critical,find execution resulted in euid=0 shell behavior")
    $lines.Add("2026-03-08T04:12:31Z,incident_opened,siem-privesc-01,high,INC-2026-5505 suid binary investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Privilege Escalation Prevention Policy (Excerpt)

1) SUID binaries must be baseline reviewed and limited to approved set.
2) SUID-enabled utility binaries with shell execution primitives are high risk.
3) SOC triage must identify exact risky SUID binary in incident scope.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Linux SUID Abuse Triage Runbook (Excerpt)

1) Compare SUID inventory against approved baseline.
2) Pivot into execution audit for euid changes and shell-spawn patterns.
3) Correlate SIEM and alert telemetry for risky binary attribution.
4) Remove unauthorized SUID bit and rotate affected credentials.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M5-05 SUID Binary (Real-World Investigation Pack)

Scenario:
Permission and execution telemetry suggests possible Linux privilege escalation through SUID binary abuse.

Task:
Analyze the investigation pack and identify the risky SUID binary involved in this incident.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5505
Severity: High
Queue: SOC + Linux Ops + Detection Engineering

Summary:
Host telemetry flagged suspicious SUID usage with possible escalation to effective root context.

Scope:
- Node: lin-sec-03
- Window: 2026-03-08 04:12 UTC
- Goal: identify risky SUID binary
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate SUID inventory, permission snapshots, execution audit logs, privilege-escalation alerts, SIEM timeline, and policy/runbook guidance.
- Determine which SUID binary is risky in this incident.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-SuidInventory -OutputPath (Join-Path $bundleRoot "evidence\filesystem\suid_inventory.csv")
New-PermissionSnapshot -OutputPath (Join-Path $bundleRoot "evidence\filesystem\permissions_snapshot.txt")
New-ExecAudit -OutputPath (Join-Path $bundleRoot "evidence\audit\execve_audit.log")
New-PrivEscAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\privesc_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\privesc_prevention_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\suid_abuse_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
