param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-14-docker-misconfiguration"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_14_realworld_build"
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

function New-DockerEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T08:00:00", [DateTimeKind]::Utc)
    $services = @("api","web","worker","db")
    $actions = @("start","stop","health_status: healthy","health_status: unhealthy","kill","create")

    for ($i = 0; $i -lt 8400; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("o")
        $svc = $services[$i % $services.Count]
        $act = $actions[$i % $actions.Count]
        $cid = "ctr-$((50000 + $i))"
        $lines.Add("$ts docker daemon: container=$cid service=$svc action=""$act"" image=$svc:latest")
    }

    $lines.Add("2026-03-06T09:41:54Z docker daemon: compose up detected for stack=staging-app actor=platform-deployer")
    $lines.Add("2026-03-06T09:41:56Z docker daemon: container=ctr-db-9012 service=db action=""recreate"" image=mysql:8 reason=compose-change")
    $lines.Add("2026-03-06T09:41:58Z docker daemon: container=ctr-db-9012 service=db action=""start"" publish=""0.0.0.0:3306->3306/tcp""")
    $lines.Add("2026-03-06T09:42:01Z docker daemon: warning service=db published on all interfaces")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SsTimeseries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,local_address,port,process,state,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T09:20:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6200; $i++) {
        $tsObj = $base.AddSeconds($i * 2)
        $ts = $tsObj.ToString("o")
        $addr = if (($i % 2) -eq 0) { "127.0.0.1" } else { "0.0.0.0" }
        $port = if (($i % 5) -eq 0) { 8080 } else { 22 }
        $proc = if ($port -eq 22) { "sshd" } else { "docker-proxy(web)" }
        $note = "expected"

        if ($tsObj -ge [datetime]::SpecifyKind([datetime]"2026-03-06T09:41:58", [DateTimeKind]::Utc) -and
            $port -eq 22) {
            $note = "baseline-ssh"
        }

        $lines.Add("$ts,$addr,$port,$proc,LISTEN,$note")
    }

    # incident exposure
    $lines.Add("2026-03-06T09:42:02Z,0.0.0.0,3306,docker-proxy(db),LISTEN,unexpected-public-bind")
    $lines.Add("2026-03-06T09:42:10Z,0.0.0.0,3306,docker-proxy(db),LISTEN,unexpected-public-bind")
    $lines.Add("2026-03-06T09:42:18Z,0.0.0.0,3306,docker-proxy(db),LISTEN,unexpected-public-bind")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ExternalScanResults {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,scanner,source_ip,target_ip,port,state,service,banner,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T09:35:00", [DateTimeKind]::Utc)
    $scanners = @("asm-probe-01","asm-probe-02","asm-probe-03")

    for ($i = 0; $i -lt 4600; $i++) {
        $tsObj = $base.AddSeconds($i * 3)
        $ts = $tsObj.ToString("o")
        $scanner = $scanners[$i % $scanners.Count]
        $src = "198.51.100.$(20 + ($i % 40))"
        $port = if (($i % 4) -eq 0) { 443 } elseif (($i % 9) -eq 0) { 8080 } else { 22 }
        $svc = if ($port -eq 443) { "https" } elseif ($port -eq 8080) { "http-alt" } else { "ssh" }
        $banner = if ($svc -eq "https") { "nginx" } elseif ($svc -eq "http-alt") { "staging-web-ui" } else { "OpenSSH_9.3" }
        $class = if ($port -eq 8080) { "expected-public-service" } else { "baseline-surface" }
        $lines.Add("$ts,$scanner,$src,198.51.100.40,$port,open,$svc,$banner,$class")
    }

    $lines.Add("2026-03-06T09:42:30Z,asm-probe-01,198.51.100.22,198.51.100.40,3306,open,mysql,MySQL 8.0.36,unexpected-exposure")
    $lines.Add("2026-03-06T09:43:10Z,asm-probe-02,198.51.100.29,198.51.100.40,3306,open,mysql,MySQL 8.0.36,unexpected-exposure")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FlowTelemetry {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,dst_port,proto,sessions,bytes,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T09:30:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 9200; $i++) {
        $tsObj = $base.AddMilliseconds($i * 700)
        $ts = $tsObj.ToString("o")
        $src = "10.70.4.$(20 + ($i % 100))"
        $dst = "172.19.0.$(5 + ($i % 40))"
        $port = if (($i % 5) -eq 0) { 3306 } else { 8080 }
        $proto = "tcp"
        $sessions = 1 + ($i % 4)
        $bytes = 900 + (($i * 12) % 70000)
        $class = if ($port -eq 3306) { "internal-db-traffic" } else { "app-traffic" }
        $lines.Add("$ts,$src,$dst,$port,$proto,$sessions,$bytes,$class")
    }

    $lines.Add("2026-03-06T09:42:31Z,45.83.22.91,198.51.100.40,3306,tcp,6,18440,external-db-attempt")
    $lines.Add("2026-03-06T09:42:37Z,45.83.22.91,198.51.100.40,3306,tcp,4,12820,external-db-attempt")
    $lines.Add("2026-03-06T09:43:02Z,203.0.113.77,198.51.100.40,3306,tcp,3,9640,external-db-attempt")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-GovernanceAndChange {
    param(
        [string]$GovernancePath,
        [string]$ChangePath
    )

    $gov = New-Object System.Collections.Generic.List[string]
    $gov.Add("timestamp_utc,control_id,severity,resource,status,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T08:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $status = if (($i % 19) -eq 0) { "closed_false_positive" } else { "informational" }
        $note = if ($status -eq "closed_false_positive") { "approved public web port exposure" } else { "compose baseline compliant" }
        $gov.Add("$ts,DOCKER-PORT-EXPOSURE-01,22,staging-app,$status,$note")
    }
    $gov.Add("2026-03-06T09:42:20Z,DOCKER-PORT-EXPOSURE-01,93,staging-db.company.local:3306,open,database published on all interfaces (0.0.0.0:3306)")
    Write-LinesFile -Path $GovernancePath -Lines $gov

    $chg = New-Object System.Collections.Generic.List[string]
    $chg.Add("ticket_id,opened_utc,approved_utc,service,requested_by,status,change_scope,notes")
    $chBase = [datetime]::SpecifyKind([datetime]"2026-03-01T09:00:00", [DateTimeKind]::Utc)
    for ($i = 0; $i -lt 1700; $i++) {
        $open = $chBase.AddMinutes($i * 11)
        $approve = $open.AddMinutes(35)
        $scope = if (($i % 3) -eq 0) { "web port tuning" } else { "worker memory limits" }
        $chg.Add("CHG-$((9000 + $i)),$($open.ToString('o')),$($approve.ToString('o')),staging-app,platform-deployer,approved,$scope,routine update")
    }
    $chg.Add("CHG-10777,2026-03-06T09:39:00Z,,staging-app,platform-deployer,draft,db port publish test,not approved")
    Write-LinesFile -Path $ChangePath -Lines $chg
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-14 Unexpected Database Reachability (Real-World Investigation Pack)

Scenario:
A Dockerized staging database became reachable from outside its intended network.
Evidence includes compose baseline/current drift, container events, host socket telemetry,
external scan outputs, network flow data, governance findings, and change-control records.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4501
Severity: High
Queue: Platform Security + Cloud Infra

Summary:
External attack-surface monitoring detected open MySQL service on staging host.
Service was expected to be reachable only from app_internal Docker network.

Scope:
- Host: staging-db.company.local (198.51.100.40)
- Port: 3306/tcp
- Window: 2026-03-06 09:42 UTC onward

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- External scans include expected open web-service ports.
- Correlate compose port binding, host LISTEN state, and external scan confirmation.
- Validate if change ticket approved this DB exposure before concluding impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$composeBaseline = @'
version: "3.8"
services:
  db:
    image: mysql:8
    restart: always
    environment:
      MYSQL_DATABASE: appdb
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
    ports:
      - "127.0.0.1:3306:3306"
    networks:
      - app_internal
networks:
  app_internal:
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\containers\docker-compose.baseline.yml") -Content $composeBaseline

$composeCurrent = @'
version: "3.8"
services:
  db:
    image: mysql:8
    restart: always
    environment:
      MYSQL_DATABASE: appdb
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
    ports:
      - "3306:3306"
    networks:
      - app_internal
networks:
  app_internal:
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\containers\docker-compose.current.yml") -Content $composeCurrent

$composeDiff = @'
diff --git a/docker-compose.yml b/docker-compose.yml
index 2f44bc3..9344aa8 100644
--- a/docker-compose.yml
+++ b/docker-compose.yml
@@ -8,7 +8,7 @@ services:
       MYSQL_DATABASE: appdb
       MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
     ports:
-      - "127.0.0.1:3306:3306"
+      - "3306:3306"
     networks:
       - app_internal
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\containers\compose_diff.patch") -Content $composeDiff

New-DockerEvents -OutputPath (Join-Path $bundleRoot "evidence\containers\docker_events.log")
New-SsTimeseries -OutputPath (Join-Path $bundleRoot "evidence\host\ss_listening_timeseries.csv")
New-ExternalScanResults -OutputPath (Join-Path $bundleRoot "evidence\network\external_scan_results.csv")
New-FlowTelemetry -OutputPath (Join-Path $bundleRoot "evidence\network\flow_telemetry.csv")
New-GovernanceAndChange -GovernancePath (Join-Path $bundleRoot "evidence\security\governance_findings.csv") -ChangePath (Join-Path $bundleRoot "evidence\operations\change_log.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
