param()

$ErrorActionPreference = "Stop"

$bundleName = "m6-02-dns-beaconing"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m6_02_realworld_build"
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

function New-DnsQueryLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $domains = @("api.github.com","packages.ubuntu.com","repo.mysql.com","pypi.org","cdn.cloudflare.net","updates.internal.local")

    for ($i = 0; $i -lt 9300; $i++) {
        $ts = $base.AddMilliseconds($i * 550).ToString("o")
        $src = "192.168.1.$(10 + ($i % 90))"
        $q = $domains[$i % $domains.Count]
        $rtype = if (($i % 7) -eq 0) { "AAAA" } else { "A" }
        $rcode = if (($i % 223) -eq 0) { "SERVFAIL" } else { "NOERROR" }
        $lat = 2 + (($i * 3) % 60)
        $lines.Add("$ts dns node=dns-sensor-01 src=$src qname=$q qtype=$rtype rcode=$rcode latency_ms=$lat")
    }

    $lines.Add("2026-03-08T11:40:10.1100000Z dns node=dns-sensor-01 src=192.168.1.45 qname=update-check.company.com qtype=A rcode=NOERROR latency_ms=6")
    $lines.Add("2026-03-08T11:40:11.0980000Z dns node=dns-sensor-01 src=192.168.1.45 qname=update-check.company.com qtype=A rcode=NOERROR latency_ms=5")
    $lines.Add("2026-03-08T11:40:12.0890000Z dns node=dns-sensor-01 src=192.168.1.45 qname=update-check.company.com qtype=A rcode=NOERROR latency_ms=7")
    $lines.Add("2026-03-08T11:40:13.0810000Z dns node=dns-sensor-01 src=192.168.1.45 qname=update-check.company.com qtype=A rcode=NOERROR latency_ms=6")
    $lines.Add("2026-03-08T11:40:14.0720000Z dns node=dns-sensor-01 src=192.168.1.45 qname=update-check.company.com qtype=A rcode=NOERROR latency_ms=5")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsSummary {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,src_ip,qname,total_queries,unique_rrtypes,avg_interval_ms,beacon_score,node")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $domains = @("api.github.com","packages.ubuntu.com","repo.mysql.com","pypi.org","updates.internal.local")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 4).ToString("o")
        $src = "192.168.1.$(12 + ($i % 80))"
        $q = $domains[$i % $domains.Count]
        $count = 1 + ($i % 8)
        $rr = if (($i % 3) -eq 0) { 2 } else { 1 }
        $interval = 1200 + (($i * 5) % 9500)
        $score = [Math]::Round(0.03 + (($i % 30) / 100.0), 2)
        $lines.Add("$ts,$src,$q,$count,$rr,$interval,$score,dns-sensor-01")
    }

    $lines.Add("2026-03-08T11:40:15Z,192.168.1.45,update-check.company.com,54,1,1000,0.98,dns-sensor-01")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FirewallDnsLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6500; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $src = "192.168.1.$(20 + ($i % 70))"
        $dst = "10.10.0.$(3 + ($i % 3))"
        $action = if (($i % 197) -eq 0) { "ALLOW_WITH_NOTE" } else { "ALLOW" }
        $lines.Add("$ts fw-dns node=fw-01 action=$action src=$src dst=$dst proto=UDP dport=53 policy=dns-outbound")
    }

    $lines.Add("2026-03-08T11:40:10Z fw-dns node=fw-01 action=ALLOW_WITH_NOTE src=192.168.1.45 dst=10.10.0.3 proto=UDP dport=53 policy=dns-outbound note=high_frequency_domain update-check.company.com")
    $lines.Add("2026-03-08T11:40:14Z fw-dns node=fw-01 action=ALLOW_WITH_NOTE src=192.168.1.45 dst=10.10.0.3 proto=UDP dport=53 policy=dns-outbound note=high_frequency_domain update-check.company.com")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HostDnsProcess {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,node,src_ip,process_name,proc_path,pid,dns_domain,query_count,interval_ms")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $procs = @("chrome","python3","systemd-resolved","apt-get","agentd")
    $domains = @("api.github.com","packages.ubuntu.com","repo.mysql.com","pypi.org")

    for ($i = 0; $i -lt 5800; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $proc = $procs[$i % $procs.Count]
        $domain = $domains[$i % $domains.Count]
        $procId = 3000 + ($i % 17000)
        $path = "C:/Program Files/$proc/$proc.exe"
        $count = 1 + ($i % 6)
        $interval = 2000 + (($i * 11) % 8000)
        $lines.Add("$ts,workstation-45,192.168.1.45,$proc,$path,$procId,$domain,$count,$interval")
    }

    $lines.Add("2026-03-08T11:40:10Z,workstation-45,192.168.1.45,svc-update-agent,C:/ProgramData/svc-update-agent/agent.exe,8422,update-check.company.com,54,1000")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("dns_rate_watch","domain_reputation_watch","beacon_pattern_watch","host_profile_drift")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "dns-" + ("{0:D8}" -f (99500000 + $i))
            severity = if (($i % 173) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine dns analytics signal"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T11:40:15Z"
        alert_id = "dns-99977104"
        severity = "critical"
        type = "dns_beaconing_pattern_detected"
        status = "open"
        detail = "host repeatedly queried domain at near-constant 1s intervals"
        suspicious_domain = "update-check.company.com"
        source_host = "192.168.1.45"
    }) | ConvertTo-Json -Compress))
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $evt = if (($i % 239) -eq 0) { "dns_behavior_review" } else { "routine_dns_monitoring" }
        $sev = if ($evt -eq "dns_behavior_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-dns-01,$sev,dns telemetry baseline")
    }

    $lines.Add("2026-03-08T11:40:15Z,dns_beaconing_candidate,siem-dns-01,critical,192.168.1.45 generated repeated queries for update-check.company.com")
    $lines.Add("2026-03-08T11:40:21Z,host_process_correlated,siem-dns-01,high,svc-update-agent tied to update-check.company.com query bursts")
    $lines.Add("2026-03-08T11:40:30Z,incident_opened,siem-dns-01,high,INC-2026-5602 dns beaconing investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
DNS Beaconing Detection Policy (Excerpt)

1) Repeated near-constant interval DNS queries must be investigated.
2) Analysts must extract suspicious domain IOC from beaconing cases.
3) Host-process attribution is required before containment.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
DNS Beaconing Triage Runbook (Excerpt)

