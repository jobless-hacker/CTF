param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-15-ransomware-lock"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m1_15_realworld_build"
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

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-15 Files Suddenly Unusable (Real-World Investigation Pack)

Scenario:
A finance workstation began mass-renaming files and users could no longer open key business documents.
Evidence includes process telemetry, file impact timelines, EDR alerts, SMB behavior,
service desk impact, and recovery-state records.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4510
Severity: Critical
Queue: SOC + Endpoint IR

Summary:
Finance users report files now have ".vault" extension and fail to open.
A ransom note appeared on WS-FIN-22 and restore attempts are failing.

Scope:
- Host: WS-FIN-22
- User: finance.ap
- Window: 2026-03-06 03:14 UTC onward

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Initial trigger came from EDR mass file-rename behavior.
- Routine finance automations create baseline noise.
- Correlate process chain, extension changes, user impact, and failed recovery.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$ransom = @'
Your files are encrypted.
Send 3.8 BTC within 72 hours to restore access.
Do not rename encrypted files.

Contact: restore-help@protonmail[.]com
Victim ID: FIN-WS22-7843
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\host\ransom_note.txt") -Content $ransom

$processLines = New-Object System.Collections.Generic.List[string]
$baseProc = [datetime]::SpecifyKind([datetime]"2026-03-06T00:20:00", [DateTimeKind]::Utc)
$users = @("finance.ap","ops.user","helpdesk.l1","svc_backup","svc_monitor","hr.exec")
$procs = @(
    @{ p = "explorer.exe"; parent = "winlogon.exe"; cmd = "C:\Windows\explorer.exe" },
    @{ p = "outlook.exe"; parent = "explorer.exe"; cmd = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE" },
    @{ p = "chrome.exe"; parent = "explorer.exe"; cmd = "C:\Program Files\Google\Chrome\Application\chrome.exe" },
    @{ p = "backup-agent.exe"; parent = "services.exe"; cmd = "C:\Program Files\BackupAgent\backup-agent.exe --cycle" },
    @{ p = "defender_scan.exe"; parent = "services.exe"; cmd = "C:\Program Files\Windows Defender\defender_scan.exe --quick" }
)
for ($i = 0; $i -lt 8800; $i++) {
    $ts = $baseProc.AddSeconds($i * 2).ToString("o")
    $pick = $procs[$i % $procs.Count]
    $user = $users[$i % $users.Count]
    $hostName = if (($i % 2) -eq 0) { "WS-FIN-22" } else { "WS-FIN-18" }
    $processLines.Add("$ts host=$hostName user=$user pid=$((3000 + $i)) parent=""$($pick.parent)"" process=""$($pick.p)"" cmd=""$($pick.cmd)""")
}
$processLines.Add("2026-03-06T03:14:11Z host=WS-FIN-22 user=finance.ap pid=19404 parent=""outlook.exe"" process=""excel.exe"" cmd=""...March_Invoice_Revised.xlsm""")
$processLines.Add("2026-03-06T03:14:23Z host=WS-FIN-22 user=finance.ap pid=19416 parent=""excel.exe"" process=""powershell.exe"" cmd=""powershell.exe -ExecutionPolicy Bypass -EncodedCommand ...""")
$processLines.Add("2026-03-06T03:14:45Z host=WS-FIN-22 user=finance.ap pid=19434 parent=""powershell.exe"" process=""cipherlock.exe"" cmd=""cipherlock.exe --mode encrypt --ext .vault --targets D:\Shared\Finance""")
$processLines.Add("2026-03-06T03:14:49Z host=WS-FIN-22 user=finance.ap pid=19441 parent=""cipherlock.exe"" process=""vssadmin.exe"" cmd=""vssadmin delete shadows /all /quiet""")
$processLines.Add("2026-03-06T03:15:06Z host=WS-FIN-22 user=finance.ap pid=19453 parent=""cipherlock.exe"" process=""cmd.exe"" cmd=""cmd.exe /c net stop backup-agent""")
Write-LinesFile -Path (Join-Path $bundleRoot "evidence\host\process_creation.log") -Lines $processLines

$impactLines = New-Object System.Collections.Generic.List[string]
$impactLines.Add("timestamp_utc,host,user,operation,file_path,result,extension_before,extension_after,entropy_delta,note")
$baseImpact = [datetime]::SpecifyKind([datetime]"2026-03-06T02:20:00", [DateTimeKind]::Utc)
$exts = @("docx","xlsx","pdf","pptx","csv")
for ($i = 0; $i -lt 11000; $i++) {
    $ts = $baseImpact.AddMilliseconds($i * 800).ToString("o")
    $ext = $exts[$i % $exts.Count]
    $op = if (($i % 9) -eq 0) { "modify" } elseif (($i % 17) -eq 0) { "rename" } else { "open" }
    $note = if (($i % 641) -eq 0) { "known-backup-temp-file-rotation" } else { "routine-user-activity" }
    $impactLines.Add("$ts,WS-FIN-22,finance.ap,$op,D:\Shared\Finance\Q1\file_$((40000 + $i)).$ext,success,$ext,$ext,0.03,$note")
}
for ($j = 0; $j -lt 260; $j++) {
    $ts = [datetime]::SpecifyKind([datetime]"2026-03-06T03:15:10", [DateTimeKind]::Utc).AddSeconds($j * 2).ToString("o")
    $before = if (($j % 3) -eq 0) { "xlsx" } elseif (($j % 3) -eq 1) { "docx" } else { "pdf" }
    $impactLines.Add("$ts,WS-FIN-22,finance.ap,rename,D:\Shared\Finance\FY26\critical_$((90000 + $j)).$before,success,$before,vault,0.81,mass-encryption-pattern")
}
$impactLines.Add("2026-03-06T03:18:04Z,WS-FIN-22,finance.ap,create,C:\Users\Public\READ_ME_RESTORE.txt,success,txt,txt,0.00,ransom-note-dropped")
$impactLines.Add("2026-03-06T03:18:28Z,WS-FIN-22,finance.ap,open,D:\Shared\Finance\FY26\critical_90121.vault,access_denied,vault,vault,0.00,user-cannot-open-post-encryption")
Write-LinesFile -Path (Join-Path $bundleRoot "evidence\host\file_impact_timeline.csv") -Lines $impactLines

$edrLines = New-Object System.Collections.Generic.List[string]
$baseEdr = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
$signals = @("powershell_encoded_cmd","suspicious_macro","script_download","defender_tamper_attempt")
for ($i = 0; $i -lt 7600; $i++) {
    $record = [ordered]@{
        timestamp = $baseEdr.AddSeconds($i * 4).ToString("o")
        host = "WS-FIN-22"
        severity = if (($i % 16) -eq 0) { "medium" } else { "low" }
        status = if (($i % 16) -eq 0) { "closed_false_positive" } else { "informational" }
        signal = $signals[$i % $signals.Count]
        process = "powershell.exe"
        user = "finance.ap"
        note = if (($i % 16) -eq 0) { "approved finance macro workflow" } else { "telemetry baseline event" }
    }
    $edrLines.Add(($record | ConvertTo-Json -Compress))
}
$edrLines.Add((([ordered]@{ timestamp = "2026-03-06T03:14:47Z"; host = "WS-FIN-22"; severity = "critical"; status = "open"; signal = "ransomware_behavior_mass_rename"; process = "cipherlock.exe"; user = "finance.ap"; note = "rapid extension change to .vault across finance share" }) | ConvertTo-Json -Compress))
$edrLines.Add((([ordered]@{ timestamp = "2026-03-06T03:14:50Z"; host = "WS-FIN-22"; severity = "critical"; status = "open"; signal = "shadowcopy_deletion"; process = "vssadmin.exe"; user = "finance.ap"; note = "command observed: vssadmin delete shadows /all /quiet" }) | ConvertTo-Json -Compress))
$edrLines.Add((([ordered]@{ timestamp = "2026-03-06T03:19:12Z"; host = "WS-FIN-22"; severity = "high"; status = "open"; signal = "no_exfiltration_confirmed"; process = "edr_sensor"; user = "SYSTEM"; note = "no large outbound transfer in impact window" }) | ConvertTo-Json -Compress))
Write-LinesFile -Path (Join-Path $bundleRoot "evidence\security\edr_alerts.jsonl") -Lines $edrLines

$smbLines = New-Object System.Collections.Generic.List[string]
$smbLines.Add("timestamp_utc,src_host,src_ip,dst_share,operation,file_count,bytes,classification")
$baseSmb = [datetime]::SpecifyKind([datetime]"2026-03-06T01:00:00", [DateTimeKind]::Utc)
$shares = @("\\fs01\finance","\\fs01\hr","\\fs02\procurement","\\fs02\ops")
for ($i = 0; $i -lt 6200; $i++) {
    $ts = $baseSmb.AddMilliseconds($i * 920).ToString("o")
    $op = if (($i % 5) -eq 0) { "write" } else { "read" }
    $bytes = 2048 + (($i * 73) % 680000)
    $class = if ($op -eq "write" -and $bytes -gt 500000) { "large-report-export" } else { "routine-file-access" }
    $smbLines.Add("$ts,WS-FIN-22,10.20.44.22,$($shares[$i % $shares.Count]),$op,$((1 + ($i % 12))),$bytes,$class")
}
$smbLines.Add("2026-03-06T03:15:12Z,WS-FIN-22,10.20.44.22,\\fs01\\finance,write,850,145000000,encryption-spike")
$smbLines.Add("2026-03-06T03:15:29Z,WS-FIN-22,10.20.44.22,\\fs01\\finance,write,910,152000000,encryption-spike")
$smbLines.Add("2026-03-06T03:15:47Z,WS-FIN-22,10.20.44.22,\\fs01\\finance,write,940,159000000,encryption-spike")
Write-LinesFile -Path (Join-Path $bundleRoot "evidence\network\smb_activity.csv") -Lines $smbLines

$deskLines = New-Object System.Collections.Generic.List[string]
$deskLines.Add("ticket_id,created_utc,queue,requester,host,summary,severity,status")
$baseDesk = [datetime]::SpecifyKind([datetime]"2026-03-05T09:00:00", [DateTimeKind]::Utc)
for ($i = 0; $i -lt 3600; $i++) {
    $ts = $baseDesk.AddMinutes($i * 5).ToString("o")
    $summary = if (($i % 12) -eq 0) { "Printer mapping issue" } elseif (($i % 19) -eq 0) { "VPN reconnect request" } else { "Application lag report" }
    $deskLines.Add("HD-$((78000 + $i)),$ts,IT-Helpdesk,user$($i % 180),WS-FIN-22,$summary,low,closed")
}
for ($j = 0; $j -lt 42; $j++) {
    $ts = [datetime]::SpecifyKind([datetime]"2026-03-06T03:18:10", [DateTimeKind]::Utc).AddSeconds($j * 11).ToString("o")
    $sev = if ($j -lt 7) { "high" } else { "medium" }
    $deskLines.Add("HD-$((85000 + $j)),$ts,IT-Helpdesk,finance_user_$j,WS-FIN-22,Unable to open files with .vault extension,$sev,open")
}
Write-LinesFile -Path (Join-Path $bundleRoot "evidence\operations\service_desk_tickets.csv") -Lines $deskLines

$recoveryLines = New-Object System.Collections.Generic.List[string]
$baseRec = [datetime]::SpecifyKind([datetime]"2026-03-06T02:50:00", [DateTimeKind]::Utc)
for ($i = 0; $i -lt 2900; $i++) {
    $ts = $baseRec.AddSeconds($i * 3).ToString("o")
    $recoveryLines.Add("$ts soc-recovery[3312]: host=WS-FIN-22 level=info msg=""automated restore-point check complete""")
}
$recoveryLines.Add("2026-03-06T03:19:50Z soc-recovery[3312]: host=WS-FIN-22 level=warn msg=""rapid file extension drift detected (.vault)""")
$recoveryLines.Add("2026-03-06T03:21:11Z soc-recovery[3312]: host=WS-FIN-22 level=error msg=""shadow copy restore failed"" detail=""No valid snapshots found""")
$recoveryLines.Add("2026-03-06T03:21:18Z soc-recovery[3312]: host=WS-FIN-22 level=error msg=""backup-agent restore failed"" detail=""Service backup-agent is not running""")
$recoveryLines.Add("2026-03-06T03:25:10Z soc-recovery[3312]: host=WS-FIN-22 level=critical msg=""business files unavailable for finance team""")
Write-LinesFile -Path (Join-Path $bundleRoot "evidence\operations\recovery_attempts.log") -Lines $recoveryLines

$snapLines = New-Object System.Collections.Generic.List[string]
$snapLines.Add("timestamp_utc,host,snapshot_type,status,snapshot_count,last_valid_snapshot_utc,note")
$baseSnap = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)
for ($i = 0; $i -lt 3100; $i++) {
    $ts = $baseSnap.AddMinutes($i * 12).ToString("o")
    $status = if (($i % 151) -eq 0) { "warning" } else { "healthy" }
    $note = if ($status -eq "warning") { "snapshot consolidation delay" } else { "scheduled snapshots retained" }
    $snapLines.Add("$ts,WS-FIN-22,vss,$status,$((4 + ($i % 9))),$($baseSnap.AddMinutes($i * 12 - 45).ToString('o')),$note")
}
$snapLines.Add("2026-03-06T03:14:50Z,WS-FIN-22,vss,critical,0,2026-03-06T02:59:14Z,shadow copies removed by command-line utility")
$snapLines.Add("2026-03-06T03:21:11Z,WS-FIN-22,vss,critical,0,2026-03-06T02:59:14Z,restore blocked due to missing snapshots")
Write-LinesFile -Path (Join-Path $bundleRoot "evidence\operations\snapshot_inventory.csv") -Lines $snapLines

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
