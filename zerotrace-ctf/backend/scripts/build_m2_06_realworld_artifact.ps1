param()

$ErrorActionPreference = "Stop"

$bundleName = "m2-06-new-admin-session"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m2_06_realworld_build"
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

function New-AdminChanges {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,idm_host,actor,action,target_account,role_before,role_after,status,change_ticket,source_ip,risk")

    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $actors = @("identity_bot","ops_maya","sre_oncall","iam_sync")
    $targets = @("svc_backup","svc_metrics","ops_ro","finance_ro","helpdesk_ro","audit_reader")
    $actions = @("password_rotate","role_review","group_sync","mfa_enroll")
    $ips = @("10.30.5.10","10.30.5.12","10.30.5.16","10.30.5.18")

    for ($i = 0; $i -lt 11200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $actor = $actors[$i % $actors.Count]
        $target = $targets[$i % $targets.Count]
        $action = $actions[$i % $actions.Count]
        $before = if ($target -like "*ro") { "read_only" } else { "service" }
        $after = if ($action -eq "mfa_enroll") { "read_only+mfa" } else { $before }
        $ticket = "CHG-2026-$((1400 + ($i % 900)))"
        $risk = if (($i % 211) -eq 0) { "medium" } else { "low" }
        $lines.Add("$ts,idm-srv-01,$actor,$action,$target,$before,$after,success,$ticket,$($ips[$i % $ips.Count]),$risk")
    }

    $lines.Add("2026-03-07T00:13:12Z,idm-srv-01,john,create_user,backup_admin,none,admin,success,NO-CHANGE,10.30.5.44,critical")
    $lines.Add("2026-03-07T00:13:21Z,idm-srv-01,john,group_add,backup_admin,admin,admin+prod_ops,success,NO-CHANGE,10.30.5.44,critical")
    $lines.Add("2026-03-07T00:13:35Z,idm-srv-01,john,mfa_disable,backup_admin,admin+prod_ops,admin+prod_ops-no_mfa,success,NO-CHANGE,10.30.5.44,critical")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PrivilegedSessions {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $users = @("ops_maya","sre_oncall","deployer","audit_reader")
    $cmds = @("/usr/bin/systemctl status app-api","/usr/bin/journalctl -u sshd -n 40","/usr/bin/tail -n 100 /var/log/auth.log","/usr/bin/df -h")

    for ($i = 0; $i -lt 7900; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("MMM dd HH:mm:ss")
        $u = $users[$i % $users.Count]
        $cmd = $cmds[$i % $cmds.Count]
        $lines.Add("$ts bastion-01 sudo: $u : TTY=pts/$((1 + ($i % 8))) ; PWD=/home/$u ; USER=root ; COMMAND=$cmd")
    }

    $lines.Add("Mar 07 00:14:03 bastion-01 sshd[90112]: Accepted publickey for backup_admin from 10.30.5.44 port 52111 ssh2")
    $lines.Add("Mar 07 00:14:11 bastion-01 sudo: backup_admin : TTY=pts/7 ; PWD=/home/backup_admin ; USER=root ; COMMAND=/usr/bin/id")
    $lines.Add("Mar 07 00:14:19 bastion-01 sudo: backup_admin : TTY=pts/7 ; PWD=/home/backup_admin ; USER=root ; COMMAND=/usr/bin/cat /etc/sudoers")
    $lines.Add("Mar 07 00:14:44 bastion-01 sudo: backup_admin : TTY=pts/7 ; PWD=/home/backup_admin ; USER=root ; COMMAND=/usr/bin/ls /srv/keys")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DirectoryAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $events = @("user_password_reset","group_membership_sync","role_validation","policy_refresh")

    for ($i = 0; $i -lt 4700; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 11).ToString("o")
            idm_host = "idm-srv-01"
            actor = if (($i % 2) -eq 0) { "identity_bot" } else { "ops_maya" }
            event_type = $events[$i % $events.Count]
            target = if (($i % 2) -eq 0) { "svc_backup" } else { "finance_ro" }
            status = if (($i % 139) -eq 0) { "review_required" } else { "ok" }
            severity = if (($i % 139) -eq 0) { "medium" } else { "low" }
            note = "routine identity governance telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T00:13:12Z"
        idm_host = "idm-srv-01"
        actor = "john"
        event_type = "user_created_with_admin_role"
        target = "backup_admin"
        status = "open"
        severity = "high"
        note = "privileged account created outside approved process"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp = "2026-03-07T00:13:35Z"
        idm_host = "idm-srv-01"
        actor = "john"
        event_type = "mfa_disabled_for_admin"
        target = "backup_admin"
        status = "open"
        severity = "critical"
        note = "new admin account provisioned without MFA"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-EndpointCommands {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,host,user,session_id,privilege,command,outcome")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $cmds = @(
        "/usr/bin/systemctl status app-api",
        "/usr/bin/ansible-playbook deploy.yml",
        "/usr/bin/tail -n 50 /var/log/app/app.log",
        "/usr/bin/git pull",
        "/usr/bin/free -m"
    )

    for ($i = 0; $i -lt 8400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $user = if (($i % 2) -eq 0) { "ops_maya" } else { "deployer" }
        $cmd = $cmds[$i % $cmds.Count]
        $lines.Add("$ts,idm-srv-01,$user,S-$((600000 + $i)),user,$cmd,ok")
    }

    $lines.Add("2026-03-07T00:13:09Z,idm-srv-01,john,S-991610,user,/usr/bin/sudo -l,ok")
    $lines.Add("2026-03-07T00:13:12Z,idm-srv-01,john,S-991610,root,/usr/sbin/useradd backup_admin,ok")
    $lines.Add("2026-03-07T00:13:21Z,idm-srv-01,john,S-991610,root,/usr/sbin/usermod -aG admin,prod_ops backup_admin,ok")
    $lines.Add("2026-03-07T00:13:35Z,idm-srv-01,john,S-991610,root,/usr/bin/disable-mfa backup_admin,ok")
    $lines.Add("2026-03-07T00:13:58Z,idm-srv-01,john,S-991610,root,/usr/bin/passwd backup_admin,ok")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ChangeRegistry {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("change_ticket,owner,scope,window_start_utc,window_end_utc,approved_by,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 2800; $i++) {
        $start = $base.AddMinutes($i * 2)
        $end = $start.AddMinutes(30)
        $lines.Add("CHG-2026-$((1400 + ($i % 900))),ops_maya,identity-maint,$($start.ToString("o")),$($end.ToString("o")),infra_manager,approved")
    }

    $lines.Add("NO-CHANGE,none,none,NA,NA,NA,not_approved")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AdminPolicy {
    param([string]$OutputPath)

    $content = @'
Privileged Account Governance Baseline

Approved admin account patterns:
- breakglass_admin_*
- sre_oncall
- ops_maya

Creation rules:
1) New admin accounts require approved change ticket.
2) MFA is mandatory for all admin accounts.
3) Direct admin account creation by junior developers is prohibited.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Timeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,actor,target,host,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $event = if (($i % 199) -eq 0) { "identity_change_review" } else { "identity_change_ok" }
        $sev = if ($event -eq "identity_change_review") { "medium" } else { "low" }
        $lines.Add("$ts,$event,identity_bot,svc_backup,idm-srv-01,$sev,routine identity lifecycle processing")
    }

    $lines.Add("2026-03-07T00:13:12Z,admin_account_created,john,backup_admin,idm-srv-01,high,privileged account created with no approved change")
    $lines.Add("2026-03-07T00:13:35Z,mfa_disabled,john,backup_admin,idm-srv-01,critical,mfa removed from newly created admin account")
    $lines.Add("2026-03-07T00:14:03Z,first_admin_login,backup_admin,prod-access,bastion-01,high,new account initiated privileged session")
    $lines.Add("2026-03-07T00:14:44Z,siem_case_opened,soc-automation,INC-2026-4782,siem-core-01,high,suspicious admin account workflow detected")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M2-06 New Admin Session (Real-World Investigation Pack)

