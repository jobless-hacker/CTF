param()

$ErrorActionPreference = "Stop"

$bundleName = "m5-06-hidden-file"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m5_06_realworld_build"
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

function New-HomeInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,node,user,home_path,file_name,is_hidden,size_bytes,perm,last_modified")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hiddenSafe = @(".bashrc",".profile",".cache",".config",".ssh")
    $visible = @("notes.txt","todo.md","deploy.log","session.tmp","backup.list","report.csv")

    for ($i = 0; $i -lt 7400; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $node = "lin-hunt-{0:D2}" -f (1 + ($i % 7))
        $user = if (($i % 5) -eq 0) { "deploy" } else { "emp_{0:D4}" -f ($i % 4100) }
        $homeDir = "/home/$user"
        $isHidden = (($i % 4) -eq 0)
        $name = if ($isHidden) { $hiddenSafe[$i % $hiddenSafe.Count] } else { $visible[$i % $visible.Count] }
        $size = if ($isHidden) { 512 + (($i * 3) % 18000) } else { 2048 + (($i * 7) % 220000) }
        $perm = if ($isHidden) { "rw-------" } else { "rw-r--r--" }
        $mtime = $base.AddSeconds(($i * 8) - 140).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $lines.Add("$ts,$node,$user,$homeDir,$name,$($isHidden.ToString().ToLower()),$size,$perm,$mtime")
    }

    $lines.Add("2026-03-08T05:40:14Z,lin-hunt-02,deploy,/home/deploy,.hidden_backdoor,true,64320,rwx------,2026-03-08T05:40:13Z")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LsLaScan {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("### recursive hidden-file scan output (sampled)")

    for ($i = 0; $i -lt 6900; $i++) {
        $user = "emp_{0:D4}" -f ($i % 4500)
        $homeDir = "/home/$user"
        $lines.Add(("{0}:" -f $homeDir))
        $lines.Add("drwxr-xr-x 15 $user $user 4096 Mar 08 05:$("{0:D2}" -f ($i % 60)) .")
        $lines.Add("drwxr-xr-x  5 root root 4096 Mar 07 23:41 ..")
        $lines.Add("-rw-------  1 $user $user  220 Mar 08 05:$("{0:D2}" -f (($i + 1) % 60)) .bash_logout")
        $lines.Add("-rw-r--r--  1 $user $user 3771 Mar 08 05:$("{0:D2}" -f (($i + 2) % 60)) .bashrc")
        $lines.Add("-rw-r--r--  1 $user $user  807 Mar 08 05:$("{0:D2}" -f (($i + 3) % 60)) .profile")
    }

    $lines.Add("/home/deploy:")
    $lines.Add("drwxr-xr-x 18 deploy deploy 4096 Mar 08 05:40 .")
    $lines.Add("drwxr-xr-x  5 root   root   4096 Mar 07 23:41 ..")
    $lines.Add("-rw-r--r--  1 deploy deploy 3771 Mar 08 05:10 .bashrc")
    $lines.Add("-rwx------  1 deploy deploy 64320 Mar 08 05:40 .hidden_backdoor")
    $lines.Add("-rw-r--r--  1 deploy deploy 1120 Mar 08 05:18 deploy.log")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FileHashCatalog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,node,path,sha256,file_type,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $node = "lin-hunt-{0:D2}" -f (1 + ($i % 7))
        $user = "emp_{0:D4}" -f ($i % 4200)
        $path = "/home/$user/.cache/obj_$("{0:D5}" -f $i).bin"
        $sha = "{0:x64}" -f (9000000000000000 + $i)
        $lines.Add("$ts,$node,$path,$sha,data,baseline")
    }

    $lines.Add("2026-03-08T05:40:15Z,lin-hunt-02,/home/deploy/.hidden_backdoor,4e3c8ef48f6a0d6e6d4aabbe19e7ad1f4db019c5519a65d92ce4f5f302bb19af,elf64,suspicious")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-InotifyEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $events = @("IN_OPEN","IN_CLOSE_WRITE","IN_ACCESS","IN_ATTRIB")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $evt = $events[$i % $events.Count]
        $user = if (($i % 3) -eq 0) { "deploy" } else { "emp_{0:D4}" -f ($i % 3900) }
        $path = if (($i % 9) -eq 0) { "/home/$user/.cache" } else { "/home/$user/.config" }
        $lines.Add("$ts inotify node=lin-hunt-02 user=$user event=$evt path=$path")
    }

    $lines.Add("2026-03-08T05:40:13Z inotify node=lin-hunt-02 user=deploy event=IN_CREATE path=/home/deploy/.hidden_backdoor")
    $lines.Add("2026-03-08T05:40:16Z inotify node=lin-hunt-02 user=deploy event=IN_ATTRIB path=/home/deploy/.hidden_backdoor mode=700")
    $lines.Add("2026-03-08T05:40:22Z inotify node=lin-hunt-02 user=deploy event=IN_EXEC path=/home/deploy/.hidden_backdoor")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HiddenFileAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("hidden_file_baseline_check","home_dir_integrity_watch","file_exec_watch","dotfile_review")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "hid-" + ("{0:D8}" -f (87000000 + $i))
            severity = if (($i % 173) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine hidden file telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T05:40:22Z"
        alert_id = "hid-99977116"
        severity = "critical"
        type = "suspicious_hidden_executable"
        status = "open"
        detail = "hidden executable created and executed in user home directory"
        suspicious_file = ".hidden_backdoor"
        node = "lin-hunt-02"
    }) | ConvertTo-Json -Compress))
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $evt = if (($i % 281) -eq 0) { "hidden_file_review" } else { "routine_file_integrity_monitoring" }
        $sev = if ($evt -eq "hidden_file_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-file-01,$sev,file integrity telemetry baseline")
    }

    $lines.Add("2026-03-08T05:40:13Z,new_hidden_file_detected,siem-file-01,high,unexpected hidden file created under /home/deploy")
    $lines.Add("2026-03-08T05:40:22Z,hidden_executable_launched,siem-file-01,critical,.hidden_backdoor executed on lin-hunt-02")
    $lines.Add("2026-03-08T05:40:30Z,incident_opened,siem-file-01,high,INC-2026-5506 hidden file investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Home Directory Monitoring Policy (Excerpt)

1) Hidden executables in user home directories are prohibited unless approved.
2) SOC triage must identify suspicious hidden filename during incident response.
3) Hidden file creation followed by execution is a critical indicator.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Hidden File Triage Runbook (Excerpt)

