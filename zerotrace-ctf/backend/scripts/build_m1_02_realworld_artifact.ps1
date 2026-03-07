param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-02-sniffed-credentials"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_02_realworld_build"
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

function New-M1SniffedCredsPcap {
    param([string]$OutputPath)

    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        $python = Get-Command py -ErrorAction SilentlyContinue
    }
    if (-not $python) {
        throw "Python is required to generate capture.pcap"
    }

    $pythonScript = @'
import pathlib
import socket
import struct
import sys

output = pathlib.Path(sys.argv[1])

base_ts = 1772740440

def mac_for_ip(ip):
    o = [int(x) for x in ip.split(".")]
    return bytes([0x02, 0x42, o[1] & 0xff, o[2] & 0xff, o[3] & 0xff, (o[0] ^ o[3]) & 0xff])

def frame(src_ip, dst_ip, src_port, dst_port, seq, ack, payload, flags=0x018):
    src_mac = mac_for_ip(src_ip)
    dst_mac = mac_for_ip(dst_ip)
    eth_type = struct.pack("!H", 0x0800)

    ip_header = struct.pack(
        "!BBHHHBBH4s4s",
        0x45,
        0,
        20 + 20 + len(payload),
        0x1234,
        0,
        64,
        6,
        0,
        socket.inet_aton(src_ip),
        socket.inet_aton(dst_ip),
    )

    tcp_header = struct.pack(
        "!HHLLHHHH",
        src_port,
        dst_port,
        seq,
        ack,
        (5 << 12) | flags,
        4096,
        0,
        0,
    )

    return dst_mac + src_mac + eth_type + ip_header + tcp_header + payload

packets = []

def add_exchange(ts_offset, client_ip, server_ip, client_port, server_port, request_bytes, response_bytes):
    seq_client = 1000 + (client_port % 2048)
    seq_server = 7000 + (client_port % 1024)
    packets.append((base_ts + ts_offset, frame(client_ip, server_ip, client_port, server_port, seq_client, seq_server, request_bytes)))
    packets.append((base_ts + ts_offset + 0.05, frame(server_ip, client_ip, server_port, client_port, seq_server, seq_client + len(request_bytes), response_bytes)))

# Noisy internal HTTP traffic
internal_clients = ["10.50.23.11", "10.50.23.12", "10.50.23.15", "10.50.23.17", "10.50.23.19", "10.50.23.27"]
for i in range(65):
    client = internal_clients[i % len(internal_clients)]
    request = (
        f"GET /static/app.bundle.js?v={i%12} HTTP/1.1\r\n"
        f"Host: intranet.local\r\n"
        f"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)\r\n"
        f"Accept: */*\r\n\r\n"
    ).encode()
    response = (
        "HTTP/1.1 200 OK\r\n"
        "Server: nginx\r\n"
        "Content-Type: application/javascript\r\n"
        "Content-Length: 2048\r\n\r\n"
        "/* js */"
    ).encode()
    add_exchange(i * 0.8, client, "10.50.10.45", 42000 + i, 80, request, response)

# False-positive web scan traffic
for i in range(6):
    request = (
        "GET /wp-login.php HTTP/1.1\r\n"
        "Host: portal.intranet.local\r\n"
        "User-Agent: Mozilla/5.0 zgrab/0.x\r\n"
        "Accept: */*\r\n\r\n"
    ).encode()
    response = (
        "HTTP/1.1 403 Forbidden\r\n"
        "Server: nginx\r\n"
        "Content-Type: text/html\r\n"
        "Content-Length: 112\r\n\r\n"
        "<html>forbidden</html>"
    ).encode()
    add_exchange(90 + i * 0.6, "198.51.100.77", "10.50.10.45", 51010 + i, 80, request, response)

