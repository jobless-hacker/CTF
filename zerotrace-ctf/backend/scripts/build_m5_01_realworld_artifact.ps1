param()

$ErrorActionPreference = "Stop"

$bundleName = "m5-01-suspicious-user"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m5_01_realworld_build"
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

function New-PasswdSnapshot {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("root:x:0:0:root:/root:/bin/bash")
    $lines.Add("daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin")
    $lines.Add("bin:x:2:2:bin:/bin:/usr/sbin/nologin")
    $lines.Add("sys:x:3:3:sys:/dev:/usr/sbin/nologin")
    $lines.Add("sync:x:4:65534:sync:/bin:/bin/sync")
    $lines.Add("games:x:5:60:games:/usr/games:/usr/sbin/nologin")
    $lines.Add("man:x:6:12:man:/var/cache/man:/usr/sbin/nologin")
    $lines.Add("lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin")
    $lines.Add("mail:x:8:8:mail:/var/mail:/usr/sbin/nologin")
    $lines.Add("news:x:9:9:news:/var/spool/news:/usr/sbin/nologin")
    $lines.Add("uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin")
    $lines.Add("proxy:x:13:13:proxy:/bin:/usr/sbin/nologin")
    $lines.Add("www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin")
    $lines.Add("backup:x:34:34:backup:/var/backups:/usr/sbin/nologin")
    $lines.Add("list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin")
    $lines.Add("irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin")
    $lines.Add("gnats:x:41:41:Gnats Bug-Reporting System:/var/lib/gnats:/usr/sbin/nologin")
    $lines.Add("nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin")
    $lines.Add("systemd-network:x:998:998:systemd Network Management:/:/usr/sbin/nologin")
    $lines.Add("systemd-timesync:x:997:997:systemd Time Synchronization:/:/usr/sbin/nologin")
    $lines.Add("messagebus:x:100:102::/nonexistent:/usr/sbin/nologin")
    $lines.Add("syslog:x:101:103::/home/syslog:/usr/sbin/nologin")

    for ($i = 0; $i -lt 8600; $i++) {
        $uid = 2000 + $i
        $gid = 2000 + $i
        $user = "emp_{0:D4}" -f $i
        $lines.Add(("{0}:x:{1}:{2}:Employee Account {3}:/home/{0}:/bin/bash" -f $user, $uid, $gid, $i))
    }

    $lines.Add("ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash")
    $lines.Add("opsadmin:x:1101:1101:Operations Admin:/home/opsadmin:/bin/bash")
    $lines.Add("devsvc:x:1102:1102:Service User:/srv/devsvc:/usr/sbin/nologin")
    $lines.Add("hacker:x:1002:1002:Unknown:/home/hacker:/bin/bash")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-UserChangeAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $act = if (($i % 181) -eq 0) { "passwd-change" } else { "group-sync" }
        $acct = if (($i % 181) -eq 0) { "emp_{0:D4}" -f ($i % 8600) } else { "svc_$($i % 20)" }
        $lines.Add("$ts auditd action=$act account=$acct actor=iam-sync result=success")
    }

    $lines.Add("2026-03-08T02:03:11Z auditd action=useradd account=hacker actor=root tty=pts/2 result=success")
    $lines.Add("2026-03-08T02:03:12Z auditd action=usermod account=hacker actor=root detail='added to sudo group' result=success")
    $lines.Add("2026-03-08T02:03:13Z auditd action=mkdir account=hacker actor=root path=/home/hacker result=success")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hostName = "lin-prod-01"
    $users = @("ubuntu","opsadmin","emp_0021","emp_0432","emp_1234","devsvc")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("MMM dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $usr = $users[$i % $users.Count]
        $ip = "10.$(20 + ($i % 40)).$((30 + $i) % 220).$((50 + $i) % 230)"
        $lines.Add("$ts $hostName sshd[$(12000 + ($i % 600))]: Accepted publickey for $usr from $ip port $((30000 + $i) % 65000) ssh2")
    }

    $lines.Add("Mar 08 02:03:15 lin-prod-01 useradd[23114]: new user: name=hacker, UID=1002, GID=1002, home=/home/hacker, shell=/bin/bash")
    $lines.Add("Mar 08 02:03:16 lin-prod-01 sshd[23115]: Accepted password for hacker from 203.0.113.77 port 49211 ssh2")
    $lines.Add("Mar 08 02:03:20 lin-prod-01 sudo: hacker : TTY=pts/2 ; PWD=/home/hacker ; USER=root ; COMMAND=/bin/cat /etc/shadow")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HomeInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,home_path,owner,size_mb,file_count,suspicious_markers")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $user = "emp_{0:D4}" -f ($i % 8600)
        $size = 120 + (($i * 3) % 5400)
        $count = 40 + (($i * 7) % 18000)
        $lines.Add("$ts,/home/$user,$user,$size,$count,-")
    }

    $lines.Add("2026-03-08T02:03:13Z,/home/hacker,hacker,18,23,new_home_created")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Alerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("login_watch","group_membership_watch","sudo_watch","file_access_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "iam-" + ("{0:D8}" -f (11100000 + $i))
            severity = if (($i % 177) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine identity activity"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T02:03:11Z"
        alert_id = "iam-99944120"
        severity = "critical"
        type = "unauthorized_account_created"
        status = "open"
        detail = "unapproved local account created on production host"
        suspicious_user = "hacker"
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
        $evt = if (($i % 317) -eq 0) { "identity_review" } else { "routine_identity_monitoring" }
        $sev = if ($evt -eq "identity_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-iam-01,$sev,background account telemetry")
    }

    $lines.Add("2026-03-08T02:03:11Z,suspicious_local_account,siem-iam-01,critical,new unapproved user account hacker created")
    $lines.Add("2026-03-08T02:03:16Z,suspicious_login,siem-iam-01,high,hacker performed first login from external address")
    $lines.Add("2026-03-08T02:03:22Z,incident_opened,siem-iam-01,high,INC-2026-5501 suspicious user investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Account Provisioning Policy (Excerpt)

1) All local user creation must be approved via IAM ticket.
2) Unapproved local accounts on production are critical incidents.
3) Security teams must identify the exact suspicious username.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Linux User Investigation Runbook (Excerpt)

1) Compare /etc/passwd snapshot with approved accounts.
2) Correlate user creation audit logs with first-login activity.
3) Identify suspicious account and escalate immediately.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M5-01 Suspicious User (Real-World Investigation Pack)

Scenario:
A production Linux host shows signs of unauthorized account provisioning.

Task:
Analyze the investigation pack and identify the suspicious user.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5501
Severity: High
Queue: SOC + IAM + Linux Ops

Summary:
Identity telemetry flagged unapproved account creation and suspicious authentication activity.

Scope:
- Host: lin-prod-01
- Window: 2026-03-08 02:03 UTC
- Goal: identify exact suspicious username
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate passwd snapshot, user-change audit logs, auth logs, home inventory, alerts, policy/runbook, and SIEM timeline.
- Determine the suspicious user account.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-PasswdSnapshot -OutputPath (Join-Path $bundleRoot "evidence\identity\passwd_snapshot.txt")
New-UserChangeAudit -OutputPath (Join-Path $bundleRoot "evidence\identity\user_change_audit.log")
New-AuthLog -OutputPath (Join-Path $bundleRoot "evidence\auth\auth.log")
New-HomeInventory -OutputPath (Join-Path $bundleRoot "evidence\identity\home_inventory.csv")
New-Alerts -OutputPath (Join-Path $bundleRoot "evidence\security\identity_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\account_provisioning_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\linux_user_investigation_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