Scenario:
Identity governance monitoring detected an unexpected privileged account creation followed by immediate admin session activity.

Task:
Analyze the investigation pack and identify the suspicious admin account.

Flag format:
CTF{account_name}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4782
Severity: High
Queue: SOC Triage

Summary:
Identity and bastion telemetry indicate that a new admin account was created outside normal governance flow and used shortly afterward.

Scope:
- Identity host: idm-srv-01
- Access host: bastion-01
- Investigation window: 2026-03-07 00:13 to 00:15 UTC

Deliverable:
Identify the suspicious admin account.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate identity change records, command execution, and privileged login sessions.
- Validate account creation against change registry and admin governance policy.
- Determine which admin account is suspicious.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-AdminChanges -OutputPath (Join-Path $bundleRoot "evidence\identity\admin_account_changes.csv")
New-DirectoryAudit -OutputPath (Join-Path $bundleRoot "evidence\identity\directory_audit.jsonl")
New-EndpointCommands -OutputPath (Join-Path $bundleRoot "evidence\endpoint\command_audit.csv")
New-PrivilegedSessions -OutputPath (Join-Path $bundleRoot "evidence\auth\privileged_sessions.log")
New-ChangeRegistry -OutputPath (Join-Path $bundleRoot "evidence\policy\change_registry.csv")
New-AdminPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\admin_governance_baseline.txt")
New-Timeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
