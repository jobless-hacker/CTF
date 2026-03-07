param()

$ErrorActionPreference = "Stop"

$bundleName = "m9-05-website-archive"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m9_05_realworld_build"
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

function New-WaybackIndex {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source_url,http_status,mime_type,archive_sha1,redirect_target")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $hosts = @("www.company.com","careers.company.com","status.company.com","blog.company.com")

    for ($i = 0; $i -lt 6900; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $hostName = $hosts[$i % $hosts.Count]
        $url = "https://$hostName/page-" + ("{0:D4}" -f ($i % 500)) + ".html"
        $code = if (($i % 57) -eq 0) { "301" } else { "200" }
        $sha = ("{0:x40}" -f ($i + 4096))
        $redir = if ($code -eq "301") { "https://www.company.com/home" } else { "" }
        $lines.Add("$ts,$url,$code,text/html,$sha,$redir")
    }

    $lines.Add("2026-03-06T23:11:19Z,https://oldportal.company.net/login,200,text/html,7c7f8a8ad673f5b48de5cbf85715ca7c9b68e66f,")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ArchiveCrawlerLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $paths = @("/","/home","/about","/contact","/products","/docs","/support")

    for ($i = 0; $i -lt 7300; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $hostName = "www.company.com"
        $path = $paths[$i % $paths.Count]
        $status = if (($i % 131) -eq 0) { "302" } else { "200" }
        $lines.Add("$ts crawler host=$hostName path=$path status=$status bytes=" + (900 + ($i % 5000)))
    }

    $lines.Add("2026-03-06T23:11:23Z crawler host=oldportal.company.net path=/login status=200 bytes=4821 note=legacy_portal_detected")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-HistoricalDnsJsonl {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5600; $i++) {
        $entry = [ordered]@{
            observed_at_utc = $base.AddSeconds($i * 8).ToString("o")
            fqdn = "host-" + ("{0:D5}" -f (22000 + $i)) + ".company.com"
            rrtype = "A"
            value = "203.0.113." + (($i % 200) + 10)
            source = "passive-dns-feed-b"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        observed_at_utc = "2026-03-06T23:11:25Z"
        fqdn = "oldportal.company.net"
        rrtype = "A"
        value = "198.51.100.143"
        source = "passive-dns-feed-b"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CtLogExtract {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("logged_at_utc,common_name,issuer,not_before,not_after,serial")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)
    $issuers = @("Let's Encrypt","DigiCert","ZeroSSL","Sectigo")

    for ($i = 0; $i -lt 4800; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("o")
        $cn = "svc-" + ("{0:D4}" -f ($i % 1700)) + ".company.com"
        $issuer = $issuers[$i % $issuers.Count]
        $nb = "2025-" + ("{0:D2}" -f (($i % 12) + 1)) + "-01T00:00:00Z"
        $na = "2026-" + ("{0:D2}" -f (($i % 12) + 1)) + "-01T00:00:00Z"
        $serial = ("{0:X}" -f (400000 + $i))
        $lines.Add("$ts,$cn,$issuer,$nb,$na,$serial")
    }

    $lines.Add("2026-03-06T23:11:28Z,oldportal.company.net,Let's Encrypt,2025-11-01T00:00:00Z,2026-02-01T00:00:00Z,7AC102F")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TimelineEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 233) -eq 0) { "archive-quality-check" } else { "archive-enrichment-heartbeat" }
        $sev = if ($evt -eq "archive-quality-check") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,osint-archive-siem-01,$sev,website archive enrichment heartbeat")
    }

    $lines.Add("2026-03-06T23:11:31Z,legacy_portal_confirmed,osint-archive-siem-01,high,old portal domain identified as oldportal.company.net")
    $lines.Add("2026-03-06T23:11:37Z,ctf_answer_ready,osint-archive-siem-01,high,submit oldportal.company.net")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ArchiveTxt {
    param([string]$OutputPath)

    $content = @'
Old version of company site archived at:

oldportal.company.net
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-CaseNotes {
    param([string]$OutputPath)

    $content = @'
OSINT Case Notes (Extract)

Objective:
Identify the old portal domain from archived web infrastructure evidence.

Validation rule:
Correlate crawler, passive DNS, and CT log evidence before finalizing.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-IntelSnapshot {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Historical infra pivot from archive intelligence:
oldportal.company.net
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M9-05 Website Archive (Real-World Investigation Pack)

Scenario:
Archive intelligence indicates a legacy web portal may still be discoverable in historical datasets.

Task:
Analyze the evidence pack and identify the old portal domain.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5905
Severity: Medium
Queue: SOC OSINT

Summary:
Identify legacy portal domain from archived website intelligence.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate wayback index records, archive crawler logs, passive DNS data,
  certificate transparency extracts, SIEM timeline, and intel notes.
- Identify the old portal domain.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-ArchiveTxt -OutputPath (Join-Path $bundleRoot "evidence\archive.txt")
New-WaybackIndex -OutputPath (Join-Path $bundleRoot "evidence\osint\wayback_index.csv")
New-ArchiveCrawlerLog -OutputPath (Join-Path $bundleRoot "evidence\osint\archive_crawler.log")
New-HistoricalDnsJsonl -OutputPath (Join-Path $bundleRoot "evidence\osint\historical_dns.jsonl")
New-CtLogExtract -OutputPath (Join-Path $bundleRoot "evidence\osint\ct_log_extract.csv")
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
