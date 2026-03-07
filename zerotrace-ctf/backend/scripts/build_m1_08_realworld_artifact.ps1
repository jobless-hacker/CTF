param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-08-config-file-tampering"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_08_realworld_build"
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

function Write-LinesFile {
    param(
        [string]$Path,
        [System.Collections.Generic.List[string]]$Lines
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    [System.IO.File]::WriteAllLines($Path, $Lines, [System.Text.Encoding]::UTF8)
}

function New-NginxAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T09:30:00", [DateTimeKind]::Utc)
    $ips = @("10.70.4.11","10.70.4.14","10.70.4.18","10.70.4.25","10.70.5.9","10.70.5.15","10.70.5.20","10.70.6.7")
    $paths = @("/","/login","/dashboard","/api/profile","/api/summary","/healthz","/assets/app.js","/assets/logo.png")
    $ua = @(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/123.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_6_1) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36",
        "curl/8.7.1"
    )

    $incidentStart = [datetime]::SpecifyKind([datetime]"2026-03-06T10:42:15", [DateTimeKind]::Utc)
    $incidentEnd = [datetime]::SpecifyKind([datetime]"2026-03-06T10:48:40", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 16200; $i++) {
        $ts = $base.AddMilliseconds($i * 380)
        $stamp = $ts.ToString("dd/MMM/yyyy:HH:mm:ss +0000", [System.Globalization.CultureInfo]::InvariantCulture)
        $ip = $ips[$i % $ips.Count]
        $path = $paths[$i % $paths.Count]
        $agent = $ua[$i % $ua.Count]
        $reqId = "req-" + (200000 + $i)
        $status = 200
        $bytes = 980 + (($i * 29) % 42000)
        $loc = "-"
        $rt = "{0:N3}" -f (0.021 + (($i % 10) / 280.0))

        # normal app redirects that are benign
        if ($path -eq "/logout") {
            $status = 302
            $loc = "https://portal.company.local/login"
            $bytes = 174
        }

        # noise from scanners
        if (($i % 577) -eq 0) {
            $lines.Add("$ip - - [$stamp] ""GET /wp-admin HTTP/1.1"" 404 162 ""-"" ""Nuclei - Open Source Project (github.com/projectdiscovery/nuclei)"" reqid=$reqId rt=$rt loc=""-""")
            continue
        }

        # tampered redirect behavior
        if ($ts -ge $incidentStart -and $ts -le $incidentEnd -and ($path -eq "/login" -or $path -eq "/dashboard")) {
            $status = 302
            $bytes = 188
            $loc = "https://portal-company-login.com/login"
            $rt = "{0:N3}" -f (0.045 + (($i % 7) / 180.0))
        }

        $lines.Add("$ip - - [$stamp] ""GET $path HTTP/1.1"" $status $bytes ""-"" ""$agent"" reqid=$reqId rt=$rt loc=""$loc""")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NginxErrorLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T09:30:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5800; $i++) {
        $ts = $base.AddMilliseconds($i * 620)
        $stamp = $ts.ToString("yyyy/MM/dd HH:mm:ss")
        $worker = 1700 + ($i % 14)
        $conn = 4100 + ($i % 2900)

        if (($i % 67) -eq 0) {
            $lines.Add("$stamp [warn] ${worker}#${worker}: *$conn upstream response is buffered to a temporary file /var/cache/nginx/proxy_temp/3/09/0000000093 while reading upstream, client: 10.70.4.11, server: portal.company.local, request: ""GET /reports HTTP/1.1"", upstream: ""http://127.0.0.1:9000/reports"", host: ""portal.company.local""")
            continue
        }

        if ($ts -ge [datetime]::SpecifyKind([datetime]"2026-03-06T10:41:54", [DateTimeKind]::Utc) -and
            $ts -le [datetime]::SpecifyKind([datetime]"2026-03-06T10:42:15", [DateTimeKind]::Utc)) {
            $lines.Add("$stamp [notice] ${worker}#${worker}: signal process started")
            $lines.Add("$stamp [notice] ${worker}#${worker}: configuration file /etc/nginx/nginx.conf test is successful")
            continue
        }

        $lines.Add("$stamp [info] ${worker}#${worker}: *$conn client closed keepalive connection")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuditConfigWatch {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = 1772799000.500

    for ($i = 0; $i -lt 9100; $i++) {
        $ts = "{0:N3}" -f ($base + ($i * 0.7))
        $eid = 99000 + $i
        $comm = if (($i % 8) -eq 0) { "ansible-playboo" } elseif (($i % 11) -eq 0) { "cp" } else { "cat" }
        $exe = if ($comm -eq "ansible-playboo") { "/usr/bin/ansible-playbook" } elseif ($comm -eq "cp") { "/usr/bin/cp" } else { "/usr/bin/cat" }
        $target = if (($i % 9) -eq 0) { "/etc/portal/cache_rules.conf" } else { "/etc/portal/feature_flags.conf" }
        $lines.Add("type=SYSCALL msg=audit(${ts}:${eid}): arch=c000003e syscall=2 success=yes exit=3 a0=7fff a1=0 a2=0 a3=0 items=1 ppid=1213 pid=$(4200 + ($i % 3300)) auid=1001 uid=0 gid=0 euid=0 tty=pts0 ses=119 comm=""$comm"" exe=""$exe"" key=""portal_config_watch""")
        $lines.Add("type=PATH msg=audit(${ts}:${eid}): item=0 name=""$target"" inode=$(520000 + ($i % 8000)) dev=fd:00 mode=0100640 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:etc_t:s0 nametype=NORMAL")
    }

    # benign config deploy with approved service account
    $lines.Add("type=SYSCALL msg=audit(1772803311.104:108201): arch=c000003e syscall=2 success=yes exit=3 a0=7fff a1=0 a2=0 a3=0 items=1 ppid=5101 pid=5144 auid=1002 uid=0 gid=0 euid=0 tty=pts1 ses=121 comm=""ansible-playbook"" exe=""/usr/bin/ansible-playbook"" key=""portal_config_watch""")
    $lines.Add("type=PATH msg=audit(1772803311.104:108201): item=0 name=""/etc/portal/cache_rules.conf"" inode=680101 dev=fd:00 mode=0100640 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:etc_t:s0 nametype=NORMAL")

    # malicious redirect config write
    $lines.Add("type=SYSCALL msg=audit(1772803314.244:108241): arch=c000003e syscall=2 success=yes exit=3 a0=7fff a1=0 a2=0 a3=0 items=1 ppid=6120 pid=6144 auid=33 uid=33 gid=33 euid=33 tty=pts2 ses=129 comm=""vim"" exe=""/usr/bin/vim"" key=""portal_config_watch""")
    $lines.Add("type=CWD msg=audit(1772803314.244:108241): cwd=""/etc/portal""")
    $lines.Add("type=PATH msg=audit(1772803314.244:108241): item=0 name=""/etc/portal/server.conf"" inode=681900 dev=fd:00 mode=0100640 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:etc_t:s0 nametype=NORMAL")
    $lines.Add("type=PROCTITLE msg=audit(1772803314.244:108241): proctitle=76696D002F6574632F706F7274616C2F7365727665722E636F6E66")
    $lines.Add("type=SYSCALL msg=audit(1772803315.109:108242): arch=c000003e syscall=82 success=yes exit=0 a0=7fff a1=7fff a2=1ff a3=0 items=1 ppid=6120 pid=6144 auid=33 uid=33 gid=33 euid=33 tty=pts2 ses=129 comm=""vim"" exe=""/usr/bin/vim"" key=""portal_config_watch""")
    $lines.Add("type=PATH msg=audit(1772803315.109:108242): item=0 name=""/etc/portal/server.conf"" inode=681900 dev=fd:00 mode=0100640 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:etc_t:s0 nametype=NORMAL")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SyntheticValidation {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,probe,region,path,http_status,location_header,latency_ms")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T10:20:00", [DateTimeKind]::Utc)
    $probes = @("synthetic-web-01","synthetic-web-02","synthetic-web-03")
    $regions = @("hyd","mum","blr")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddMilliseconds($i * 450).ToString("o")
        $probe = $probes[$i % $probes.Count]
        $region = $regions[$i % $regions.Count]
        $path = if (($i % 3) -eq 0) { "/login" } elseif (($i % 5) -eq 0) { "/dashboard" } else { "/" }
        $status = 200
        $location = "-"
        $lat = 65 + (($i * 7) % 320)

        if (($i % 401) -eq 0) {
            # benign internal redirect
            $status = 302
            $location = "https://portal.company.local/login"
            $lat = 120
        }

        if ($ts -ge [datetime]::SpecifyKind([datetime]"2026-03-06T10:42:20", [DateTimeKind]::Utc).ToString("o") -and
            $ts -le [datetime]::SpecifyKind([datetime]"2026-03-06T10:48:40", [DateTimeKind]::Utc).ToString("o") -and
            ($path -eq "/login" -or $path -eq "/dashboard")) {
            $status = 302
            $location = "https://portal-company-login.com/login"
            $lat = 210 + (($i * 5) % 90)
        }

        $lines.Add("$ts,$probe,$region,$path,$status,$location,$lat")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ChangeControlData {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("ticket_id,opened_utc,approved_utc,service,requested_by,approved_by,status,config_scope,notes")

    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T08:00:00", [DateTimeKind]::Utc)
    for ($i = 0; $i -lt 1500; $i++) {
        $open = $base.AddMinutes($i * 14)
        $approve = $open.AddMinutes(42)
        $service = if (($i % 4) -eq 0) { "portal-nginx" } else { "portal-api" }
        $scope = if ($service -eq "portal-nginx") { "/etc/portal/cache_rules.conf" } else { "/etc/portal/feature_flags.conf" }
        $lines.Add("CHG-$((8100 + $i)),$($open.ToString('o')),$($approve.ToString('o')),$service,ops-deploy,change-manager,approved,$scope,routine platform update")
    }

    # misleading draft ticket, never approved
    $lines.Add("CHG-9722,2026-03-06T10:39:00Z,,portal-nginx,unknown_user,,draft,/etc/portal/server.conf,temporary redirect test requested but not approved")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source,event_type,severity,asset,status,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T09:40:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $etype = if (($i % 21) -eq 0) { "web_scanner_probe" } else { "normal_portal_traffic" }
        $sev = if ($etype -eq "web_scanner_probe") { 25 } else { 5 }
        $status = if ($etype -eq "web_scanner_probe") { "closed_false_positive" } else { "informational" }
        $note = if ($etype -eq "web_scanner_probe") { "404 probes to wp-admin path" } else { "healthy baseline" }
        $lines.Add("$ts,siem,$etype,$sev,portal.company.local,$status,$note")
    }

    $lines.Add("2026-03-06T10:42:16Z,siem,config_integrity_drift,92,/etc/portal/server.conf,open,hash mismatch against approved baseline")
    $lines.Add("2026-03-06T10:42:18Z,siem,external_redirect_detected,94,portal.company.local,open,login endpoint redirecting to portal-company-login.com")
    $lines.Add("2026-03-06T10:42:20Z,siem,change_control_mismatch,88,portal-nginx,open,no approved change ticket for modified file")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-08 Unexpected Redirect After Reload (Real-World Investigation Pack)

Scenario:
After a routine NGINX reload, users reported being redirected to an unexpected external domain.
The evidence includes high-volume web logs, config baselines, audit file-watch records,
change-control exports, synthetic validation checks, and SIEM events.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4453
Severity: High
Queue: Web Platform Security + Detection Engineering

Summary:
Portal login traffic started redirecting to portal-company-login.com after config reload.
No approved change request is currently linked to /etc/portal/server.conf updates.

Scope:
- Service: portal.company.local
- Suspected file: /etc/portal/server.conf
- Window: 2026-03-06 10:41 UTC to 10:49 UTC

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Normal scanner probes and benign internal redirects exist in the same timeline.
- Correlate config diff, audit file-write records, and change-ticket status.
- Validate observed redirect targets from access logs and synthetic checks.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$baseline = @'
server_name=portal.company.local
redirect=false
target=
maintenance_mode=false
allow_internal_only=false
allowed_redirect_hosts=portal.company.local
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\config\server.conf.baseline") -Content $baseline

$current = @'
server_name=portal.company.local
redirect=true
target=portal-company-login.com
maintenance_mode=false
allow_internal_only=false
allowed_redirect_hosts=portal.company.local
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\config\server.conf.current") -Content $current

$diffText = @'
diff --git a/etc/portal/server.conf b/etc/portal/server.conf
index 4f8ca17..89ba203 100640
--- a/etc/portal/server.conf
+++ b/etc/portal/server.conf
@@ -1,6 +1,6 @@
 server_name=portal.company.local
-redirect=false
-target=
+redirect=true
+target=portal-company-login.com
 maintenance_mode=false
 allow_internal_only=false
 allowed_redirect_hosts=portal.company.local
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\config\server_conf_diff.patch") -Content $diffText

$hashTimeline = @'
timestamp_utc,file_path,sha256,recorded_by
2026-03-06T10:30:00Z,/etc/portal/server.conf,8eaf66a6532f496513d5c7538db1f6f7afe2a0ffabf4db6683ee71f80c130617,config-monitor
2026-03-06T10:41:55Z,/etc/portal/server.conf,6fcd154fd8d9a87d3f8af3aa0d1452d90f8a4e5f5d1237f473f8fd944fc4888e,config-monitor
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\forensics\config_hash_timeline.csv") -Content $hashTimeline

New-NginxAccessLog -OutputPath (Join-Path $bundleRoot "evidence\logs\nginx_access.log")
New-NginxErrorLog -OutputPath (Join-Path $bundleRoot "evidence\logs\nginx_error.log")
New-AuditConfigWatch -OutputPath (Join-Path $bundleRoot "evidence\audit\audit_config_watch.log")
New-SyntheticValidation -OutputPath (Join-Path $bundleRoot "evidence\validation\synthetic_http_checks.csv")
New-ChangeControlData -OutputPath (Join-Path $bundleRoot "evidence\change_control\change_tickets.csv")
New-SiemEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\normalized_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
