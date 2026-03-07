param()

$ErrorActionPreference = "Stop"

$bundleName = "m9-03-domain-investigation"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m9_03_realworld_build"
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

function New-DomainInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("snapshot_time_utc,domain,tld,registrar,created_utc,expiry_utc,risk_score,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T00:00:00", [DateTimeKind]::Utc)
    $registrars = @("GoDaddy","Name.com","Porkbun","Cloudflare Registrar","Dynadot","Hostinger")
    $tlds = @("com","net","org","io","biz")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $domain = "track-" + ("{0:D5}" -f (20000 + $i)) + "." + $tlds[$i % $tlds.Count]
        $tld = $domain.Split(".")[-1]
        $registrar = $registrars[$i % $registrars.Count]
        $created = "2024-" + ("{0:D2}" -f (($i % 12) + 1)) + "-15T10:00:00Z"
        $expiry = "2027-" + ("{0:D2}" -f (($i % 12) + 1)) + "-15T10:00:00Z"
        $risk = [math]::Round((($i % 85) / 100), 2)
        $status = if (($i % 211) -eq 0) { "watchlist" } else { "active" }
        $lines.Add("$ts,$domain,$tld,$registrar,$created,$expiry,$risk,$status")
    }

    $lines.Add("2026-03-06T22:07:32Z,suspicious-site.com,com,NameCheap,2024-01-08T04:20:11Z,2027-01-08T04:20:11Z,0.99,watchlist")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WhoisBatchLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $registrars = @("GoDaddy.com, LLC","Name.com, Inc.","Porkbun LLC","Dynadot LLC","Cloudflare, Inc.")

    for ($i = 0; $i -lt 7200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $domain = "probe-" + ("{0:D5}" -f (30000 + $i)) + ".com"
        $registrar = $registrars[$i % $registrars.Count]
        $lines.Add("$ts whois_lookup domain=$domain registrar=`"$registrar`" status=ok")
    }

    $lines.Add("2026-03-06T22:07:40Z whois_lookup domain=suspicious-site.com registrar=`"NameCheap Inc.`" status=ok note=priority_domain")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-RdapResponses {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 7).ToString("o")
            ldhName = "probe-" + ("{0:D5}" -f (40000 + $i)) + ".net"
            registrarName = "Registrar-" + ("{0:D3}" -f ($i % 400))
            status = @("client transfer prohibited")
            risk = if (($i % 173) -eq 0) { "medium" } else { "low" }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-06T22:07:42Z"
        ldhName = "suspicious-site.com"
        registrarName = "NameCheap"
        status = @("ok", "client transfer prohibited")
        risk = "high"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PassiveDns {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            observed_at_utc = $base.AddSeconds($i * 8).ToString("o")
            domain = "probe-" + ("{0:D5}" -f (50000 + $i)) + ".org"
            rrtype = "A"
            value = "203.0.113." + (($i % 200) + 20)
            source = "passive-dns-feed-a"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        observed_at_utc = "2026-03-06T22:07:45Z"
        domain = "suspicious-site.com"
        rrtype = "A"
        value = "198.51.100.200"
        source = "passive-dns-feed-a"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 227) -eq 0) { "domain-quality-check" } else { "whois-enrichment-heartbeat" }
        $sev = if ($evt -eq "domain-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,osint-domain-siem-01,$sev,domain enrichment pipeline heartbeat")
    }

    $lines.Add("2026-03-06T22:07:48Z,registrar_confirmed,osint-domain-siem-01,high,suspicious-site.com registrar resolved as NameCheap")
    $lines.Add("2026-03-06T22:07:54Z,ctf_answer_ready,osint-domain-siem-01,high,submit registrar NameCheap")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WhoisTxt {
    param([string]$OutputPath)

    $content = @'
Domain Name: suspicious-site.com
Registrar: NameCheap Inc.
Creation Date: 2024-01-08
Updated Date: 2026-03-06
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
OSINT Case Notes (Extract)

Goal:
Identify registrar for priority domain suspicious-site.com.

Validation rule:
Do not rely on one source. Confirm through WHOIS + RDAP + SIEM normalization.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Priority monitored domain: suspicious-site.com
Latest enrichment consensus registrar: NameCheap
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M9-03 Domain Investigation (Real-World Investigation Pack)

Scenario:
A suspicious domain was flagged by OSINT enrichment and needs registrar attribution.

Task:
Analyze the evidence pack and identify the registrar for the flagged domain.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5903
Severity: Medium
Queue: SOC OSINT

Summary:
Registrar attribution required for suspicious domain suspicious-site.com.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate domain inventory export, whois batch logs, RDAP responses,
  passive DNS context, SIEM timeline, and intel notes.
- Determine registrar for suspicious-site.com.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-WhoisTxt -OutputPath (Join-Path $bundleRoot "evidence\whois.txt")
New-DomainInventory -OutputPath (Join-Path $bundleRoot "evidence\osint\domain_inventory.csv")
New-WhoisBatchLog -OutputPath (Join-Path $bundleRoot "evidence\osint\whois_batch.log")
New-RdapResponses -OutputPath (Join-Path $bundleRoot "evidence\osint\rdap_responses.jsonl")
New-PassiveDns -OutputPath (Join-Path $bundleRoot "evidence\osint\passive_dns.jsonl")
New-TimelineEvents -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-CaseNotes -OutputPath (Join-Path $bundleRoot "evidence\osint\case_notes.txt")
New-IntelSnapshot -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
