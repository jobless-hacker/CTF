param()

$ErrorActionPreference = "Stop"

$bundleName = "m9-09-subdomain-discovery"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m9_09_realworld_build"
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

function New-SubdomainInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("snapshot_time_utc,subdomain,record_type,value,source,classification")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $prefixes = @("api","mail","cdn","status","portal","auth","assets","news")

    for ($i = 0; $i -lt 6800; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $name = $prefixes[$i % $prefixes.Count] + "-" + ("{0:D4}" -f ($i % 2200)) + ".company.com"
        $rtype = if (($i % 3) -eq 0) { "A" } elseif (($i % 3) -eq 1) { "CNAME" } else { "AAAA" }
        $val = if ($rtype -eq "A") { "203.0.113." + (($i % 180) + 10) } elseif ($rtype -eq "AAAA") { "2001:db8::" + ($i % 1024) } else { "edge-" + ($i % 500) + ".cloud.example.net" }
        $cls = if (($i % 211) -eq 0) { "review" } else { "known" }
        $lines.Add("$ts,$name,$rtype,$val,inventory-sync,$cls")
    }

    $lines.Add("2026-03-07T23:27:11Z,dev.company.com,A,198.51.100.77,inventory-sync,review")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsBruteforceLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $words = @("test","beta","stage","alpha","img","files","chat","pay","id","secure")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $candidate = $words[$i % $words.Count] + ("{0:D3}" -f ($i % 500)) + ".company.com"
        $result = if (($i % 61) -eq 0) { "NXDOMAIN" } else { "NOERROR" }
        $lines.Add("$ts dns_bruteforce candidate=$candidate result=$result resolver=8.8.8.8")
    }

    $lines.Add("2026-03-07T23:27:15Z dns_bruteforce candidate=dev.company.com result=NOERROR resolver=1.1.1.1 note=interesting_subdomain")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-PassiveDnsJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            observed_at_utc = $base.AddSeconds($i * 8).ToString("o")
            fqdn = "svc-" + ("{0:D5}" -f (40000 + $i)) + ".company.com"
            rrtype = "A"
            value = "198.51.100." + (($i % 200) + 10)
            source = "pdns-feed-01"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        observed_at_utc = "2026-03-07T23:27:18Z"
        fqdn = "dev.company.com"
        rrtype = "A"
        value = "198.51.100.77"
        source = "pdns-feed-01"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CertificateSanExtract {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("logged_at_utc,cert_id,common_name,san_count,san_preview,issuer")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $issuers = @("Let's Encrypt","ZeroSSL","DigiCert","Sectigo")

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $cert = "CERT-" + ("{0:D8}" -f (10000000 + $i))
        $cn = "www" + ($i % 900) + ".company.com"
        $count = 2 + ($i % 8)
        $preview = "www.company.com|api.company.com"
        $issuer = $issuers[$i % $issuers.Count]
        $lines.Add("$ts,$cert,$cn,$count,$preview,$issuer")
    }

    $lines.Add("2026-03-07T23:27:21Z,CERT-99990001,company.com,5,www.company.com|api.company.com|dev.company.com,Let's Encrypt")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ResolverQueryLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $qname = "host-" + ("{0:D5}" -f (50000 + $i)) + ".company.com"
        $rcode = if (($i % 63) -eq 0) { "NXDOMAIN" } else { "NOERROR" }
        $client = "10.20." + (($i % 40) + 1) + "." + (($i % 200) + 10)
        $lines.Add("$ts resolver_query client=$client qname=$qname qtype=A rcode=$rcode")
    }

    $lines.Add("2026-03-07T23:27:23Z resolver_query client=10.20.14.22 qname=dev.company.com qtype=A rcode=NOERROR answer=198.51.100.77")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 229) -eq 0) { "subdomain-quality-check" } else { "dns-osint-heartbeat" }
        $sev = if ($evt -eq "subdomain-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,osint-dns-siem-01,$sev,dns discovery enrichment heartbeat")
    }

    $lines.Add("2026-03-07T23:27:27Z,development_subdomain_confirmed,osint-dns-siem-01,high,development subdomain identified as dev.company.com")
    $lines.Add("2026-03-07T23:27:33Z,ctf_answer_ready,osint-dns-siem-01,high,submit dev.company.com")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DnsRecordsTxt {
    param([string]$OutputPath)

    $content = @'
www.company.com
mail.company.com
dev.company.com
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
OSINT Case Notes (Extract)

Objective:
Identify development subdomain from DNS discovery artifacts.

Validation rule:
Correlate brute-force discovery, passive DNS, and certificate SAN evidence.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Infrastructure expansion includes a development endpoint.
Confirmed dev subdomain: dev.company.com
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M9-09 Subdomain Discovery (Real-World Investigation Pack)

Scenario:
DNS intelligence collection was performed to map exposed service subdomains.

Task:
Analyze the evidence pack and identify the development subdomain.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5909
Severity: Medium
Queue: SOC OSINT

Summary:
Identify development subdomain from DNS and certificate intelligence.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate subdomain inventory, brute-force logs, passive DNS records,
  certificate SAN extracts, resolver queries, SIEM timeline, and intel notes.
- Identify development subdomain.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-DnsRecordsTxt -OutputPath (Join-Path $bundleRoot "evidence\dns_records.txt")
New-SubdomainInventory -OutputPath (Join-Path $bundleRoot "evidence\osint\subdomain_inventory.csv")
New-DnsBruteforceLog -OutputPath (Join-Path $bundleRoot "evidence\osint\dns_bruteforce.log")
New-PassiveDnsJsonl -OutputPath (Join-Path $bundleRoot "evidence\osint\passive_dns.jsonl")
New-CertificateSanExtract -OutputPath (Join-Path $bundleRoot "evidence\osint\certificate_san_extract.csv")
New-ResolverQueryLog -OutputPath (Join-Path $bundleRoot "evidence\osint\resolver_query.log")
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
