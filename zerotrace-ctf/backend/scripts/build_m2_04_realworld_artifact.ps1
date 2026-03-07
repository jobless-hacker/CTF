param()

$ErrorActionPreference = "Stop"

$bundleName = "m2-04-unexpected-sudo-activity"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m2_04_realworld_build"
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

function New-SudoActivityLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,user,target_user,tty,pwd,command,result,source_ip,change_ticket,risk")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $users = @("deployer","ops_maya","ops_srinath","monitor_bot")
    $commands = @(
        "/usr/bin/systemctl restart nginx",
        "/usr/bin/journalctl -u nginx --since -15m",
        "/usr/bin/apt-get update",
        "/usr/bin/tail -n 100 /var/log/nginx/error.log",
        "/usr/bin/systemctl status app-api"
    )

    for ($i = 0; $i -lt 12500; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $user = $users[$i % $users.Count]
        $cmd = $commands[$i % $commands.Count]
        $ticket = if (($i % 9) -eq 0) { "CHG-2026-$((2200 + ($i % 800)))" } else { "CHG-2026-$((1200 + ($i % 800)))" }
        $result = if (($i % 97) -eq 0) { "denied" } else { "allowed" }
        $risk = if ($result -eq "denied") { "medium" } else { "low" }
        $lines.Add("$ts,prod-app-01,$user,root,pts/$((1 + ($i % 8))),/srv/app,$cmd,$result,10.20.8.$((10 + ($i % 90))),$ticket,$risk")
    }

    $lines.Add("2026-03-06T01:43:11Z,prod-app-01,john,root,pts/7,/home/john,/usr/bin/sudo -l,allowed,10.20.17.34,NO-CHANGE,medium")
    $lines.Add("2026-03-06T01:43:45Z,prod-app-01,john,root,pts/7,/home/john,/bin/su -,allowed,10.20.17.34,NO-CHANGE,high")
    $lines.Add("2026-03-06T01:44:04Z,prod-app-01,john,root,pts/7,/root,/usr/sbin/useradd backup_temp,allowed,10.20.17.34,NO-CHANGE,high")
    $lines.Add("2026-03-06T01:44:11Z,prod-app-01,john,root,pts/7,/root,/usr/bin/usermod -aG sudo backup_temp,allowed,10.20.17.34,NO-CHANGE,critical")
    $lines.Add("2026-03-06T01:44:40Z,prod-app-01,john,root,pts/7,/root,/usr/bin/cat /etc/shadow,allowed,10.20.17.34,NO-CHANGE,critical")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $accounts = @("deployer","ops_maya","ops_srinath","monitor_bot")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("MMM dd HH:mm:ss")
        $acct = $accounts[$i % $accounts.Count]
        $lines.Add("$ts prod-app-01 sudo: pam_unix(sudo:session): session opened for user root by $acct(uid=$((1000 + ($i % 20))))")
        if (($i % 3) -eq 0) {
            $lines.Add("$ts prod-app-01 sudo: pam_unix(sudo:session): session closed for user root")
        }
    }

    $lines.Add("Mar 06 01:43:09 prod-app-01 sudo: john : TTY=pts/7 ; PWD=/home/john ; USER=root ; COMMAND=/usr/bin/sudo -l")
    $lines.Add("Mar 06 01:43:44 prod-app-01 sudo: john : TTY=pts/7 ; PWD=/home/john ; USER=root ; COMMAND=/bin/su -")
    $lines.Add("Mar 06 01:44:03 prod-app-01 sudo: john : TTY=pts/7 ; PWD=/root ; USER=root ; COMMAND=/usr/sbin/useradd backup_temp")
    $lines.Add("Mar 06 01:44:10 prod-app-01 sudo: john : TTY=pts/7 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/usermod -aG sudo backup_temp")
    $lines.Add("Mar 06 01:44:39 prod-app-01 sudo: john : TTY=pts/7 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/cat /etc/shadow")
    $lines.Add("Mar 06 01:45:08 prod-app-01 sudo: pam_unix(sudo:session): session closed for user root")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SessionCommands {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,session_id,user,uid,privilege,command,outcome")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $routine = @(
        "/usr/bin/git pull",
        "/usr/bin/systemctl status app-api",
        "/usr/bin/df -h",
        "/usr/bin/tail -n 50 /var/log/app/app.log",
        "/usr/bin/free -m"
    )

    for ($i = 0; $i -lt 8200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $u = if (($i % 2) -eq 0) { "ops_maya" } else { "deployer" }
        $cmd = $routine[$i % $routine.Count]
        $lines.Add("$ts,prod-app-01,S-$((70000 + ($i % 5000))),$u,$((1001 + ($i % 7))),user,$cmd,ok")
    }

    $lines.Add("2026-03-06T01:43:42Z,prod-app-01,S-99101,john,1007,user,/usr/bin/sudo -l,ok")
    $lines.Add("2026-03-06T01:43:45Z,prod-app-01,S-99101,john,1007,root,/bin/su -,ok")
    $lines.Add("2026-03-06T01:44:04Z,prod-app-01,S-99101,john,1007,root,/usr/sbin/useradd backup_temp,ok")
    $lines.Add("2026-03-06T01:44:11Z,prod-app-01,S-99101,john,1007,root,/usr/bin/usermod -aG sudo backup_temp,ok")
    $lines.Add("2026-03-06T01:44:40Z,prod-app-01,S-99101,john,1007,root,/usr/bin/cat /etc/shadow,ok")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuditdExecve {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $bins = @("/usr/bin/systemctl","/usr/bin/journalctl","/usr/bin/tail","/usr/bin/df","/usr/bin/free")

    for ($i = 0; $i -lt 5200; $i++) {
        $epoch = [int][double]([datetimeoffset]$base.AddSeconds($i * 8)).ToUnixTimeSeconds()
        $bin = $bins[$i % $bins.Count]
        $lines.Add("type=EXECVE msg=audit($epoch.$((200 + ($i % 700))):$((40000 + $i)): argc=2 a0=""$bin"" a1=""--status"" uid=$((1001 + ($i % 4))) auid=$((1001 + ($i % 4))) exe=""$bin""")
    }

    $lines.Add("type=EXECVE msg=audit(1772751790.501:462021): argc=3 a0=""/usr/sbin/useradd"" a1=""backup_temp"" a2=""--create-home"" uid=0 auid=1007 exe=""/usr/sbin/useradd""")
    $lines.Add("type=EXECVE msg=audit(1772751798.778:462022): argc=4 a0=""/usr/bin/usermod"" a1=""-aG"" a2=""sudo"" a3=""backup_temp"" uid=0 auid=1007 exe=""/usr/bin/usermod""")
    $lines.Add("type=EXECVE msg=audit(1772751826.149:462023): argc=2 a0=""/usr/bin/cat"" a1=""/etc/shadow"" uid=0 auid=1007 exe=""/usr/bin/cat""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RoleBaseline {
    param([string]$OutputPath)

    $content = @'
Privileged Access Baseline (Production Linux)

Allowed routine sudo users:
- deployer
- ops_maya
- ops_srinath
- sre_oncall

Restricted users (must not perform root operations):
- john (role: junior_developer)
- interns
- qa_readonly

Any privileged action by restricted users requires approved emergency ticket and manager authorization.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ChangeWindow {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("change_ticket,owner,service,window_start_utc,window_end_utc,approved_by,status")
    for ($i = 0; $i -lt 2600; $i++) {
        $start = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc).AddMinutes($i * 2)
        $end = $start.AddMinutes(30)
        $lines.Add("CHG-2026-$((1200 + ($i % 800))),ops_maya,prod-app,$($start.ToString("o")),$($end.ToString("o")),infra_manager,approved")
    }
    $lines.Add("NO-CHANGE,none,none,NA,NA,NA,not_approved")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Timeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,user,host,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4700; $i++) {
        $ts = $base.AddSeconds($i * 11).ToString("o")
        $event = if (($i % 19) -eq 0) { "sudo_denied" } else { "sudo_allowed" }
        $sev = if ($event -eq "sudo_denied") { "medium" } else { "low" }
        $u = if (($i % 2) -eq 0) { "deployer" } else { "ops_maya" }
        $lines.Add("$ts,$event,$u,prod-app-01,$sev,routine privileged maintenance")
    }

    $lines.Add("2026-03-06T01:43:45Z,sudo_allowed,john,prod-app-01,high,restricted account escalated to root")
    $lines.Add("2026-03-06T01:44:11Z,policy_violation,john,prod-app-01,critical,unauthorized sudo group assignment executed")
    $lines.Add("2026-03-06T01:44:40Z,sensitive_file_access,john,prod-app-01,critical,/etc/shadow accessed via sudo")
    $lines.Add("2026-03-06T01:45:09Z,siem_case_opened,soc-automation,prod-app-01,high,INC-2026-4684 initiated")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M2-04 Unexpected Sudo Activity (Real-World Investigation Pack)

Scenario:
A production Linux host triggered privileged-access alerts indicating that a restricted developer account may have executed root-level commands.

Task:
Analyze the investigation pack and identify which account escalated privileges.

Flag format:
CTF{username}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4684
Severity: High
Queue: SOC Triage

Summary:
Policy-based alerting flagged unexpected root actions from a non-privileged developer profile on `prod-app-01`.

Scope:
- Host: prod-app-01
- Focus window: 2026-03-06 01:40 to 01:50 UTC
- Controls involved: sudo, PAM auth, auditd, SIEM timeline

Deliverable:
Identify the account that escalated privileges.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate sudo activity with auth, command, and audit execution records.
- Validate whether account behavior aligns with privileged access baseline.
- Verify if actions map to approved change windows or unauthorized escalation.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-SudoActivityLog -OutputPath (Join-Path $bundleRoot "evidence\linux\sudo_activity.csv")
New-AuthLog -OutputPath (Join-Path $bundleRoot "evidence\linux\auth.log")
New-SessionCommands -OutputPath (Join-Path $bundleRoot "evidence\linux\session_commands.csv")
New-AuditdExecve -OutputPath (Join-Path $bundleRoot "evidence\linux\auditd_execve.log")
New-RoleBaseline -OutputPath (Join-Path $bundleRoot "evidence\policy\privileged_access_baseline.txt")
New-ChangeWindow -OutputPath (Join-Path $bundleRoot "evidence\policy\change_window_registry.csv")
New-Timeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
