param()

$ErrorActionPreference = "Stop"

$bundleName = "m2-01-after-hours-access"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m2_01_realworld_build"
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

function New-SSHAuthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    $users = @("admin","devops","backupsvc","monitor","batchuser")
    $ips = @("10.44.8.12","10.44.8.19","10.44.8.21","10.44.8.34","10.55.6.17")

    for ($i = 0; $i -lt 12400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("MMM dd HH:mm:ss")
        $user = $users[$i % $users.Count]
        $ip = $ips[$i % $ips.Count]
        $port = 42000 + ($i % 18000)
        $result = if (($i % 133) -eq 0) { "Failed password" } else { "Accepted publickey" }
        $procId = 18000 + $i
        if ($result -eq "Failed password") {
            $lines.Add("$ts prod-app-01 sshd[$procId]: Failed password for $user from $ip port $port ssh2")
        } else {
            $lines.Add("$ts prod-app-01 sshd[$procId]: Accepted publickey for $user from $ip port $port ssh2")
        }
    }

    $lines.Add("Mar 06 02:12:01 prod-app-01 sshd[29441]: Accepted publickey for admin from 45.83.22.91 port 53118 ssh2")
    $lines.Add("Mar 06 02:12:47 prod-app-01 sshd[29452]: Accepted publickey for admin from 45.83.22.91 port 53174 ssh2")
    $lines.Add("Mar 06 02:13:31 prod-app-01 sshd[29464]: Accepted publickey for admin from 45.83.22.91 port 53210 ssh2")
    $lines.Add("Mar 06 09:01:22 prod-app-01 sshd[30172]: Accepted publickey for admin from 10.44.8.12 port 41432 ssh2")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-BastionSessions {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,session_id,user,src_ip,target_host,auth_method,mfa,status,session_duration_s")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    $users = @("admin","devops","backupsvc","opslead")
    $srcs = @("10.44.8.12","10.44.8.19","10.55.6.17","10.55.6.44")

    for ($i = 0; $i -lt 6700; $i++) {
        $ts = $base.AddMinutes($i * 2).ToString("o")
        $user = $users[$i % $users.Count]
        $src = $srcs[$i % $srcs.Count]
        $mfa = if (($i % 43) -eq 0) { "bypass-breakglass" } else { "pass" }
        $status = "success"
        $dur = 120 + (($i * 5) % 4200)
        $lines.Add("$ts,BS-$((81000 + $i)),$user,$src,prod-app-01,publickey,$mfa,$status,$dur")
    }

    $lines.Add("2026-03-06T02:12:01Z,BS-99901,admin,45.83.22.91,prod-app-01,publickey,not_configured,success,1820")
    $lines.Add("2026-03-06T02:12:47Z,BS-99902,admin,45.83.22.91,prod-app-01,publickey,not_configured,success,1714")
    $lines.Add("2026-03-06T02:13:31Z,BS-99903,admin,45.83.22.91,prod-app-01,publickey,not_configured,success,1652")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-VPNSessions {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,user,src_ip,vpn_profile,assigned_ip,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    $users = @("admin","devops","opslead","qauser")
    $srcs = @("49.204.22.81","117.220.14.8","103.75.11.19","49.207.99.71")

    for ($i = 0; $i -lt 5300; $i++) {
        $ts = $base.AddMinutes($i * 3).ToString("o")
        $user = $users[$i % $users.Count]
        $src = $srcs[$i % $srcs.Count]
        $assigned = "10.88.2.$(20 + ($i % 140))"
        $lines.Add("$ts,$user,$src,corp-vpn,$assigned,connected")
    }

    $lines.Add("2026-03-06T02:11:50Z,admin,45.83.22.91,corp-vpn,10.88.2.222,connection_denied")
    $lines.Add("2026-03-06T02:12:40Z,admin,45.83.22.91,corp-vpn,10.88.2.222,connection_denied")
    $lines.Add("2026-03-06T02:13:20Z,admin,45.83.22.91,corp-vpn,10.88.2.222,connection_denied")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GeoipContext {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("ip,country,city,asn,known_org,classification")
    $lines.Add("10.44.8.12,private,internal,NA,corp-lan,trusted-internal")
    $lines.Add("10.44.8.19,private,internal,NA,corp-lan,trusted-internal")
    $lines.Add("10.55.6.17,private,internal,NA,corp-lan,trusted-internal")
    $lines.Add("49.204.22.81,IN,Hyderabad,AS55836,Jio,expected-vpn-home")
    $lines.Add("117.220.14.8,IN,Vijayawada,AS9829,BSNL,expected-vpn-home")
    $lines.Add("45.83.22.91,NL,Amsterdam,AS9009,M247,unexpected-external")
    $lines.Add("203.0.113.50,US,New York,AS64496,example-cdn,benign-external")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source,event_type,severity,user,src_ip,asset,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4200; $i++) {
        $ts = $base.AddMinutes($i * 2).ToString("o")
        $sev = if (($i % 171) -eq 0) { "medium" } else { "low" }
        $note = if ($sev -eq "medium") { "off-hour maintenance exception" } else { "routine auth event" }
        $lines.Add("$ts,siem,ssh_login,$sev,admin,10.44.8.12,prod-app-01,$note")
    }

    $lines.Add("2026-03-06T02:12:01Z,siem,ssh_login_after_hours,high,admin,45.83.22.91,prod-app-01,successful admin login from non-corporate network")
    $lines.Add("2026-03-06T02:12:47Z,siem,ssh_login_after_hours,high,admin,45.83.22.91,prod-app-01,repeat successful login from same external ip")
    $lines.Add("2026-03-06T02:13:31Z,siem,ssh_login_after_hours,high,admin,45.83.22.91,prod-app-01,continued off-hour access pattern")
    $lines.Add("2026-03-06T02:14:22Z,siem,vpn_bypass_attempt,high,admin,45.83.22.91,corp-vpn,vpn denied before ssh acceptance")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AccessPolicy {
    param([string]$OutputPath)

    $content = @'
Production SSH Access Policy (Excerpt)

1) Direct SSH to production hosts is allowed only from:
   - Corporate private ranges: 10.44.0.0/16, 10.55.0.0/16
   - Bastion-managed internal addresses

2) Off-hours access requires:
   - Approved maintenance ticket
   - MFA enforced via bastion/vpn

3) Any successful SSH login from non-corporate external IP must be treated as suspicious unless explicitly approved.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M2-01 After-Hours Access (Real-World Investigation Pack)

