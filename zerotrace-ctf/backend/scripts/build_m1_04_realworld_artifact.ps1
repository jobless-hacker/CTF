param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-04-deleted-logs"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_04_realworld_build"
$bundleRoot = Join-Path $buildRoot $bundleName

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

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

function New-AuthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $hostName = "app-server-02"
    $users = @("svc_web","svc_api","backup","deploy","analyst")
    $srcIps = @("10.40.8.11","10.40.8.12","10.40.8.17","10.40.8.19","10.40.9.7")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 12600; $i++) {
        $dt = $base.AddSeconds($i * 2)
        $stamp = $dt.ToString("MMM dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $procId = 2200 + ($i % 3000)
        $user = $users[$i % $users.Count]
        $ip = $srcIps[$i % $srcIps.Count]

        if (($i % 11) -eq 0) {
            $lines.Add("$stamp $hostName sshd[$procId]: Failed password for invalid user oracle from 203.0.113.$(50 + ($i % 80)) port $(41000 + ($i % 2200)) ssh2")
        } elseif (($i % 5) -eq 0) {
            $lines.Add("$stamp $hostName sshd[$procId]: Accepted publickey for $user from $ip port $(51000 + ($i % 1000)) ssh2")
        } elseif (($i % 17) -eq 0) {
            $lines.Add("$stamp $hostName sudo: $user : TTY=pts/0 ; PWD=/opt/app ; USER=root ; COMMAND=/usr/bin/systemctl status app-api")
        } else {
            $lines.Add("$stamp $hostName sshd[$procId]: pam_unix(sshd:session): session opened for user $user(uid=$(1000 + ($i % 25))) by (uid=0)")
        }
    }

    # suspicious sequence in same log file
    $lines.Add("Mar 06 02:14:10 app-server-02 sshd[9911]: Accepted password for root from 10.40.8.19 port 51244 ssh2")
    $lines.Add("Mar 06 02:14:12 app-server-02 sudo: root : TTY=pts/1 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/tail -n 50 /var/log/auth.log")
    $lines.Add("Mar 06 02:14:14 app-server-02 sudo: root : TTY=pts/1 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/cp /var/log/auth.log /tmp/auth.log.bak")
    $lines.Add("Mar 06 02:14:16 app-server-02 sudo: root : TTY=pts/1 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/truncate -s 0 /var/log/auth.log")
    $lines.Add("Mar 06 02:14:18 app-server-02 sshd[9911]: pam_unix(sshd:session): session closed for user root")
    $lines.Add("Mar 06 02:14:24 app-server-02 audit[14420]: ANOM_ABEND auid=0 uid=0 gid=0 ses=104 subj=unconfined_u:unconfined_r:unconfined_t:s0 comm=""truncate"" exe=""/usr/bin/truncate""")

    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

function New-AuditLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $baseTs = 1772752000.100

    for ($i = 0; $i -lt 9800; $i++) {
        $ts = "{0:N3}" -f ($baseTs + ($i * 0.5))
        $eid = 70000 + $i
        $uid = if (($i % 9) -eq 0) { 1002 } else { 1001 }
        $exe = if (($i % 7) -eq 0) { "/usr/bin/cat" } elseif (($i % 13) -eq 0) { "/usr/bin/grep" } else { "/usr/bin/tail" }
        $comm = [System.IO.Path]::GetFileName($exe)
        $lines.Add("type=SYSCALL msg=audit(${ts}:${eid}): arch=c000003e syscall=2 success=yes exit=3 a0=7fffd0 a1=0 a2=0 a3=0 items=1 ppid=1211 pid=$(3000 + ($i % 6000)) auid=$uid uid=0 gid=0 euid=0 tty=pts1 ses=104 comm=""$comm"" exe=""$exe"" key=""log_watch""")
        $lines.Add("type=PATH msg=audit(${ts}:${eid}): item=0 name=""/var/log/auth.log"" inode=318221 dev=fd:00 mode=0100640 ouid=0 ogid=4 rdev=00:00 obj=system_u:object_r:var_log_t:s0 nametype=NORMAL")
    }

    # false-positive but benign truncation from logrotate on another file
    $lines.Add("type=SYSCALL msg=audit(1772753640.201:88000): arch=c000003e syscall=76 success=yes exit=0 a0=7f2aa0 a1=7f2ab0 a2=0 a3=0 items=1 ppid=1 pid=4411 auid=0 uid=0 gid=0 euid=0 tty=(none) ses=1 comm=""logrotate"" exe=""/usr/sbin/logrotate"" key=""logrotate""")
    $lines.Add("type=PATH msg=audit(1772753640.201:88000): item=0 name=""/var/log/nginx/access.log"" inode=445511 dev=fd:00 mode=0100640 ouid=0 ogid=4 rdev=00:00 obj=system_u:object_r:httpd_log_t:s0 nametype=NORMAL")

    # suspicious log clear operation
    $lines.Add("type=SYSCALL msg=audit(1772753656.243:88001): arch=c000003e syscall=76 success=yes exit=0 a0=7f2aa0 a1=7f2ab0 a2=0 a3=0 items=1 ppid=9911 pid=9927 auid=0 uid=0 gid=0 euid=0 tty=pts1 ses=104 comm=""truncate"" exe=""/usr/bin/truncate"" key=""log_integrity""")
    $lines.Add("type=CWD msg=audit(1772753656.243:88001): cwd=""/root""")
    $lines.Add("type=PATH msg=audit(1772753656.243:88001): item=0 name=""/var/log/auth.log"" inode=318221 dev=fd:00 mode=0100640 ouid=0 ogid=4 rdev=00:00 obj=system_u:object_r:var_log_t:s0 nametype=NORMAL")
    $lines.Add("type=PROCTITLE msg=audit(1772753656.243:88001): proctitle=7472756E63617465002D730030002F7661722F6C6F672F617574682E6C6F67")

    # post action evidence
    $lines.Add("type=SYSCALL msg=audit(1772753658.110:88002): arch=c000003e syscall=2 success=yes exit=3 a0=7f2aa0 a1=0 a2=0 a3=0 items=1 ppid=9911 pid=9930 auid=0 uid=0 gid=0 euid=0 tty=pts1 ses=104 comm=""stat"" exe=""/usr/bin/stat"" key=""log_integrity""")
    $lines.Add("type=PATH msg=audit(1772753658.110:88002): item=0 name=""/var/log/auth.log"" inode=318221 dev=fd:00 mode=0100640 ouid=0 ogid=4 rdev=00:00 obj=system_u:object_r:var_log_t:s0 nametype=NORMAL")

    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

function New-RsyslogMessages {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $hostName = "app-server-02"

    for ($i = 0; $i -lt 4200; $i++) {
        $dt = $base.AddSeconds($i * 3)
        $stamp = $dt.ToString("MMM dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        if (($i % 8) -eq 0) {
            $lines.Add("$stamp $hostName systemd[1]: Started Session $(300 + ($i % 70)) of user svc_web.")
        } elseif (($i % 19) -eq 0) {
            $lines.Add("$stamp $hostName CRON[$(6000 + $i)]: (root) CMD (/usr/libexec/sa/sa1 1 1)")
        } else {
            $lines.Add("$stamp $hostName rsyslogd: action 'action-1-builtin:omfile' resumed (module 'builtin:omfile') [v8.2312.0 try https://www.rsyslog.com/e/2359 ]")
        }
    }

    # critical signal
    $lines.Add("Mar 06 02:14:24 app-server-02 rsyslogd: imfile: file '/var/log/auth.log': truncation detected, output position reset (inode 318221, offset 0)")
    $lines.Add("Mar 06 02:14:25 app-server-02 rsyslogd: imfile: begin read from start for '/var/log/auth.log' due to detected truncation")

    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

function New-SiemEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp,source,host,user,src_ip,event_type,target,severity,rule_name")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 2).ToString("o")
        $user = if (($i % 5) -eq 0) { "svc_web" } else { "deploy" }
        $src = if (($i % 7) -eq 0) { "10.40.8.17" } else { "10.40.8.11" }
        $etype = if (($i % 9) -eq 0) { "AUTH_FAILURE" } else { "AUTH_SUCCESS" }
        $sev = if ($etype -eq "AUTH_FAILURE") { 30 } else { 10 }
        $rule = if ($etype -eq "AUTH_FAILURE") { "linux_auth_failed_login_volume" } else { "linux_auth_normal" }
        $lines.Add("$ts,authlog,app-server-02,$user,$src,$etype,/var/log/auth.log,$sev,$rule")
    }

    # false-positive alert
    $lines.Add("2026-03-06T02:14:00Z,siem,app-server-02,root,10.40.8.19,ADMIN_LOGIN,/var/log/auth.log,55,privileged_login_after_hours")
    # true tampering alert
    $lines.Add("2026-03-06T02:14:24Z,siem,app-server-02,root,10.40.8.19,LOG_TAMPER,/var/log/auth.log,95,linux_log_file_truncation_detected")

    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-04 Deleted Logs (Real-World Investigation Pack)

Scenario:
The SOC suspects authentication logs were tampered with after privileged access on a Linux server.
The case pack includes high-volume auth/syslog telemetry, auditd syscall records, SIEM alerts,
and forensic file metadata.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4431
Severity: High
Queue: Linux Detection Engineering

Summary:
A detection fired for potential tampering of /var/log/auth.log during a root session.
Normal SSH noise and failed-password spray events are present in the same timeline.

Scope:
- Host: app-server-02
- Primary file: /var/log/auth.log
- Suspected window: 2026-03-06 02:13 UTC - 02:16 UTC

Deliverable:
Classify primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- We observed a root login from an internal admin subnet. This alone is not conclusive.
- Correlate auth.log with audit.log and rsyslog telemetry to confirm if log content was altered.
- Watch for same inode with sudden size drop events.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$history = @'
cd /var/log
tail -n 100 auth.log
cp auth.log /tmp/auth.log.bak
truncate -s 0 auth.log
stat auth.log
exit
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\host\root_bash_history.txt") -Content $history

$timeline = @'
timestamp_utc,file_path,inode,size_bytes,event
2026-03-06T02:14:10Z,/var/log/auth.log,318221,184320,pre-incident sample
2026-03-06T02:14:16Z,/var/log/auth.log,318221,184320,command execution observed
2026-03-06T02:14:24Z,/var/log/auth.log,318221,0,size drop detected
2026-03-06T02:14:25Z,/var/log/auth.log,318221,512,new writes after truncate
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\forensics\log_file_metadata_timeline.csv") -Content $timeline

New-AuthLog -OutputPath (Join-Path $bundleRoot "evidence\logs\auth.log")
New-AuditLog -OutputPath (Join-Path $bundleRoot "evidence\audit\audit.log")
New-RsyslogMessages -OutputPath (Join-Path $bundleRoot "evidence\syslog\rsyslog_messages.log")
New-SiemEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\normalized_security_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
