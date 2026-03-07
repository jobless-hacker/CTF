param(
    [string[]]$BundleName = @()
)

$ErrorActionPreference = "Stop"

$artifactRoot = Join-Path $PSScriptRoot "..\\artifacts\\m6"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$buildRoot = Join-Path $env:TEMP "m6_artifacts_build"

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
        bundle = "m6-01-suspicious-connection"
        title = "M6-01 - Suspicious Connection"
        difficulty = "Easy"
        scenario = "An internal workstation appears to be repeatedly communicating with an unknown external endpoint."
        task = "Identify the suspicious external IP."
        evidence_name = "traffic.pcap"
        evidence_content = @"
No. Time       Source         Destination    Protocol Info
1   11.002311  192.168.1.25   203.0.113.77   TCP      51322 -> 443 [SYN]
2   12.018554  192.168.1.25   203.0.113.77   TCP      51324 -> 443 [SYN]
3   13.039781  192.168.1.25   203.0.113.77   TCP      51331 -> 443 [SYN]
"@
    },
    @{
        bundle = "m6-02-dns-beaconing"
        title = "M6-02 - DNS Beaconing"
        difficulty = "Easy"
        scenario = "DNS logs show frequent repeated queries from a single workstation."
        task = "Identify the suspicious domain."
        evidence_name = "dns.log"
        evidence_content = @"
2026-07-10T10:02:11Z host=WS-14 query=update-check.company.com type=A
2026-07-10T10:03:11Z host=WS-14 query=update-check.company.com type=A
2026-07-10T10:04:11Z host=WS-14 query=update-check.company.com type=A
2026-07-10T10:05:11Z host=WS-14 query=update-check.company.com type=A
2026-07-10T10:06:11Z host=WS-14 query=update-check.company.com type=A
"@
    },
    @{
        bundle = "m6-03-plaintext-credentials"
        title = "M6-03 - Plaintext Credentials"
        difficulty = "Easy"
        scenario = "A packet capture includes an HTTP login request over plaintext transport."
        task = "Identify the leaked username."
        evidence_name = "http_capture.pcap"
        evidence_content = @"
POST /login HTTP/1.1
Host: intranet.local
User-Agent: curl/8.1

username=john
password=secret123
"@
    },
    @{
        bundle = "m6-04-port-scan"
        title = "M6-04 - Port Scan"
        difficulty = "Easy"
        scenario = "Firewall telemetry shows sequential connection attempts to many ports."
        task = "Identify the scanning IP."
        evidence_name = "firewall.log"
        evidence_content = @"
connection attempt from 185.199.110.42 to ports:
22
80
443
8080
3306
3389
"@
    },
    @{
        bundle = "m6-05-malware-download"
        title = "M6-05 - Malware Download"
        difficulty = "Easy"
        scenario = "Proxy logs contain an executable download from a malicious host."
        task = "Identify the malicious file."
        evidence_name = "proxy.log"
        evidence_content = @"
2026-07-10T12:17:33Z user=hr-pc GET http://malicious-domain.ru/trojan.exe status=200
"@
    },
    @{
        bundle = "m6-06-c2-communication"
        title = "M6-06 - C2 Communication"
        difficulty = "Medium"
        scenario = "Threat hunting data shows regular heartbeat traffic from an infected host."
        task = "Identify the command-and-control server."
        evidence_name = "traffic.pcap"
        evidence_content = @"
2026-07-10T13:01:00Z infected_host -> 198.51.100.44 TCP 443 heartbeat
2026-07-10T13:02:00Z infected_host -> 198.51.100.44 TCP 443 heartbeat
2026-07-10T13:03:00Z infected_host -> 198.51.100.44 TCP 443 heartbeat
"@
    },
    @{
        bundle = "m6-07-suspicious-dns-query"
        title = "M6-07 - Suspicious DNS Query"
        difficulty = "Medium"
        scenario = "DNS capture includes a query pattern consistent with data exfiltration naming."
        task = "Identify the exfiltration domain."
        evidence_name = "dns_capture.pcap"
        evidence_content = @"
Frame 2012: query type A data.exfiltration.evil.com
"@
    },
    @{
        bundle = "m6-08-data-exfiltration"
        title = "M6-08 - Data Exfiltration"
        difficulty = "Medium"
        scenario = "NetFlow records indicate large outbound traffic from a workstation."
        task = "Identify the external data destination."
        evidence_name = "netflow.log"
        evidence_content = @"
src=192.168.1.45 dst=203.0.113.200 proto=tcp dport=443 bytes=80000000
"@
    },
    @{
        bundle = "m6-09-infected-host"
        title = "M6-09 - Infected Host"
        difficulty = "Medium"
        scenario = "ARP monitoring detected suspicious behavior tied to one internal host."
        task = "Identify the compromised device."
        evidence_name = "arp.log"
        evidence_content = @"
192.168.1.10
192.168.1.25
192.168.1.45
192.168.1.90 suspicious activity detected
"@
    },
    @{
        bundle = "m6-10-lateral-movement"
        title = "M6-10 - Lateral Movement"
        difficulty = "Medium"
        scenario = "SMB traffic inspection indicates movement from one compromised endpoint to another."
        task = "Identify the attacked internal host."
        evidence_name = "smb_traffic.pcap"
        evidence_content = @"
192.168.1.90 -> 192.168.1.12 SMB login attempt
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

Write-Host "M6 artifact bundles generated in $artifactRoot"