Scenario:
SOC observed successful off-hours SSH access to a production server.
Evidence includes SSH auth logs, bastion sessions, VPN records, geo-IP context, SIEM timeline events, and access policy guidance.

Task:
Identify the suspicious external IP address.

Flag format:
CTF{suspicious_ip}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4602
Severity: High
Queue: SOC Triage

Summary:
Multiple successful SSH authentications for `admin` were observed around 02:12 UTC.
Access happened outside normal change windows and may not align with bastion/VPN policy.

Scope:
- Host: prod-app-01
- User: admin
- Window: 2026-03-06 02:10 UTC to 02:20 UTC

Deliverable:
Identify the suspicious source IP.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Compare auth success records with bastion and VPN controls.
- Check whether source IP belongs to approved internal/corporate ranges.
- Use geo context and policy excerpt for final confirmation.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-SSHAuthLog -OutputPath (Join-Path $bundleRoot "evidence\auth\sshd_auth.log")
New-BastionSessions -OutputPath (Join-Path $bundleRoot "evidence\auth\bastion_sessions.csv")
New-VPNSessions -OutputPath (Join-Path $bundleRoot "evidence\auth\vpn_sessions.csv")
New-GeoipContext -OutputPath (Join-Path $bundleRoot "evidence\intel\geoip_context.csv")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-AccessPolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\prod_ssh_access_policy.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