1) Review DNS query logs for repetitive timing patterns.
2) Correlate with DNS summary and firewall DNS traffic.
3) Map source host queries to local process telemetry.
4) Report suspicious beaconing domain and isolate host if confirmed.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M6-02 DNS Beaconing (Real-World Investigation Pack)

Scenario:
Network analytics flagged repeated high-frequency DNS lookups from one internal workstation.

Task:
Analyze the investigation pack and identify the suspicious domain.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5602
Severity: High
Queue: SOC + Network Security

Summary:
One workstation generated near-constant interval DNS queries to an unusual domain.

Scope:
- Source host: 192.168.1.45
- Window: 2026-03-08 11:40 UTC
- Goal: identify suspicious beaconing domain
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate DNS query logs, DNS summary analytics, firewall DNS logs, host process DNS activity, security alerts, SIEM timeline, and policy/runbook guidance.
- Determine the suspicious DNS beaconing domain.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-DnsQueryLog -OutputPath (Join-Path $bundleRoot "evidence\network\dns_query.log")
New-DnsSummary -OutputPath (Join-Path $bundleRoot "evidence\network\dns_query_summary.csv")
New-FirewallDnsLog -OutputPath (Join-Path $bundleRoot "evidence\network\firewall_dns_egress.log")
New-HostDnsProcess -OutputPath (Join-Path $bundleRoot "evidence\host\process_dns_activity.csv")
New-DnsAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dns_beacon_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\dns_beaconing_detection_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\dns_beaconing_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