1) Review home directory inventories and recursive ls scans for anomalies.
2) Correlate file hash catalog and inotify execution events.
3) Confirm suspicious filename through alert and SIEM evidence.
4) Quarantine host and collect binary for malware analysis.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M5-06 Hidden File (Real-World Investigation Pack)

Scenario:
File integrity monitoring identified suspicious hidden-file behavior in a Linux home directory.

Task:
Analyze the investigation pack and identify the suspicious hidden file involved in this incident.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5506
Severity: High
Queue: SOC + DFIR + Linux Ops

Summary:
A hidden executable was created and executed under a user home directory on a production node.

Scope:
- Node: lin-hunt-02
- Window: 2026-03-08 05:40 UTC
- Goal: identify suspicious hidden filename
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate home inventory, recursive listing scan, hash catalog, inotify events, hidden-file alerts, SIEM timeline, and policy/runbook guidance.
- Determine the suspicious hidden file name.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-HomeInventory -OutputPath (Join-Path $bundleRoot "evidence\filesystem\home_inventory.csv")
New-LsLaScan -OutputPath (Join-Path $bundleRoot "evidence\filesystem\recursive_ls_hidden_scan.txt")
New-FileHashCatalog -OutputPath (Join-Path $bundleRoot "evidence\filesystem\file_hash_catalog.csv")
New-InotifyEvents -OutputPath (Join-Path $bundleRoot "evidence\filesystem\inotify_events.log")
New-HiddenFileAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\hidden_file_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\home_directory_monitoring_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\hidden_file_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
