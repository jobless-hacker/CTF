param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-19-kubernetes-crash"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m1_19_realworld_build"
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

function New-KubeEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T03:00:00", [DateTimeKind]::Utc)
    $objects = @("deploy/payment-api","pod/payment-api-6d4f8db7bd-kkj2m","pod/payment-api-6d4f8db7bd-lr9c5","hpa/payment-api","rs/payment-api-6d4f8db7bd")
    $types = @("Normal","Normal","Warning","Normal")
    $reasons = @("Scheduled","Pulled","BackOff","Created","Started","Killing")

    for ($i = 0; $i -lt 9400; $i++) {
        $ts = $base.AddSeconds($i * 3).ToString("o")
        $obj = $objects[$i % $objects.Count]
        $t = $types[$i % $types.Count]
        $reason = $reasons[$i % $reasons.Count]
        $msg = if ($reason -eq "BackOff") { "Back-off restarting failed container" } elseif ($reason -eq "Killing") { "Stopping container payment-api" } else { "Routine controller action" }
        $ns = if (($i % 7) -eq 0) { "payments" } else { "payments"
        }
        $lines.Add("$ts namespace=$ns type=$t reason=$reason object=$obj message=""$msg""")
    }

    $lines.Add("2026-03-06T09:17:44Z namespace=payments type=Warning reason=OOMKilled object=pod/payment-api-6d4f8db7bd-kkj2m message=""Container payment-api exceeded memory limit and was terminated""")
    $lines.Add("2026-03-06T09:17:51Z namespace=payments type=Warning reason=BackOff object=pod/payment-api-6d4f8db7bd-kkj2m message=""Back-off restarting failed container""")
    $lines.Add("2026-03-06T09:18:03Z namespace=payments type=Warning reason=CrashLoopBackOff object=pod/payment-api-6d4f8db7bd-lr9c5 message=""Container in CrashLoopBackOff state""")
    $lines.Add("2026-03-06T09:18:11Z namespace=payments type=Warning reason=Unhealthy object=pod/payment-api-6d4f8db7bd-lr9c5 message=""Readiness probe failed: HTTP probe failed with statuscode: 503""")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RestartSeries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,namespace,pod,container,restart_count,state,last_exit_reason,last_exit_code")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T04:30:00", [DateTimeKind]::Utc)
    $pods = @("payment-api-6d4f8db7bd-kkj2m","payment-api-6d4f8db7bd-lr9c5","payment-api-6d4f8db7bd-pv2qc")

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("o")
        $pod = $pods[$i % $pods.Count]
        $count = [math]::Floor($i / 350)
        $state = if (($i % 41) -eq 0) { "Terminated" } else { "Running" }
        $reason = if ($state -eq "Terminated") { "Error" } else { "Completed" }
        $exit = if ($state -eq "Terminated") { 1 } else { 0 }
        $lines.Add("$ts,payments,$pod,payment-api,$count,$state,$reason,$exit")
    }

    $lines.Add("2026-03-06T09:17:44Z,payments,payment-api-6d4f8db7bd-kkj2m,payment-api,37,Terminated,OOMKilled,137")
    $lines.Add("2026-03-06T09:17:52Z,payments,payment-api-6d4f8db7bd-kkj2m,payment-api,38,Waiting,CrashLoopBackOff,137")
    $lines.Add("2026-03-06T09:18:03Z,payments,payment-api-6d4f8db7bd-lr9c5,payment-api,39,Waiting,CrashLoopBackOff,137")
    $lines.Add("2026-03-06T09:18:17Z,payments,payment-api-6d4f8db7bd-pv2qc,payment-api,41,Waiting,CrashLoopBackOff,137")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-KubeletLogs {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T04:00:00", [DateTimeKind]::Utc)
    $nodes = @("ip-10-44-8-31","ip-10-44-8-32","ip-10-44-8-33")

    for ($i = 0; $i -lt 7200; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $node = $nodes[$i % $nodes.Count]
        $msg = if (($i % 113) -eq 0) {
            "readiness probe failed but recovered within retry threshold"
        } else {
            "syncLoop (housekeeping) completed"
        }
        $lines.Add("$ts $node kubelet[$((1200 + ($i % 240)))] info: $msg")
    }

    $lines.Add("2026-03-06T09:17:44.118Z ip-10-44-8-32 kubelet[1417] warning: Container payment-api in pod payment-api-6d4f8db7bd-kkj2m terminated with OOMKilled")
    $lines.Add("2026-03-06T09:17:51.911Z ip-10-44-8-32 kubelet[1417] warning: Back-off restarting failed container payment-api in pod payment-api-6d4f8db7bd-kkj2m")
    $lines.Add("2026-03-06T09:18:03.404Z ip-10-44-8-31 kubelet[1379] warning: Liveness probe failed for container payment-api, HTTP 503")
    $lines.Add("2026-03-06T09:18:08.842Z ip-10-44-8-31 kubelet[1379] warning: Killing container payment-api due to failed liveness probe")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-MetricsSamples {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,namespace,pod,cpu_millicores,memory_mib,memory_limit_mib,restarts,availability_state")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T05:00:00", [DateTimeKind]::Utc)
    $pods = @("payment-api-6d4f8db7bd-kkj2m","payment-api-6d4f8db7bd-lr9c5","payment-api-6d4f8db7bd-pv2qc")

    for ($i = 0; $i -lt 5300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $pod = $pods[$i % $pods.Count]
        $cpu = 180 + (($i * 7) % 520)
        $mem = 220 + (($i * 9) % 680)
        $limit = 1024
        $restarts = [math]::Floor($i / 500)
        $state = if ($restarts -gt 20) { "degraded" } else { "healthy" }
        $lines.Add("$ts,payments,$pod,$cpu,$mem,$limit,$restarts,$state")
    }

    $lines.Add("2026-03-06T09:17:42Z,payments,payment-api-6d4f8db7bd-kkj2m,410,742,128,37,degraded")
    $lines.Add("2026-03-06T09:17:50Z,payments,payment-api-6d4f8db7bd-lr9c5,428,755,128,39,degraded")
    $lines.Add("2026-03-06T09:18:03Z,payments,payment-api-6d4f8db7bd-pv2qc,402,761,128,41,down")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IngressProbes {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,probe_region,service,endpoint,http_status,latency_ms,result")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T06:00:00", [DateTimeKind]::Utc)
    $regions = @("hyd","mum","blr","del")

    for ($i = 0; $i -lt 4600; $i++) {
        $tsObj = $base.AddMilliseconds($i * 710)
        $ts = $tsObj.ToString("o")
        $region = $regions[$i % $regions.Count]
        $status = 200
        $lat = 95 + (($i * 3) % 240)
        $result = "ok"
        if (($i % 340) -eq 0) {
            $status = 503
            $lat = 3100 + (($i * 7) % 2200)
            $result = "degraded"
        }
        $lines.Add("$ts,$region,payment-api,/health,$status,$lat,$result")
    }

    $lines.Add("2026-03-06T09:17:45Z,hyd,payment-api,/health,503,5401,degraded")
    $lines.Add("2026-03-06T09:17:52Z,mum,payment-api,/health,503,5830,degraded")
    $lines.Add("2026-03-06T09:18:04Z,blr,payment-api,/health,0,10000,timeout")
    $lines.Add("2026-03-06T09:18:12Z,del,payment-api,/health,503,6122,degraded")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DeploymentRevisions {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("revision,deployed_utc,deployer,image,replicas,requests_cpu,requests_mem,limits_cpu,limits_mem,change_summary")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 2200; $i++) {
        $rev = 500 + $i
        $ts = $base.AddMinutes($i * 18).ToString("o")
        $img = "registry.company.local/payments/payment-api:2026.03.$((1 + ($i % 28)).ToString('D2'))"
        $lines.Add("$rev,$ts,release-bot,$img,6,300m,384Mi,1000m,1024Mi,routine patch release")
    }

    $lines.Add("2781,2026-03-06T09:16:58Z,platform-engineer,registry.company.local/payments/payment-api:2026.03.06-hotfix,6,300m,384Mi,1000m,128Mi,hotfix rollout with mistaken memory limit")
    $lines.Add("2782,2026-03-06T09:22:20Z,platform-engineer,registry.company.local/payments/payment-api:2026.03.06-hotfix2,6,300m,384Mi,1000m,1024Mi,rollback memory limit after outage")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ChangeRecords {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("change_id,opened_utc,service,requested_by,approved_by,status,summary")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-01T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 1700; $i++) {
        $ts = $base.AddMinutes($i * 21).ToString("o")
        $svc = if (($i % 2) -eq 0) { "payment-api" } else { "checkout-api" }
        $lines.Add("CHG-$((64000 + $i)),$ts,$svc,release-bot,change-advisory,approved,routine deployment maintenance")
    }

    $lines.Add("CHG-66781,2026-03-06T09:12:00Z,payment-api,platform-engineer,change-advisory,approved,emergency hotfix rollout")
    $lines.Add("CHG-66781-REV,2026-03-06T09:20:30Z,payment-api,platform-engineer,change-advisory,approved,rollback misconfigured memory limit")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-19 Kubernetes Service Instability (Real-World Investigation Pack)

Scenario:
A Kubernetes payment workload entered repeated restart loops and service quality collapsed.
Evidence includes Kubernetes events, pod restart telemetry, kubelet node logs, metrics samples,
ingress probe outcomes, deployment revision history, and operational change records.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4539
Severity: Critical
Queue: SRE + Platform Security

Summary:
payment-api users reported failures and timeouts. Kubernetes indicates restart storms
and failing readiness/liveness probes after an emergency deployment.

Scope:
- Namespace: payments
- Deployment: payment-api
- Incident window: 2026-03-06 09:17 UTC onward

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate deployment revision changes with restart spikes and probe failures.
- Validate whether outage source is resource misconfiguration or external attack.
- Use pod/node/ingress evidence to classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-KubeEvents -OutputPath (Join-Path $bundleRoot "evidence\k8s\kube_events.log")
New-RestartSeries -OutputPath (Join-Path $bundleRoot "evidence\k8s\pod_restart_timeseries.csv")
New-KubeletLogs -OutputPath (Join-Path $bundleRoot "evidence\k8s\kubelet_node_logs.log")
New-MetricsSamples -OutputPath (Join-Path $bundleRoot "evidence\k8s\metrics_samples.csv")
New-IngressProbes -OutputPath (Join-Path $bundleRoot "evidence\network\ingress_probe_results.csv")
New-DeploymentRevisions -OutputPath (Join-Path $bundleRoot "evidence\k8s\deployment_revisions.csv")
New-ChangeRecords -OutputPath (Join-Path $bundleRoot "evidence\operations\change_records.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
