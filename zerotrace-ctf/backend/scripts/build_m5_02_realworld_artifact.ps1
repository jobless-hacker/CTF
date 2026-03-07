param()

$ErrorActionPreference = "Stop"

$bundleName = "m5-02-ssh-login-trail"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m5_02_realworld_build"
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

function New-AuthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hostName = "lin-app-02"
    $users = @("ubuntu","opsadmin","devsvc","deploy","batchsvc","audituser")

    for ($i = 0; $i -lt 8900; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("MMM dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $usr = $users[$i % $users.Count]
        $procId = 14000 + ($i % 800)
        $port = (31000 + $i) % 65000
        $ip = "10.$(18 + ($i % 40)).$((40 + $i) % 210).$((20 + $i) % 230)"
        $lines.Add("$ts $hostName sshd[$procId]: Accepted publickey for $usr from $ip port $port ssh2")

        if (($i % 250) -eq 0) {
            $noiseIp = "198.51.100.$(10 + ($i % 130))"
            $noisePid = 17000 + ($i % 500)
            $lines.Add("$ts $hostName sshd[$noisePid]: Failed password for invalid user oracle from $noiseIp port $((35000 + $i) % 65000) ssh2")
        }
    }

    $lines.Add("Mar 08 02:11:24 lin-app-02 sshd[24109]: Failed password for root from 203.0.113.7 port 48911 ssh2")
    $lines.Add("Mar 08 02:11:29 lin-app-02 sshd[24109]: Failed password for root from 203.0.113.7 port 48911 ssh2")
    $lines.Add("Mar 08 02:11:33 lin-app-02 sshd[24109]: Failed password for root from 203.0.113.7 port 48911 ssh2")
    $lines.Add("Mar 08 02:11:36 lin-app-02 sshd[24109]: Accepted password for root from 203.0.113.7 port 48911 ssh2")
    $lines.Add("Mar 08 02:11:52 lin-app-02 sudo: root : TTY=pts/0 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/id")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SshSummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,username,failed_count,success_count,host,geo_hint")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("ubuntu","deploy","opsadmin","devsvc")

    for ($i = 0; $i -lt 6600; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $ip = "10.$(30 + ($i % 30)).$((10 + $i) % 220).$((40 + $i) % 220)"
        $u = $users[$i % $users.Count]
        $fails = if (($i % 191) -eq 0) { 2 } else { 0 }
        $success = if ($fails -eq 0) { 1 } else { 0 }
        $lines.Add("$ts,$ip,$u,$fails,$success,lin-app-02,corp-network")
    }

    $lines.Add("2026-03-08T02:11:20Z,203.0.113.7,root,12,1,lin-app-02,unknown-vps")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-VpnGatewayLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5300; $i++) {
        $ts = $base.AddSeconds($i * 11).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $user = "emp_{0:D4}" -f ($i % 5000)
        $src = "100.64.$(10 + ($i % 80)).$((20 + $i) % 230)"
        $assigned = "10.$(40 + ($i % 20)).$((10 + $i) % 220).$((30 + $i) % 220)"
        $lines.Add("$ts vpn-gw auth=success user=$user src_ip=$src assigned_ip=$assigned mfa=ok")
    }

    $lines.Add("2026-03-08T02:11:38Z vpn-gw correlation alert=no_vpn_mapping src_ip=203.0.113.7 event=direct_ssh_observed host=lin-app-02")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GeoIpReference {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("ip,asn,provider,region,confidence")
    for ($i = 0; $i -lt 4200; $i++) {
        $ip = "10.$(20 + ($i % 50)).$((30 + $i) % 220).$((40 + $i) % 220)"
        $lines.Add("$ip,AS64512,Corp Internal,IN-HYD,high")
    }
    $lines.Add("203.0.113.7,AS399999,Example Hosting Ltd,unknown,medium")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IdentityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("ssh_rate_watch","offhours_login_watch","credential_stuffing_watch","geovelocity_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "ssh-" + ("{0:D8}" -f (81230000 + $i))
            severity = if (($i % 173) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "background authentication noise"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T02:11:36Z"
        alert_id = "ssh-99922014"
        severity = "critical"
        type = "external_root_login"
        status = "open"
        detail = "successful root authentication from untrusted external address"
        suspicious_ip = "203.0.113.7"
        host = "lin-app-02"
    }) | ConvertTo-Json -Compress))
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $evt = if (($i % 293) -eq 0) { "ssh_review" } else { "routine_auth_monitoring" }
        $sev = if ($evt -eq "ssh_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-auth-01,$sev,authentication telemetry baseline")
    }

    $lines.Add("2026-03-08T02:11:24Z,failed_root_login,siem-auth-01,high,multiple failed root attempts from 203.0.113.7")
    $lines.Add("2026-03-08T02:11:36Z,external_root_login_success,siem-auth-01,critical,root login accepted from external source 203.0.113.7")
    $lines.Add("2026-03-08T02:11:46Z,incident_opened,siem-auth-01,high,INC-2026-5502 ssh login trail investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RemotePolicy {
    param([string]$OutputPath)

    $content = @'
Remote Access Policy (Excerpt)

1) Root login from external/public internet addresses is prohibited.
2) SSH admin access must originate from approved corporate/VPN ranges only.
3) Any successful external root login is a critical security incident.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
SSH Intrusion Triage Runbook (Excerpt)

1) Confirm successful vs failed logins in auth logs.
2) Identify external source IP tied to suspicious successful login.
3) Correlate VPN gateway mapping and SIEM critical alerts.
4) Escalate and isolate host if external root login is confirmed.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M5-02 SSH Login Trail (Real-World Investigation Pack)

Scenario:
Monitoring detected suspicious SSH behavior with possible root compromise on a production Linux host.

Task:
Analyze the investigation pack and identify the external attacker IP tied to the suspicious successful login.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5502
Severity: High
Queue: SOC + Linux Ops + IAM

Summary:
Auth telemetry indicates repeated root login attempts followed by suspicious success from an external address.

Scope:
- Host: lin-app-02
- Window: 2026-03-08 02:11 UTC
- Goal: identify the external attacker source IP
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate auth.log, SSH summary, VPN gateway logs, GeoIP reference, identity alerts, policy/runbook, and SIEM timeline.
- Determine the external IP responsible for the suspicious successful root login.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-AuthLog -OutputPath (Join-Path $bundleRoot "evidence\auth\auth.log")
New-SshSummary -OutputPath (Join-Path $bundleRoot "evidence\auth\ssh_attempt_summary.csv")
New-VpnGatewayLog -OutputPath (Join-Path $bundleRoot "evidence\network\vpn_gateway.log")
New-GeoIpReference -OutputPath (Join-Path $bundleRoot "evidence\threatintel\geoip_reference.csv")
New-IdentityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\identity_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-RemotePolicy -OutputPath (Join-Path $bundleRoot "evidence\policy\remote_access_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\ssh_intrusion_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
