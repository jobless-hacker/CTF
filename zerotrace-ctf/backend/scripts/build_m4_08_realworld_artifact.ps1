param()

$ErrorActionPreference = "Stop"

$bundleName = "m4-08-dns-outage"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m4"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m4_08_realworld_build"
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

function New-NamedLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $hostName = "dns-core-01"
    $zones = @("company.example","internal.local","prod.service.local","cdn.company.example")

    for ($i = 0; $i -lt 9600; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("dd-MMM-yyyy HH:mm:ss.fff", [System.Globalization.CultureInfo]::InvariantCulture)
        $procId = 10000 + ($i % 600)
        $zone = $zones[$i % $zones.Count]
        $sev = if (($i % 181) -eq 0) { "warning" } else { "info" }
        $msg = if ($sev -eq "warning") { "delayed response from upstream for zone $zone" } else { "client query accepted zone=$zone type=A status=NOERROR" }
        $lines.Add("$ts named[$procId]: ${sev}: $msg host=$hostName")
    }

    $lines.Add("07-Mar-2026 23:17:42.105 named[11881]: error: service bind9 stopped")
    $lines.Add("07-Mar-2026 23:17:42.221 named[11881]: critical: dns resolution failure for all forward lookups")
    $lines.Add("07-Mar-2026 23:17:43.004 named[11881]: error: exiting due to fatal configuration/runtime issue")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ResolverTimeseries {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,total_queries,noerror,nxdomain,servfail,timeout,avg_latency_ms")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 8600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $total = 150 + (($i * 5) % 2800)
        $noerr = [Math]::Max(0, $total - (25 + ($i % 20)))
        $nxd = 10 + ($i % 9)
        $sf = ($i % 4)
        $to = ($i % 3)
        $lat = 6 + (($i * 3) % 140)
        $lines.Add("$ts,$total,$noerr,$nxd,$sf,$to,$lat")
    }

    $lines.Add("2026-03-07T23:17:42Z,3021,120,45,1455,1401,0")
    $lines.Add("2026-03-07T23:17:43Z,2898,88,50,1380,1380,0")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SystemctlSnapshot {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $services = @("sshd","chronyd","rsyslog","node-exporter","docker")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $svc = $services[$i % $services.Count]
        $state = if (($i % 191) -eq 0) { "degraded" } else { "active (running)" }
        $lines.Add("$ts systemctl status ${svc}.service -> Active: $state")
    }

    $lines.Add("2026-03-07T23:17:42Z systemctl status bind9.service -> Active: failed (Result: exit-code)")
    $lines.Add("2026-03-07T23:17:42Z systemctl status bind9.service -> Main PID: 0 (code=exited, status=1/FAILURE)")
    $lines.Add("2026-03-07T23:17:43Z systemctl status bind9.service -> Unit entered failed state")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DigProbeResults {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,resolver,query_name,query_type,result_code,response_ms,error")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $names = @("api.company.example","auth.company.example","db.internal.local","cdn.company.example")

    for ($i = 0; $i -lt 6400; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $q = $names[$i % $names.Count]
        $code = if (($i % 157) -eq 0) { "SERVFAIL" } else { "NOERROR" }
        $ms = 5 + (($i * 4) % 220)
        $err = if ($code -eq "NOERROR") { "-" } else { "transient_upstream_error" }
        $lines.Add("$ts,dns-core-01,$q,A,$code,$ms,$err")
    }

    $lines.Add("2026-03-07T23:17:42Z,dns-core-01,api.company.example,A,SERVFAIL,0,dns resolution failure")
    $lines.Add("2026-03-07T23:17:43Z,dns-core-01,auth.company.example,A,SERVFAIL,0,dns resolution failure")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsPacketSummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,dst_ip,src_port,dst_port,protocol,query_count,response_count,rcode")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $src = "10.$(30 + ($i % 90)).$((20 + $i) % 220).$((40 + $i) % 230)"
        $dst = "172.20.10.53"
        $q = 1 + ($i % 35)
        $r = [Math]::Max(0, $q - ($i % 3))
        $rcode = if ($r -eq 0) { "SERVFAIL" } else { "NOERROR" }
        $lines.Add("$ts,$src,$dst,$((30000 + $i) % 65535),53,UDP,$q,$r,$rcode")
    }

    $lines.Add("2026-03-07T23:17:42Z,10.55.14.21,172.20.10.53,45123,53,UDP,980,0,SERVFAIL")
    $lines.Add("2026-03-07T23:17:43Z,10.56.14.22,172.20.10.53,45124,53,UDP,1012,0,SERVFAIL")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AlertFeed {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("latency_watch","servfail_watch","timeout_watch","query_spike_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 12).ToString("o")
            alert_id = "dns-" + ("{0:D8}" -f (97000000 + $i))
            severity = if (($i % 173) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine dns fluctuation"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-07T23:17:42Z"
        alert_id = "dns-99922004"
        severity = "critical"
        type = "dns_service_down"
        status = "open"
        detail = "bind9 service failed; resolver returning SERVFAIL"
        failed_service = "bind9"
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
        $evt = if (($i % 307) -eq 0) { "dns_health_review" } else { "routine_dns_monitoring" }
        $sev = if ($evt -eq "dns_health_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-dns-01,$sev,background dns telemetry")
    }

    $lines.Add("2026-03-07T23:17:42Z,dns_service_failed,siem-dns-01,critical,bind9 service failed on resolver node")
    $lines.Add("2026-03-07T23:17:43Z,resolution_failures,siem-dns-01,high,system-wide SERVFAIL spikes observed")
    $lines.Add("2026-03-07T23:17:47Z,incident_opened,siem-dns-01,high,INC-2026-5402 dns outage incident")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-NamedConfig {
    param([string]$OutputPath)

    $content = @'
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    forwarders { 1.1.1.1; 8.8.8.8; };
};
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
DNS Outage Runbook (Excerpt)

1) Confirm resolver service status via systemctl.
2) Correlate named logs and dig probe SERVFAIL spikes.
3) Identify exact failed DNS service unit.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M4-08 DNS Outage (Real-World Investigation Pack)

Scenario:
Name resolution failures were observed across production services.

Task:
Analyze the investigation pack and identify which DNS service failed.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5402
Severity: High
Queue: SOC + NOC + SRE

Summary:
Critical resolver degradation detected; internal and external services report lookup failures.

Scope:
- Resolver host: dns-core-01
- Window: 2026-03-07 23:17 UTC
- Goal: identify failed DNS service name
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate named logs, resolver timeseries, systemctl snapshots, dig probe outcomes, packet summaries, alerts, config, runbook, and SIEM timeline.
- Determine which DNS service failed.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-NamedLog -OutputPath (Join-Path $bundleRoot "evidence\dns\named.log")
New-ResolverTimeseries -OutputPath (Join-Path $bundleRoot "evidence\dns\resolver_timeseries.csv")
New-SystemctlSnapshot -OutputPath (Join-Path $bundleRoot "evidence\system\systemctl_snapshot.log")
New-DigProbeResults -OutputPath (Join-Path $bundleRoot "evidence\service\dig_probe_results.csv")
New-DnsPacketSummary -OutputPath (Join-Path $bundleRoot "evidence\network\dns_packet_summary.csv")
New-AlertFeed -OutputPath (Join-Path $bundleRoot "evidence\security\dns_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-NamedConfig -OutputPath (Join-Path $bundleRoot "evidence\config\named.conf")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\dns_outage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