# Credential leak exchange (target evidence)
leak_request = (
    "POST /auth/login HTTP/1.1\r\n"
    "Host: portal.intranet.local\r\n"
    "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)\r\n"
    "Authorization: Basic Y2xpbmljb3BzOlB1bHNlQDIwMjY=\r\n"
    "Content-Type: application/x-www-form-urlencoded\r\n"
    "Content-Length: 41\r\n\r\n"
    "username=clinicops&password=Pulse@2026"
).encode()
leak_response = (
    "HTTP/1.1 302 Found\r\n"
    "Server: nginx\r\n"
    "Location: /dashboard\r\n"
    "Set-Cookie: session=9a1b2c3d; Path=/; HttpOnly\r\n"
    "Content-Length: 0\r\n\r\n"
).encode()
add_exchange(120.0, "10.50.23.19", "10.50.10.45", 51234, 80, leak_request, leak_response)

# Extra benign traffic after compromise window
for i in range(40):
    request = (
        f"GET /api/notifications?offset={i*5} HTTP/1.1\r\n"
        "Host: portal.intranet.local\r\n"
        "User-Agent: Mozilla/5.0\r\n"
        "Accept: application/json\r\n\r\n"
    ).encode()
    response = (
        "HTTP/1.1 200 OK\r\n"
        "Server: nginx\r\n"
        "Content-Type: application/json\r\n"
        "Content-Length: 128\r\n\r\n"
        "{\"ok\":true}"
    ).encode()
    add_exchange(130 + i * 0.7, "10.50.23.12", "10.50.10.45", 53000 + i, 80, request, response)

# Sort packets by timestamp
packets.sort(key=lambda x: x[0])

pcap = bytearray(struct.pack("<IHHIIII", 0xA1B2C3D4, 2, 4, 0, 0, 65535, 1))
for ts, pkt in packets:
    sec = int(ts)
    usec = int((ts - sec) * 1_000_000)
    pcap.extend(struct.pack("<IIII", sec, usec, len(pkt), len(pkt)))
    pcap.extend(pkt)

output.parent.mkdir(parents=True, exist_ok=True)
output.write_bytes(bytes(pcap))
'@

    $scriptPath = Join-Path $buildRoot "build_m1_02_pcap.py"
    Write-TextFile -Path $scriptPath -Content $pythonScript

    if ($python.Name -eq "py.exe") {
        & $python.Source -3 $scriptPath $OutputPath
    } else {
        & $python.Source $scriptPath $OutputPath
    }
}

function New-ZeekConnLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("#separator \x09")
    $lines.Add("#set_separator  ,")
    $lines.Add("#empty_field    (empty)")
    $lines.Add("#unset_field    -")
    $lines.Add("#path   conn")
    $lines.Add("#open   2026-03-06-09-00-00")
    $lines.Add("#fields ts uid id.orig_h id.orig_p id.resp_h id.resp_p proto service duration orig_bytes resp_bytes conn_state local_orig local_resp missed_bytes history orig_pkts orig_ip_bytes resp_pkts resp_ip_bytes tunnel_parents ip_proto")
    $lines.Add("#types time string addr port addr port enum string interval count count string bool bool count string count count count count set[string] count")

    $clients = @("10.50.23.11","10.50.23.12","10.50.23.15","10.50.23.17","10.50.23.19","10.50.23.27")
    $targets = @("10.50.10.45","10.50.10.47","52.95.110.19","142.250.67.14","104.16.132.229")
    $baseTs = 1772740000.0

    for ($i = 0; $i -lt 5200; $i++) {
        $ts = "{0:N6}" -f ($baseTs + ($i * 0.13))
        $uid = "C{0:D7}" -f (1000000 + $i)
        $src = $clients[$i % $clients.Count]
        $dst = $targets[$i % $targets.Count]
        $dstPort = if (($i % 5) -eq 0) { 80 } elseif (($i % 7) -eq 0) { 53 } else { 443 }
        $service = if ($dstPort -eq 80) { "http" } elseif ($dstPort -eq 53) { "dns" } else { "ssl" }
        $proto = if ($dstPort -eq 53) { "udp" } else { "tcp" }
        $ipProto = if ($proto -eq "tcp") { 6 } else { 17 }
        $origBytes = 120 + (($i * 7) % 3000)
        $respBytes = 300 + (($i * 11) % 9000)
        $line = @(
            $ts, $uid, $src, (40000 + ($i % 20000)), $dst, $dstPort, $proto, $service,
            ("{0:N6}" -f (0.09 + (($i % 13) / 100.0))), $origBytes, $respBytes, "SF",
            "T", "F", 0, "ShADadFf", (4 + ($i % 6)), (500 + ($i % 1200)), (3 + ($i % 5)), (700 + ($i % 2500)), "-", $ipProto
        ) -join "`t"
        $lines.Add($line)
    }

    # False-positive scanner conn
    $lines.Add("1772740119.220500`tCZXFALSE1`t198.51.100.77`t51012`t10.50.10.45`t80`ttcp`thttp`t0.028151`t178`t192`tSF`tF`tF`t0`tShADadFf`t4`t430`t4`t522`t-`t6")

    # True suspicious cleartext auth flow
    $lines.Add("1772740122.120110`tCCREDLEAK1`t10.50.23.19`t51234`t10.50.10.45`t80`ttcp`thttp`t0.234511`t612`t430`tSF`tT`tF`t0`tShADadFf`t7`t1004`t6`t822`t-`t6")

    $lines.Add("#close  2026-03-06-09-45-00")
    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

