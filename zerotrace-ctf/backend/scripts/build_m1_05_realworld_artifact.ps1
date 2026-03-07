param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-05-web-server-crash"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_05_realworld_build"
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
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T08:40:00", [DateTimeKind]::Utc)
    $clientIps = @("10.20.30.11","10.20.30.15","10.20.30.21","10.20.30.33","10.20.30.44","10.20.30.52","10.20.31.9","10.20.31.14")
    $paths = @("/","/login","/dashboard","/api/profile","/api/summary","/assets/app.js","/assets/logo.png")
    $agents = @(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/123.0.0.0 Safari/537.36",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/122.0.0.0 Safari/537.36",
        "curl/8.6.0",
        "python-requests/2.32.2"
    )

    for ($i = 0; $i -lt 16800; $i++) {
        $ts = $base.AddMilliseconds($i * 240)
        $stamp = $ts.ToString("dd/MMM/yyyy:HH:mm:ss +0000", [System.Globalization.CultureInfo]::InvariantCulture)
        $ip = $clientIps[$i % $clientIps.Count]
        $path = $paths[$i % $paths.Count]
        $ua = $agents[$i % $agents.Count]

        $status = if (($i % 71) -eq 0) { 404 } else { 200 }
        $bytes = if ($status -eq 200) { 800 + (($i * 37) % 24000) } else { 162 }
        $rt = "{0:N3}" -f (0.030 + (($i % 9) / 200.0))
        $urt = "{0:N3}" -f (0.022 + (($i % 7) / 260.0))

        # false-positive noisy scanner requests
        if (($i % 613) -eq 0) {
            $lines.Add("$ip - - [$stamp] ""GET /wp-login.php HTTP/1.1"" 404 162 ""-"" ""Nuclei - Open Source Project (github.com/projectdiscovery/nuclei)"" ""-"" rt=$rt urt=- uct=- uht=-")
            continue
        }

        # incident surge with 503 responses
        if ($ts -ge [datetime]::SpecifyKind([datetime]"2026-03-06T09:12:00", [DateTimeKind]::Utc) -and $ts -le [datetime]::SpecifyKind([datetime]"2026-03-06T09:16:30", [DateTimeKind]::Utc)) {
            $isFailed = (($i % 3) -ne 0)
            if ($isFailed) {
                $status = 503
                $bytes = 197
                $rt = "{0:N3}" -f (1.200 + (($i % 11) / 8.0))
                $urt = "-"
                $lines.Add("$ip - - [$stamp] ""GET $path HTTP/1.1"" $status $bytes ""-"" ""$ua"" ""-"" rt=$rt urt=$urt uct=- uht=-")
                continue
            }
        }

        $lines.Add("$ip - - [$stamp] ""GET $path HTTP/1.1"" $status $bytes ""-"" ""$ua"" ""-"" rt=$rt urt=$urt uct=0.001 uht=0.003")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NginxErrorLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T08:40:00", [DateTimeKind]::Utc)
    $clients = @("10.20.30.11","10.20.30.15","10.20.30.44","10.20.31.9")

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddMilliseconds($i * 530)
        $stamp = $ts.ToString("yyyy/MM/dd HH:mm:ss")
        $workerPid = 1428 + ($i % 12)
        $connId = 5000 + ($i % 4200)
        $clientIp = $clients[$i % $clients.Count]

        if (($i % 97) -eq 0) {
            $lines.Add("$stamp [warn] ${workerPid}#${workerPid}: *$connId an upstream response is buffered to a temporary file /var/cache/nginx/proxy_temp/4/12/0000000124 while reading upstream, client: $clientIp, server: portal.company.local, request: ""GET /reports HTTP/1.1"", upstream: ""http://127.0.0.1:9000/reports"", host: ""portal.company.local""")
            continue
        }

        if ($ts -ge [datetime]::SpecifyKind([datetime]"2026-03-06T09:11:50", [DateTimeKind]::Utc) -and $ts -le [datetime]::SpecifyKind([datetime]"2026-03-06T09:16:20", [DateTimeKind]::Utc)) {
            if (($i % 2) -eq 0) {
                $lines.Add("$stamp [alert] ${workerPid}#${workerPid}: 2048 worker_connections are not enough while connecting to upstream, client: $clientIp, server: portal.company.local, request: ""GET /dashboard HTTP/1.1"", upstream: ""http://127.0.0.1:9000/dashboard"", host: ""portal.company.local""")
            } elseif (($i % 3) -eq 0) {
                $lines.Add("$stamp [error] ${workerPid}#${workerPid}: *$connId connect() failed (111: Connection refused) while connecting to upstream, client: $clientIp, server: portal.company.local, request: ""GET /api/profile HTTP/1.1"", upstream: ""http://127.0.0.1:9000/api/profile"", host: ""portal.company.local""")
            } else {
                $lines.Add("$stamp [error] ${workerPid}#${workerPid}: *$connId upstream prematurely closed connection while reading response header from upstream, client: $clientIp, server: portal.company.local, request: ""GET /api/summary HTTP/1.1"", upstream: ""http://127.0.0.1:9000/api/summary"", host: ""portal.company.local""")
            }
            continue
        }

        $lines.Add("$stamp [info] ${workerPid}#${workerPid}: *$connId client closed keepalive connection")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NginxStatusTimeseries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,active,accepts,handled,requests,reading,writing,waiting")

    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T08:55:00", [DateTimeKind]::Utc)
    $accepts = 16630948
    $handled = 16630948
    $requests = 31070465

    for ($i = 0; $i -lt 520; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        if ($i -lt 190) {
            $active = 280 + ($i % 35)
            $reading = 4 + ($i % 3)
            $writing = 26 + ($i % 11)
            $waiting = $active - $reading - $writing
            $accepts += 45 + ($i % 12)
            $handled += 45 + ($i % 12)
            $requests += 74 + ($i % 19)
        } elseif ($i -lt 280) {
            # saturation interval
            $active = 1800 + (($i - 190) * 9)
            $reading = 12 + (($i - 190) % 8)
            $writing = 1300 + (($i - 190) * 7)
            $waiting = [Math]::Max(50, $active - $reading - $writing)
            $accepts += 220 + ($i % 33)
            $handled += 180 + ($i % 24) # handled lower than accepts due limits
            $requests += 310 + ($i % 45)
        } else {
            $active = 620 + ($i % 120)
            $reading = 7 + ($i % 4)
            $writing = 210 + ($i % 44)
            $waiting = $active - $reading - $writing
            $accepts += 95 + ($i % 17)
            $handled += 95 + ($i % 17)
            $requests += 140 + ($i % 27)
        }
        $lines.Add("$ts,$active,$accepts,$handled,$requests,$reading,$writing,$waiting")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SyntheticChecks {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,probe,region,status_code,latency_ms,upstream_healthy")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T09:00:00", [DateTimeKind]::Utc)
    $probes = @("synthetic-web-01","synthetic-web-02","synthetic-web-03","synthetic-api-01")
    $regions = @("hyd","mum","blr","del")

    for ($i = 0; $i -lt 8800; $i++) {
        $ts = $base.AddMilliseconds($i * 180).ToString("o")
        $probe = $probes[$i % $probes.Count]
        $region = $regions[$i % $regions.Count]
        $code = 200
        $lat = 70 + (($i * 5) % 280)
        $healthy = "true"

        if ($i % 911 -eq 0) {
            # false positive transient network timeout
            $code = 502
            $lat = 1800
            $healthy = "true"
        }

        if ($ts -ge [datetime]::SpecifyKind([datetime]"2026-03-06T09:12:02", [DateTimeKind]::Utc).ToString("o") -and
            $ts -le [datetime]::SpecifyKind([datetime]"2026-03-06T09:16:20", [DateTimeKind]::Utc).ToString("o") -and
            ($i % 3) -ne 0) {
            $code = 503
            $lat = 2400 + (($i * 3) % 1800)
            $healthy = "false"
        }

        $lines.Add("$ts,$probe,$region,$code,$lat,$healthy")
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-JournalJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T09:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = $base.AddMilliseconds($i * 220)
        $entry = [ordered]@{
            "__REALTIME_TIMESTAMP" = [int64](($ts - [datetime]'1970-01-01').TotalMilliseconds * 1000)
            "_HOSTNAME" = "web-02"
            "_SYSTEMD_UNIT" = "portal-api.service"
            "_PID" = 2200 + ($i % 380)
            "PRIORITY" = if (($i % 12) -eq 0) { 4 } else { 6 }
            "MESSAGE" = if (($i % 14) -eq 0) {
                "Handled request batch successfully"
            } elseif (($i % 9) -eq 0) {
                "Worker queue depth above soft threshold"
            } else {
                "App heartbeat ok"
            }
        }
        $lines.Add(($entry | ConvertTo-Json -Depth 6 -Compress))
    }

    # incident entries
    $incidentEntries = @(
        [ordered]@{
            "__REALTIME_TIMESTAMP" = 1772759521000000
            "_HOSTNAME" = "web-02"
            "_SYSTEMD_UNIT" = "portal-api.service"
            "_PID" = 2241
            "PRIORITY" = 3
            "MESSAGE" = "worker pool saturated, request queue length exceeded threshold"
        },
        [ordered]@{
            "__REALTIME_TIMESTAMP" = 1772759522000000
            "_HOSTNAME" = "web-02"
            "_SYSTEMD_UNIT" = "portal-api.service"
            "_PID" = 1
            "PRIORITY" = 3
            "MESSAGE" = "portal-api.service: Main process exited, code=exited, status=1/FAILURE"
        },
        [ordered]@{
            "__REALTIME_TIMESTAMP" = 1772759523000000
            "_HOSTNAME" = "web-02"
            "_SYSTEMD_UNIT" = "portal-api.service"
            "_PID" = 1
            "PRIORITY" = 3
            "MESSAGE" = "portal-api.service: Failed with result 'exit-code'"
        },
        [ordered]@{
            "__REALTIME_TIMESTAMP" = 1772759525000000
            "_HOSTNAME" = "web-02"
            "_SYSTEMD_UNIT" = "portal-api.service"
            "_PID" = 1
            "PRIORITY" = 4
            "MESSAGE" = "portal-api.service: Scheduled restart job, restart counter is at 11"
        }
    )

    foreach ($e in $incidentEntries) {
        $lines.Add(($e | ConvertTo-Json -Depth 6 -Compress))
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LoadavgSamples {
    param([string]$OutputPath)
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,proc_loadavg_raw,parsed_running_threads,total_threads,last_pid")

    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T09:05:00", [DateTimeKind]::Utc)
    for ($i = 0; $i -lt 1300; $i++) {
        $ts = $base.AddSeconds($i).ToString("o")
        if ($i -lt 360) {
            $one = "{0:N2}" -f (1.10 + (($i % 20) / 50.0))
            $five = "{0:N2}" -f (1.30 + (($i % 18) / 60.0))
            $fifteen = "{0:N2}" -f (1.20 + (($i % 16) / 70.0))
            $running = 3 + ($i % 4)
            $threads = 1160 + ($i % 40)
        } elseif ($i -lt 740) {
            $one = "{0:N2}" -f (18.0 + (($i % 60) / 3.0))
            $five = "{0:N2}" -f (11.0 + (($i % 40) / 4.0))
            $fifteen = "{0:N2}" -f (4.5 + (($i % 30) / 8.0))
            $running = 55 + ($i % 30)
            $threads = 1300 + ($i % 90)
        } else {
            $one = "{0:N2}" -f (4.20 + (($i % 22) / 10.0))
            $five = "{0:N2}" -f (6.40 + (($i % 16) / 12.0))
            $fifteen = "{0:N2}" -f (4.10 + (($i % 12) / 15.0))
            $running = 10 + ($i % 8)
            $threads = 1220 + ($i % 50)
        }
        $lastPid = 9400 + $i
        $raw = "$one $five $fifteen $running/$threads $lastPid"
        $lines.Add("$ts,""$raw"",$running,$threads,$lastPid")
    }
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemAvailabilityEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source,service,event_type,status,severity,rule_name,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T08:55:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 2).ToString("o")
        $eventType = if (($i % 17) -eq 0) { "LATENCY_SPIKE" } else { "HEALTHCHECK_OK" }
        $sev = if ($eventType -eq "LATENCY_SPIKE") { 35 } else { 10 }
        $status = if ($eventType -eq "LATENCY_SPIKE") { "warning" } else { "ok" }
        $rule = if ($eventType -eq "LATENCY_SPIKE") { "web_latency_baseline_deviation" } else { "web_health_ok" }
        $note = if ($eventType -eq "LATENCY_SPIKE") { "transient p95 increase" } else { "normal state" }
        $lines.Add("$ts,monitoring,portal.company.local,$eventType,$status,$sev,$rule,$note")
    }

    # false-positive maintenance notice
    $lines.Add("2026-03-06T09:10:00Z,change_mgmt,portal.company.local,MAINTENANCE_NOTICE,info,15,planned_deploy_window,announced deploy window but no actual drain command executed")

    # true outage event
    $lines.Add("2026-03-06T09:12:04Z,monitoring,portal.company.local,OUTAGE,critical,96,web_service_availability_breach,successful checks dropped below 20 percent and HTTP 503 surge detected")
    $lines.Add("2026-03-06T09:12:06Z,nginx,portal.company.local,RESOURCE_LIMIT,critical,94,nginx_worker_connections_exhausted,handled lower than accepts and worker_connections alert burst")
    $lines.Add("2026-03-06T09:12:08Z,systemd,portal-api.service,PROCESS_CRASH,critical,93,systemd_auto_restart_loop,service entering auto-restart with repeated exit-code failure")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-05 Web Server Crash (Real-World Investigation Pack)

Scenario:
An internal portal became unstable and returned widespread 503 responses during a traffic surge.
The evidence pack includes high-volume NGINX access/error logs, status counters, synthetic checks,
systemd/journal telemetry, host load snapshots, and SIEM-normalized outage events.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4438
Severity: High
Queue: Web Operations + SRE

Summary:
Users reported login/dashboard failures. Monitoring shows high request volume and significant 503 spikes.
Initial triage suggests possible web-tier resource exhaustion and backend restart loops.

Scope:
- Service: portal.company.local
- Upstream app: portal-api.service (web-02)
- Window: 2026-03-06 09:11 UTC - 09:17 UTC

Deliverable:
Classify primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Not all warnings indicate outage root cause. Scanner 404s and transient 502 probes exist in baseline.
- Correlate access/error logs with status counters (`accepts` vs `handled`) and service restart evidence.
- Focus on reliability degradation (error-rate and healthcheck failure) in outage window.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$systemdStatus = @'
$ systemctl status portal-api.service

portal-api.service - Portal API service
   Loaded: loaded (/etc/systemd/system/portal-api.service; enabled)
   Active: activating (auto-restart) (Result: exit-code) since Fri 2026-03-06 09:12:02 UTC; 3s ago
  Process: 2241 ExecStart=/usr/bin/python3 /srv/portal/app.py (code=exited, status=1/FAILURE)
 Main PID: 2241 (code=exited, status=1/FAILURE)

Mar 06 09:11:58 web-02 app.py[2241]: worker pool saturated, request queue length exceeded threshold
Mar 06 09:12:01 web-02 systemd[1]: portal-api.service: Main process exited, code=exited, status=1/FAILURE
Mar 06 09:12:02 web-02 systemd[1]: portal-api.service: Failed with result 'exit-code'.
Mar 06 09:12:02 web-02 systemd[1]: portal-api.service: Scheduled restart job, restart counter is at 11.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\host\systemctl_status_portal_api.txt") -Content $systemdStatus

New-NginxAccessLog -OutputPath (Join-Path $bundleRoot "evidence\logs\nginx_access.log")
New-NginxErrorLog -OutputPath (Join-Path $bundleRoot "evidence\logs\nginx_error.log")
New-NginxStatusTimeseries -OutputPath (Join-Path $bundleRoot "evidence\monitoring\nginx_stub_status_timeseries.csv")
New-SyntheticChecks -OutputPath (Join-Path $bundleRoot "evidence\monitoring\synthetic_check_results.csv")
New-JournalJsonl -OutputPath (Join-Path $bundleRoot "evidence\host\journal_portal_api.jsonl")
New-LoadavgSamples -OutputPath (Join-Path $bundleRoot "evidence\host\proc_loadavg_samples.csv")
New-SiemAvailabilityEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\availability_events.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
