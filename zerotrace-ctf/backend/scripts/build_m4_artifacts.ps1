param(
    [string[]]$BundleName = @()
)

$ErrorActionPreference = "Stop"

$artifactRoot = Join-Path $PSScriptRoot "..\\artifacts\\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$buildRoot = Join-Path $env:TEMP "m4_artifacts_build"

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

function New-BundleDirectory {
    param([string]$Name)

    $bundlePath = Join-Path $buildRoot $Name
    New-Item -ItemType Directory -Force -Path $bundlePath | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $bundlePath "evidence") | Out-Null
    return $bundlePath
}

function Publish-Bundle {
    param([string]$Bundle)

    $source = Join-Path $buildRoot $Bundle
    $zipPath = Join-Path $artifactRoot ($Bundle + ".zip")
    if (Test-Path $zipPath) {
        Remove-Item -Force $zipPath
    }
    Compress-Archive -Path (Join-Path $source "*") -DestinationPath $zipPath -Force
}

function Build-CaseBundle {
    param([hashtable]$Case)

    $bundle = $Case["bundle"]
    if ($BundleName.Count -gt 0 -and -not ($BundleName -contains $bundle)) {
        return
    }

    $bundlePath = New-BundleDirectory -Name $bundle

    $description = @"
$($Case["title"])
Difficulty: $($Case["difficulty"])

Scenario:
$($Case["scenario"])

Task:
$($Case["task"])

Flag format:
CTF{answer}
"@

    Write-TextFile -Path (Join-Path $bundlePath "description.txt") -Content $description
    Write-TextFile -Path (Join-Path $bundlePath "evidence\\$($Case["evidence_name"])") -Content $Case["evidence_content"]
    Publish-Bundle -Bundle $bundle
}

$cases = @(
    @{
        bundle = "m4-01-web-server-crash"
        title = "M4-01 - Web Server Crash"
        difficulty = "Easy"
        scenario = "Users reported the public website was intermittently unavailable."
        task = "Identify the HTTP error returned by the service."
        evidence_name = "nginx_error.log"
        evidence_content = @"
2026-06-20T09:13:11Z [error] 1221#1221: worker_connections are not enough while connecting to upstream
2026-06-20T09:13:13Z [warn] 1221#1221: server reached connection limit
2026-06-20T09:13:15Z [error] 1221#1221: upstream prematurely closed connection while reading response header
2026-06-20T09:13:15Z status=503 Service Unavailable
"@
    },
    @{
        bundle = "m4-02-traffic-flood"
        title = "M4-02 - Traffic Flood"
        difficulty = "Easy"
        scenario = "Edge firewall telemetry detected a sudden multi-source traffic spike."
        task = "Identify the attack type."
        evidence_name = "firewall.log"
        evidence_content = @"
2026-06-20T10:02:11Z Incoming requests/sec: 42000
2026-06-20T10:02:11Z Source profile: 1500 unique IP addresses
2026-06-20T10:02:13Z Connection saturation detected
2026-06-20T10:02:15Z Service unreachable from external probes
"@
    },
    @{
        bundle = "m4-03-disk-full"
        title = "M4-03 - Disk Full"
        difficulty = "Easy"
        scenario = "A production host stopped serving requests and system usage metrics were captured."
        task = "Identify the root cause of outage."
        evidence_name = "disk_usage.txt"
        evidence_content = @"
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   50G    0G 100% /
/dev/sdb1       200G   74G  126G  37% /var/lib
"@
    },
    @{
        bundle = "m4-04-service-failure"
        title = "M4-04 - Service Failure"
        difficulty = "Easy"
        scenario = "Systemd service status snapshots were exported during triage."
        task = "Identify which service failed."
        evidence_name = "systemctl_status.txt"
        evidence_content = @"
* ssh.service - OpenSSH server daemon
  Active: active (running)

* nginx.service - nginx web server
  Active: failed (Result: exit-code)

* postgresql.service - PostgreSQL database server
  Active: active (running)
"@
    },
    @{
        bundle = "m4-05-database-overload"
        title = "M4-05 - Database Overload"
        difficulty = "Easy"
        scenario = "Application error traces pointed to database connectivity problems."
        task = "Identify the issue causing the outage."
        evidence_name = "db_connections.log"
        evidence_content = @"
2026-06-20 11:18:03 ERROR: Too many connections
2026-06-20 11:18:03 DETAIL: connection limit exceeded for role app_user
2026-06-20 11:18:03 HINT: Increase max_connections or pool appropriately
"@
    },
    @{
        bundle = "m4-06-container-crash"
        title = "M4-06 - Container Crash"
        difficulty = "Medium"
        scenario = "Container runtime logs show the workload exiting unexpectedly after deployment."
        task = "Identify the container that crashed."
        evidence_name = "docker_logs.txt"
        evidence_content = @"
2026-06-20T12:00:01Z container=db started
2026-06-20T12:00:03Z container=cache started
2026-06-20T12:00:09Z Error: container web-app exited unexpectedly
2026-06-20T12:00:10Z restart policy triggered for web-app
"@
    },
    @{
        bundle = "m4-07-kubernetes-restart-loop"
        title = "M4-07 - Kubernetes Restart Loop"
        difficulty = "Medium"
        scenario = "Kubernetes pod events indicate repeated startup failures."
        task = "Identify the Kubernetes error."
        evidence_name = "pod.log"
        evidence_content = @"
2026-06-20T12:47:11Z pod/web-api-7f9f5d5 restarting
2026-06-20T12:47:21Z pod/web-api-7f9f5d5 restarting
2026-06-20T12:47:31Z Warning BackOff: CrashLoopBackOff
"@
    },
    @{
        bundle = "m4-08-dns-outage"
        title = "M4-08 - DNS Outage"
        difficulty = "Medium"
        scenario = "DNS resolution failures were reported across multiple internal applications."
        task = "Identify the DNS service that failed."
        evidence_name = "dns_server.log"
        evidence_content = @"
2026-06-20T13:25:02Z service named active
2026-06-20T13:25:07Z service bind9 stopped
2026-06-20T13:25:10Z dns resolution failure for internal.company.local
"@
    },
    @{
        bundle = "m4-09-load-balancer-failure"
        title = "M4-09 - Load Balancer Failure"
        difficulty = "Medium"
        scenario = "Load balancer health checks reported multiple unhealthy backends."
        task = "Identify the backend service affected in the alert."
        evidence_name = "lb_healthcheck.log"
        evidence_content = @"
2026-06-20T14:08:15Z healthcheck backend server api01 unhealthy (timeout)
2026-06-20T14:08:16Z healthcheck backend server api02 unhealthy (timeout)
2026-06-20T14:08:17Z frontend status degraded
"@
    },
    @{
        bundle = "m4-10-ransomware-lockdown"
        title = "M4-10 - Ransomware Lockdown"
        difficulty = "Medium"
        scenario = "Incident responders recovered a ransom note during an enterprise outage."
        task = "Identify the primary impact caused by this attack."
        evidence_name = "ransom_note.txt"
        evidence_content = @"
Your files are encrypted.
Send 5 BTC to recover access.
Do not power off the system.
"@
    }
)

if (Test-Path $buildRoot) {
    Remove-Item -Recurse -Force $buildRoot
}
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

foreach ($case in $cases) {
    Build-CaseBundle -Case $case
}

Write-Host "M4 artifact bundles generated in $artifactRoot"