function New-ZeekHttpLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("#separator \x09")
    $lines.Add("#set_separator  ,")
    $lines.Add("#empty_field    (empty)")
    $lines.Add("#unset_field    -")
    $lines.Add("#path   http")
    $lines.Add("#open   2026-03-06-09-00-00")
    $lines.Add("#fields ts uid id.orig_h id.orig_p id.resp_h id.resp_p trans_depth method host uri referrer version user_agent origin request_body_len response_body_len status_code status_msg info_code info_msg tags username password proxied orig_fuids orig_filenames orig_mime_types resp_fuids resp_filenames resp_mime_types")
    $lines.Add("#types time string addr port addr port count string string string string string string string count count count string count string set[enum] string string set[string] vector[string] vector[string] vector[string] vector[string] vector[string] vector[string]")

    $agents = @(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "curl/8.6.0",
        "python-requests/2.32.2"
    )

    for ($i = 0; $i -lt 2600; $i++) {
        $ts = "{0:N6}" -f (1772740000.0 + ($i * 0.19))
        $uid = "H{0:D7}" -f (3000000 + $i)
        $src = if (($i % 9) -eq 0) { "10.50.23.19" } else { "10.50.23.$(11 + ($i % 17))" }
        $ua = $agents[$i % $agents.Count]
        $uri = if (($i % 14) -eq 0) { "/api/notifications?offset=$($i*2)" } else { "/static/app.bundle.js?v=$($i%13)" }
        $mime = if ($uri -like "/api/*") { "application/json" } else { "application/javascript" }
        $line = @(
            $ts, $uid, $src, (43000 + ($i % 20000)), "10.50.10.45", 80, 1, "GET",
            "portal.intranet.local", $uri, "-", "1.1", $ua, "-", 0, (240 + ($i % 8000)),
            200, "OK", "-", "-", "(empty)", "-", "-", "-", "-", "-", "-", ("FRESP{0}" -f $i), "-", $mime
        ) -join "`t"
        $lines.Add($line)
    }

    # False-positive scanner request
    $lines.Add("1772740119.220500`tHZXFALSE1`t198.51.100.77`t51012`t10.50.10.45`t80`t1`tGET`tportal.intranet.local`t/wp-login.php`t-`t1.1`tMozilla/5.0 zgrab/0.x`t-`t0`t112`t403`tForbidden`t-`t-`t(empty)`t-`t-`t-`t-`t-`t-`tFRESP_SCAN`t-`ttext/html")

    # True suspicious credential exposure over cleartext HTTP
    $lines.Add("1772740122.120110`tCCREDLEAK1`t10.50.23.19`t51234`t10.50.10.45`t80`t1`tPOST`tportal.intranet.local`t/auth/login`thttp://portal.intranet.local/login`t1.1`tMozilla/5.0 (Windows NT 10.0; Win64; x64)`t-`t41`t0`t302`tFound`t-`t-`t(empty)`tclinicops`tPulse@2026`t-`t-`t-`t-`tFRESP_CREDLEAK`t-`ttext/html")

    $lines.Add("#close  2026-03-06-09-45-00")
    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

