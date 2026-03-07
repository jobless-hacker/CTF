param()

$ErrorActionPreference = "Stop"

$bundleName = "m4-07-kubernetes-restart-loop"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m4_07_realworld_build"
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

function New-KubeletLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $nodeName = "k8s-node-04"
    $pods = @("auth-api-6f5d7","billing-worker-7bd4a","catalog-api-9a12f","metrics-agent-b8c22")

    for ($i = 0; $i -lt 9400; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $pod = $pods[$i % $pods.Count]
        $sev = if (($i % 179) -eq 0) { "W" } else { "I" }
        $msg = if ($sev -eq "W") { "probe warning for pod $pod (transient timeout)" } else { "syncLoop UPDATE pod=$pod status=Running" }
        $lines.Add("$ts $sev kubelet[$(8000 + ($i % 1200))] node=$nodeName $msg")
    }

    $lines.Add("2026-03-07T22:51:19.114Z E kubelet[9021] node=k8s-node-04 Back-off restarting failed container web-app in pod web-app-5b5f9_prod(8f9c2a1e)")
    $lines.Add("2026-03-07T22:51:19.202Z E kubelet[9021] node=k8s-node-04 pod web-app-5b5f9 entered CrashLoopBackOff")
    $lines.Add("2026-03-07T22:51:20.008Z W kubelet[9021] node=k8s-node-04 Liveness probe failed for container web-app")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PodEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $reasons = @("Scheduled","Pulled","Created","Started","Killing")

    for ($i = 0; $i -lt 7600; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 8).ToString("o")
            namespace = "prod"
            pod = "workload-$($i % 120)-$('{0:x4}' -f $i)"
            container = "app"
            reason = $reasons[$i % $reasons.Count]
            type = if (($i % 7) -eq 0) { "Warning" } else { "Normal" }
            message = if (($i % 7) -eq 0) { "minor probe latency" } else { "operation completed" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T22:51:19Z"
        namespace = "prod"
        pod = "web-app-5b5f9"
        container = "web-app"
        reason = "BackOff"
        type = "Warning"
        message = "Back-off restarting failed container web-app"
    }) | ConvertTo-Json -Compress))
    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T22:51:19Z"
        namespace = "prod"
        pod = "web-app-5b5f9"
        container = "web-app"
        reason = "CrashLoopBackOff"
        type = "Warning"
        message = "pod entered CrashLoopBackOff state"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ContainerStatusMatrix {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,namespace,pod,container,state,restarts,last_exit_code,last_reason")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $pods = @("auth-api-6f5d7","billing-worker-7bd4a","catalog-api-9a12f","metrics-agent-b8c22")

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $pod = $pods[$i % $pods.Count]
        $rest = $i % 4
        $lines.Add("$ts,prod,$pod,app,Running,$rest,0,-")
    }

    $lines.Add("2026-03-07T22:51:19Z,prod,web-app-5b5f9,web-app,Waiting,14,137,CrashLoopBackOff")
    $lines.Add("2026-03-07T22:51:20Z,prod,web-app-5b5f9,web-app,Waiting,15,137,CrashLoopBackOff")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ProbeFailures {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,pod,container,probe_type,result,http_code,error")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $res = if (($i % 151) -eq 0) { "fail" } else { "pass" }
        $code = if ($res -eq "pass") { 200 } else { 500 }
        $err = if ($res -eq "pass") { "-" } else { "transient_probe_error" }
        $lines.Add("$ts,workload-$($i % 110),app,liveness,$res,$code,$err")
    }

    $lines.Add("2026-03-07T22:51:19Z,web-app-5b5f9,web-app,liveness,fail,0,container_not_running")
    $lines.Add("2026-03-07T22:51:20Z,web-app-5b5f9,web-app,readiness,fail,0,container_not_running")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PodResourceMetrics {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,pod,container,cpu_pct,mem_mb,mem_limit_mb,restarts_last_1h,oom_kills")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $pods = @("auth-api-6f5d7","billing-worker-7bd4a","catalog-api-9a12f","metrics-agent-b8c22")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $pod = $pods[$i % $pods.Count]
        $cpu = [Math]::Round(3 + (($i * 0.9) % 70), 1)
        $mem = 40 + (($i * 4) % 1200)
        $rest = $i % 4
        $lines.Add("$ts,$pod,app,$cpu,$mem,2048,$rest,0")
    }

    $lines.Add("2026-03-07T22:51:19Z,web-app-5b5f9,web-app,0.0,0,2048,15,1")
    $lines.Add("2026-03-07T22:51:20Z,web-app-5b5f9,web-app,0.0,0,2048,16,1")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ClusterAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("cpu_watch","latency_watch","pod_restart_watch","probe_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "k8s-" + ("{0:D8}" -f (95000000 + $i))
            severity = if (($i % 167) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine cluster fluctuation"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T22:51:19Z"
        alert_id = "k8s-99911330"
        severity = "critical"
        type = "pod_restart_loop"
        status = "open"
        detail = "pod web-app-5b5f9 in CrashLoopBackOff"
        k8s_error = "crashloopbackoff"
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
        $evt = if (($i % 311) -eq 0) { "k8s_health_review" } else { "routine_cluster_monitoring" }
        $sev = if ($evt -eq "k8s_health_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-k8s-01,$sev,background kubernetes telemetry")
    }

    $lines.Add("2026-03-07T22:51:19Z,pod_restart_loop_detected,siem-k8s-01,critical,web-app-5b5f9 entered CrashLoopBackOff")
    $lines.Add("2026-03-07T22:51:20Z,service_degraded,siem-k8s-01,high,readiness checks failing for web-app workload")
    $lines.Add("2026-03-07T22:51:24Z,incident_opened,siem-k8s-01,high,INC-2026-5389 kubernetes restart loop")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DeploymentSnippet {
    param([string]$OutputPath)

    $content = @'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: prod
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: web-app
        image: registry.local/web-app:2026.03.07
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Kubernetes Outage Runbook (Excerpt)

1) Check kubelet and pod event stream for restart-loop indicators.
2) Correlate probe failures with pod/container status.
3) If pod is repeatedly failing with BackOff, classify as crashloopbackoff.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M4-07 Kubernetes Restart Loop (Real-World Investigation Pack)

Scenario:
A production workload experienced repeated restarts, degrading service health.

Task:
Analyze the investigation pack and identify the Kubernetes error.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5389
Severity: High
Queue: SOC + SRE + Platform

Summary:
Cluster monitoring detected rapid pod restarts and service instability in the prod namespace.

Scope:
- Node: k8s-node-04
- Window: 2026-03-07 22:51 UTC
- Goal: identify Kubernetes error classification
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate kubelet logs, pod events, container status matrix, probe failures, resource metrics, cluster alerts, deployment context, runbook, and SIEM timeline.
- Determine the Kubernetes error name.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-KubeletLog -OutputPath (Join-Path $bundleRoot "evidence\k8s\kubelet.log")
New-PodEvents -OutputPath (Join-Path $bundleRoot "evidence\k8s\pod_events.jsonl")
New-ContainerStatusMatrix -OutputPath (Join-Path $bundleRoot "evidence\k8s\container_status_matrix.csv")
New-ProbeFailures -OutputPath (Join-Path $bundleRoot "evidence\service\probe_failures.csv")
New-PodResourceMetrics -OutputPath (Join-Path $bundleRoot "evidence\metrics\pod_resource_metrics.csv")
New-ClusterAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\cluster_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-DeploymentSnippet -OutputPath (Join-Path $bundleRoot "evidence\config\deployment_web_app.yaml")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\k8s_outage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