function New-SuricataEveJson {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt 700; $i++) {
        $src = "10.50.23.{0}" -f (11 + ($i % 17))
        $minute = [int](($i / 60) % 60)
        $second = [int]($i % 60)
        $micros = [int](($i * 3137) % 1000000)
        $obj = [ordered]@{
            timestamp = ("2026-03-06T09:{0:D2}:{1:D2}.{2:D6}+0000" -f $minute, $second, $micros)
            flow_id = 900000000000000 + $i
            event_type = "flow"
            src_ip = $src
            src_port = 43000 + ($i % 20000)
            dest_ip = "10.50.10.45"
            dest_port = if (($i % 6) -eq 0) { 80 } else { 443 }
            proto = "TCP"
            app_proto = if (($i % 6) -eq 0) { "http" } else { "tls" }
            flow = [ordered]@{
                pkts_toserver = 4 + ($i % 11)
                pkts_toclient = 3 + ($i % 8)
                bytes_toserver = 280 + (($i * 17) % 9000)
                bytes_toclient = 410 + (($i * 23) % 12000)
                start = "2026-03-06T09:00:00.000000+0000"
            }
        }
        $lines.Add(($obj | ConvertTo-Json -Depth 8 -Compress))
    }

    # False-positive scanner alert
    $fp = [ordered]@{
        timestamp = "2026-03-06T09:11:59.220500+0000"
        flow_id = 944001122334450
        event_type = "alert"
        src_ip = "198.51.100.77"
        src_port = 51012
        dest_ip = "10.50.10.45"
        dest_port = 80
        proto = "TCP"
        app_proto = "http"
        alert = [ordered]@{
            action = "allowed"
            gid = 1
            signature_id = 2018358
            rev = 10
            signature = "ET HUNTING Suspicious Scan on HTTP Login Path"
            category = "Potentially Bad Traffic"
            severity = 2
        }
    }
    $lines.Add(($fp | ConvertTo-Json -Depth 8 -Compress))

    # True cleartext credential alert
    $alert = [ordered]@{
        timestamp = "2026-03-06T09:12:02.120110+0000"
        flow_id = 944001122334455
        event_type = "alert"
        src_ip = "10.50.23.19"
        src_port = 51234
        dest_ip = "10.50.10.45"
        dest_port = 80
        proto = "TCP"
        app_proto = "http"
        alert = [ordered]@{
            action = "allowed"
            gid = 1
            signature_id = 2030010
            rev = 4
            signature = "ET POLICY Cleartext Basic Auth Credentials over HTTP"
            category = "Potential Corporate Privacy Violation"
            severity = 2
        }
        http = [ordered]@{
            hostname = "portal.intranet.local"
            url = "/auth/login"
            http_method = "POST"
            protocol = "HTTP/1.1"
            status = 302
            http_user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        }
    }
    $lines.Add(($alert | ConvertTo-Json -Depth 10 -Compress))

    $httpEvt = [ordered]@{
        timestamp = "2026-03-06T09:12:02.130110+0000"
        flow_id = 944001122334455
        event_type = "http"
        src_ip = "10.50.23.19"
        src_port = 51234
        dest_ip = "10.50.10.45"
        dest_port = 80
        proto = "TCP"
        tx_id = 0
        http = [ordered]@{
            hostname = "portal.intranet.local"
            url = "/auth/login"
            http_method = "POST"
            protocol = "HTTP/1.1"
            status = 302
        }
    }
    $lines.Add(($httpEvt | ConvertTo-Json -Depth 10 -Compress))

    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

function New-ProxyAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = 1772740000.0
    $clients = @("10.50.23.11","10.50.23.12","10.50.23.15","10.50.23.17","10.50.23.19","10.50.23.27")

    for ($i = 0; $i -lt 12000; $i++) {
        $ts = "{0:N3}" -f ($base + ($i * 0.2))
        $client = $clients[$i % $clients.Count]
        $status = if (($i % 11) -eq 0) { "TCP_MISS/304" } else { "TCP_TUNNEL/200" }
        $method = if ($status -eq "TCP_TUNNEL/200") { "CONNECT" } else { "GET" }
        $url = if ($status -eq "TCP_TUNNEL/200") { "api.office365.com:443" } else { "http://intranet.local/static/app.bundle.js" }
        $bytes = 1200 + (($i * 17) % 80000)
        $lines.Add("$ts $(4 + ($i % 120)) $client $status $bytes $method - HIER_DIRECT/$url -")
    }

    # False-positive scanner via direct HTTP probe
    $lines.Add("1772740119.220 29 198.51.100.77 TCP_MISS/403 192 GET http://portal.intranet.local/wp-login.php - HIER_DIRECT/10.50.10.45 text/html")

    # Suspicious cleartext login event
    $lines.Add("1772740122.120 41 10.50.23.19 TCP_MISS/302 430 POST http://portal.intranet.local/auth/login - HIER_DIRECT/10.50.10.45 text/html")

    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-02 Sniffed Credentials (Real-World Investigation Pack)

Scenario:
A SOC team suspects credentials were exposed on an internal segment where HTTPS offload controls were misconfigured.
The case pack includes packet capture, Zeek logs, Suricata EVE telemetry, proxy logs, and analyst handoff context.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4422
Severity: High
Queue: Network Detection & Response

Summary:
NDR generated a policy alert indicating cleartext credential material over HTTP.
Traffic appears mixed with normal intranet activity and noisy scanner probes.

Scope:
- VLAN: corp-user-vlan-20
- Suspected host: WS-23-19 (10.50.23.19)
- App: portal.intranet.local (10.50.10.45)
- Window: 2026-03-06 09:10 UTC - 09:15 UTC

Deliverable:
Identify primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Handoff notes:
- We mirrored the user VLAN span port and exported a trimmed pcap.
- Scanner-like traffic exists in the same 5-minute window; do not treat every alert as compromise.
- Validate with correlated flow identifiers and HTTP transaction context before concluding impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$assetInventory = @'
asset_id,hostname,ip,segment,owner,role
WS-23-11,frontdesk-11,10.50.23.11,corp-user-vlan-20,operations,employee-endpoint
WS-23-12,frontdesk-12,10.50.23.12,corp-user-vlan-20,operations,employee-endpoint
WS-23-15,reception-15,10.50.23.15,corp-user-vlan-20,reception,employee-endpoint
WS-23-17,billing-17,10.50.23.17,corp-user-vlan-20,finance,employee-endpoint
WS-23-19,clinicops-19,10.50.23.19,corp-user-vlan-20,clinical-ops,employee-endpoint
APP-PORTAL-01,portal.intranet.local,10.50.10.45,app-tier-vlan-10,platform,internal-portal
DNS-CORE-01,dns-core-01,10.50.10.47,app-tier-vlan-10,platform,dns-service
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\network\asset_inventory.csv") -Content $assetInventory

$intel = @'
indicator,type,source,first_seen_utc,confidence,comment
198.51.100.77,ip,soc-feed-internal,2026-03-06T08:51:00Z,low,Known scanner that often creates noisy HTTP probes
185.220.101.14,ip,tor-exit-feed,2026-03-04T00:00:00Z,medium,No direct hit in this case pack
portal.intranet.local,domain,cmdb,2024-11-01T00:00:00Z,high,Approved internal business application
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\network\threat_intel_context.csv") -Content $intel

New-ZeekConnLog -OutputPath (Join-Path $bundleRoot "evidence\network\zeek_conn.log")
New-ZeekHttpLog -OutputPath (Join-Path $bundleRoot "evidence\network\zeek_http.log")
New-SuricataEveJson -OutputPath (Join-Path $bundleRoot "evidence\network\suricata_eve.json")
New-ProxyAccessLog -OutputPath (Join-Path $bundleRoot "evidence\network\proxy_access.log")
New-M1SniffedCredsPcap -OutputPath (Join-Path $bundleRoot "evidence\network\capture.pcap")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
