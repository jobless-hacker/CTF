param(
    [string[]]$BundleName = @()
)

$ErrorActionPreference = "Stop"

$artifactRoot = Join-Path $PSScriptRoot "..\\artifacts\\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$buildRoot = Join-Path $env:TEMP "m1_artifacts_build"

function New-BundleDirectory {
    param([string]$Name)

    $bundlePath = Join-Path $buildRoot $Name
    New-Item -ItemType Directory -Force -Path $bundlePath | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $bundlePath "evidence") | Out-Null
    return $bundlePath
}

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

function Publish-Bundle {
    param([string]$BundleName)

    $source = Join-Path $buildRoot $BundleName
    $zipPath = Join-Path $artifactRoot ($BundleName + ".zip")
    if (Test-Path $zipPath) {
        Remove-Item -Force $zipPath
    }
    Compress-Archive -Path (Join-Path $source "*") -DestinationPath $zipPath -Force
}

function Get-PythonCommand {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        return ,@($python.Source)
    }

    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        return ,@($py.Source, "-3")
    }

    throw "Python is required to generate the packet-capture artifact."
}

function New-PcapArtifact {
    param([string]$OutputPath)

    $pythonCommand = Get-PythonCommand
    $script = @'
import pathlib
import socket
import struct
import sys

output = pathlib.Path(sys.argv[1])
payload = (
    b"POST /login HTTP/1.1\r\n"
    b"Host: portal.company.local\r\n"
    b"Content-Type: application/x-www-form-urlencoded\r\n"
    b"Content-Length: 32\r\n\r\n"
    b"username=admin&password=admin123"
)

eth_dst = b"\xaa\xbb\xcc\xdd\xee\xff"
eth_src = b"\x11\x22\x33\x44\x55\x66"
eth_type = struct.pack("!H", 0x0800)

ip_header = struct.pack(
    "!BBHHHBBH4s4s",
    0x45,
    0,
    20 + 20 + len(payload),
    0x1338,
    0,
    64,
    6,
    0,
    socket.inet_aton("10.20.30.15"),
    socket.inet_aton("10.20.30.5"),
)

tcp_header = struct.pack(
    "!HHLLHHHH",
    52444,
    80,
    1,
    1,
    (5 << 12) | 0x018,
    2048,
    0,
    0,
)

frame = eth_dst + eth_src + eth_type + ip_header + tcp_header + payload
pcap_global_header = struct.pack("<IHHIIII", 0xA1B2C3D4, 2, 4, 0, 0, 65535, 1)
packet_header = struct.pack("<IIII", 1760000000, 123456, len(frame), len(frame))

output.write_bytes(pcap_global_header + packet_header + frame)
'@

    $scriptPath = Join-Path $buildRoot "build_m1_capture.py"
    Write-TextFile -Path $scriptPath -Content $script

    $exe = $pythonCommand[0]
    $args = @()
    if ($pythonCommand.Length -gt 1) {
        $args += $pythonCommand[1..($pythonCommand.Length - 1)]
    }
    $args += @($scriptPath, $OutputPath)
    & $exe @args
}

function New-SniffedCredentialsPcap {
    param([string]$OutputPath)

    $pythonCommand = Get-PythonCommand
    $script = @'
import pathlib
import socket
import struct
import sys

output = pathlib.Path(sys.argv[1])

client_ip = "10.20.30.15"
server_ip = "10.20.30.5"
client_port = 52444
server_port = 80

client_mac = b"\x11\x22\x33\x44\x55\x66"
server_mac = b"\xaa\xbb\xcc\xdd\xee\xff"

frames = [
    {
        "src_mac": client_mac,
        "dst_mac": server_mac,
        "src_ip": client_ip,
        "dst_ip": server_ip,
        "src_port": client_port,
        "dst_port": server_port,
        "seq": 1000,
        "ack": 1,
        "flags": 0x018,
        "payload": (
            b"GET /login HTTP/1.1\r\n"
            b"Host: portal.company.local\r\n"
            b"User-Agent: Mozilla/5.0\r\n\r\n"
        ),
    },
    {
        "src_mac": server_mac,
        "dst_mac": client_mac,
        "src_ip": server_ip,
        "dst_ip": client_ip,
        "src_port": server_port,
        "dst_port": client_port,
        "seq": 4000,
        "ack": 1069,
        "flags": 0x018,
        "payload": (
            b"HTTP/1.1 200 OK\r\n"
            b"Server: nginx\r\n"
            b"Content-Type: text/html\r\n\r\n"
            b"<form method=\"post\" action=\"/login\">"
        ),
    },
    {
        "src_mac": client_mac,
        "dst_mac": server_mac,
        "src_ip": client_ip,
        "dst_ip": server_ip,
        "src_port": client_port,
        "dst_port": server_port,
        "seq": 1069,
        "ack": 4078,
        "flags": 0x018,
        "payload": (
            b"POST /login HTTP/1.1\r\n"
            b"Host: portal.company.local\r\n"
            b"Content-Type: application/x-www-form-urlencoded\r\n"
            b"Content-Length: 32\r\n\r\n"
            b"username=admin&password=admin123"
        ),
    },
    {
        "src_mac": server_mac,
        "dst_mac": client_mac,
        "src_ip": server_ip,
        "dst_ip": client_ip,
        "src_port": server_port,
        "dst_port": client_port,
        "seq": 4078,
        "ack": 4207,
        "flags": 0x018,
        "payload": (
            b"HTTP/1.1 302 Found\r\n"
            b"Location: /dashboard\r\n"
            b"Set-Cookie: session=9c2d5b\r\n\r\n"
        ),
    },
]

def build_packet(frame):
    eth_type = struct.pack("!H", 0x0800)
    payload = frame["payload"]
    ip_header = struct.pack(
        "!BBHHHBBH4s4s",
        0x45,
        0,
        20 + 20 + len(payload),
        0x2000,
        0,
        64,
        6,
        0,
        socket.inet_aton(frame["src_ip"]),
        socket.inet_aton(frame["dst_ip"]),
    )
    tcp_header = struct.pack(
        "!HHLLHHHH",
        frame["src_port"],
        frame["dst_port"],
        frame["seq"],
        frame["ack"],
        (5 << 12) | frame["flags"],
        4096,
        0,
        0,
    )
    return frame["dst_mac"] + frame["src_mac"] + eth_type + ip_header + tcp_header + payload

pcap = bytearray(struct.pack("<IHHIIII", 0xA1B2C3D4, 2, 4, 0, 0, 65535, 1))
ts_sec = 1760000100
for index, frame in enumerate(frames):
    packet = build_packet(frame)
    pcap.extend(struct.pack("<IIII", ts_sec + index, 111000 + index, len(packet), len(packet)))
    pcap.extend(packet)

output.write_bytes(bytes(pcap))
'@

    $scriptPath = Join-Path $buildRoot "build_m1_sniffed_credentials.py"
    Write-TextFile -Path $scriptPath -Content $script

    $exe = $pythonCommand[0]
    $args = @()
    if ($pythonCommand.Length -gt 1) {
        $args += $pythonCommand[1..($pythonCommand.Length - 1)]
    }
    $args += @($scriptPath, $OutputPath)
    & $exe @args
}

$bundleDefinitions = @(
    @{
        BundleName = "m1-01-public-bucket-exposure"
        Description = @'
Challenge: Public Bucket Exposure

A cloud storage bucket may be reachable from the internet.
Review the bundled AWS evidence and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0314
Priority: P2
Queue: Cloud Security Monitoring

Summary:
AWS Config forwarded a finding that the S3 bucket customer-data-prod may allow internet read access.

Analyst task:
Validate the exposure, review what type of data is present, and determine which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\aws_cli\\bucket_listing.txt"
                Content = @'
aws s3 ls s3://customer-data-prod/ --summarize

2026-03-01 08:16:22   users_2026_q1.csv
2026-03-01 08:16:28   payments_2026_q1.csv
2026-03-01 08:16:31   addresses_2026_q1.csv

Total Objects: 3
Total Size: 88.2 MiB
'@
            },
            @{
                Path = "evidence\\aws_cli\\bucket_policy.json"
                Content = @'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadFromInternet",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::customer-data-prod/*"
    }
  ]
}
'@
            },
            @{
                Path = "evidence\\logs\\s3_access.log"
                Content = @'
79a1f58d customer-data-prod [06/Mar/2026:08:22:11 +0000] 198.51.100.42 - 4F8A REST.GET.OBJECT payments_2026_q1.csv "GET /customer-data-prod/payments_2026_q1.csv HTTP/1.1" 200 - 52218 52218 41 39 "-" "curl/8.5.0" - - - - - - - -
79a1f58d customer-data-prod [06/Mar/2026:08:22:19 +0000] 198.51.100.42 - 4F8B REST.GET.OBJECT addresses_2026_q1.csv "GET /customer-data-prod/addresses_2026_q1.csv HTTP/1.1" 200 - 44110 44110 38 36 "-" "curl/8.5.0" - - - - - - - -
'@
            }
        )
    },
    @{
        BundleName = "m1-02-sniffed-credentials"
        Description = @'
Challenge: Sniffed Credentials

A network analyst captured suspicious login traffic from an internal network.
Review the case pack, correlate the analyst handoff, asset mapping, and packet capture, then determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0318
Priority: P2
Queue: Network Monitoring

Summary:
An analyst on the corp-user VLAN observed unusual login traffic between a workstation and the internal portal.

Analyst task:
Inspect the capture, identify what was exposed in transit, and determine which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\network\\asset_inventory.txt"
                Content = @'
Asset Inventory Snapshot

10.20.30.15  WS-24               Employee workstation
10.20.30.5   portal.company.local Internal employee portal
'@
            },
            @{
                Path = "evidence\\network\\suricata_alert.json"
                Content = @'
{
  "timestamp": "2026-03-06T09:14:22Z",
  "src_ip": "10.20.30.15",
  "dest_ip": "10.20.30.5",
  "alert": {
    "signature": "Observed authentication request on non-TLS web service",
    "severity": 2
  }
}
'@
            },
            @{
                Path = "evidence\\network\\capture.pcap"
                Kind = "sniffed_credentials_pcap"
            },
            @{
                Path = "evidence\\network\\analyst_notes.txt"
                Content = @'
Handoff Notes:
- Session was captured from a mirrored switch port on VLAN 20.
- Login traffic was observed on the standard web service port rather than the expected secure endpoint.
- The portal is intended for employee self-service access.
'@
            }
        )
    },
    @{
        BundleName = "m1-03-modified-database-record"
        Description = @'
Challenge: Modified Database Record

A finance database record changed after a suspicious incident.
Review the case pack, compare the database snapshots, inspect the audit evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0321
Priority: P1
Queue: Fraud Monitoring

Summary:
The finance team reported an unexpected balance change on account 88314 during overnight reconciliation.

Analyst task:
Review the database evidence, validate whether the data was altered, and determine which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\database\\record_before.txt"
                Content = @'
Forensic source: read-only replica snapshot captured at 2026-03-05 23:59:00 UTC

mysql> SELECT account_id, customer_name, balance, last_updated_by, last_updated_at
    -> FROM customer_wallets
    -> WHERE account_id = 88314;

+------------+---------------+---------+-----------------+---------------------+
| account_id | customer_name | balance | last_updated_by | last_updated_at     |
+------------+---------------+---------+-----------------+---------------------+
| 88314      | Alex M        | 1200.00 | batch_recon     | 2026-03-05 23:58:14 |
+------------+---------------+---------+-----------------+---------------------+
'@
            },
            @{
                Path = "evidence\\database\\record_after.txt"
                Content = @'
mysql> SELECT account_id, customer_name, balance, last_updated_by, last_updated_at
    -> FROM customer_wallets
    -> WHERE account_id = 88314;

+------------+---------------+----------+-----------------+---------------------+
| account_id | customer_name | balance  | last_updated_by | last_updated_at     |
+------------+---------------+----------+-----------------+---------------------+
| 88314      | Alex M        | 90000.00 | web_admin       | 2026-03-06 00:03:19 |
+------------+---------------+----------+-----------------+---------------------+
'@
            },
            @{
                Path = "evidence\\database\\audit_log.csv"
                Content = @'
timestamp,actor,source_ip,action,statement
2026-03-06T00:03:19Z,web_admin,10.44.18.25,UPDATE,"UPDATE customer_wallets SET balance = 90000.00 WHERE account_id = 88314;"
'@
            },
            @{
                Path = "evidence\\database\\reconciliation_alert.txt"
                Content = @'
Fraud Reconciliation Alert

Account: 88314
Expected ledger total: 1200.00
Observed wallet balance: 90000.00
Linked payment transaction: not found
Escalation reason: unexpected value mutation in finance table
'@
            }
        )
    },
    @{
        BundleName = "m1-04-deleted-logs"
        Description = @'
Challenge: Deleted Logs

Authentication logs were truncated after privileged access on a server.
Review the case pack, compare the host and log evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0324
Priority: P1
Queue: Linux Detection Engineering

Summary:
The SOC received an alert involving authentication records on app-server-02 shortly after a root login from an internal admin subnet.

Analyst task:
Review the evidence, determine what happened to the logs, and identify which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\logs\\auth.log"
                Content = @'
Feb 21 02:11:08 app-server-02 sshd[1881]: Accepted password for root from 10.40.8.19 port 51244 ssh2
Feb 21 02:11:12 app-server-02 sudo: root : TTY=pts/0 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/tail -n 50 /var/log/auth.log
Feb 21 02:11:17 app-server-02 sshd[1881]: pam_unix(sshd:session): session opened for user root(uid=0) by (uid=0)
Feb 21 02:11:24 app-server-02 *** log truncated ***
'@
            },
            @{
                Path = "evidence\\logs\\syslog_excerpt.log"
                Content = @'
Feb 21 02:11:24 app-server-02 rsyslogd: file '/var/log/auth.log': truncation detected, output position reset (inode 942018, offset 0)
Feb 21 02:11:25 app-server-02 systemd[1]: Started Session 441 of user root.
'@
            },
            @{
                Path = "evidence\\host\\bash_history_root.txt"
                Content = @'
cd /var/log
tail -n 50 auth.log
cp auth.log /tmp/auth.log.bak
truncate -s 0 auth.log
'@
            },
            @{
                Path = "evidence\\siem\\alert_summary.txt"
                Content = @'
SIEM Alert Summary

Rule: Unexpected Authentication Log Size Change
Host: app-server-02
Reason: auth.log file size dropped from 184 KB to 0 bytes within 2 seconds of privileged shell activity
Recommendation: review related host activity and verify whether security records were altered
'@
            }
        )
    },
    @{
        BundleName = "m1-05-web-server-crash"
        Description = @'
Challenge: Web Server Crash

A web service became unavailable after overload errors.
Review the case pack, correlate the monitoring and host evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0328
Priority: P1
Queue: Web Operations

Summary:
Customers reported that the internal employee portal started returning 503 errors at 09:12 UTC.

Analyst task:
Review the outage evidence, determine what security property was most affected, and classify the incident accordingly.
'@
            },
            @{
                Path = "evidence\\logs\\nginx_error.log"
                Content = @'
2026/03/06 09:11:56 [alert] 1428#1428: 2048 worker_connections are not enough while connecting to upstream, client: 10.20.30.15, server: portal.company.local, request: "GET /login HTTP/1.1", upstream: "http://127.0.0.1:9000/login", host: "portal.company.local"
2026/03/06 09:12:01 [error] 1428#1428: *8842 connect() failed (111: Connection refused) while connecting to upstream, client: 10.20.30.88, server: portal.company.local, request: "GET /dashboard HTTP/1.1", upstream: "http://127.0.0.1:9000/dashboard", host: "portal.company.local"
2026/03/06 09:12:03 [error] 1428#1428: *8844 upstream prematurely closed connection while reading response header from upstream, client: 10.20.30.44, server: portal.company.local, request: "GET /api/profile HTTP/1.1", upstream: "http://127.0.0.1:9000/api/profile", host: "portal.company.local"
'@
            },
            @{
                Path = "evidence\\monitoring\\availability_alert.txt"
                Content = @'
Health Monitor Alert

Service: portal.company.local
Alert: service health threshold breached
Start time: 2026-03-06 09:12:04 UTC
Successful checks (5m): 18%
Failed checks (5m): 82%
HTTP 503 responses (5m): 913
User impact: most requests failing during the alert window
'@
            },
            @{
                Path = "evidence\\monitoring\\request_rate.csv"
                Content = @'
timestamp,requests_per_second,upstream_healthy,http_200,http_503
2026-03-06T09:10:00Z,240,4,238,0
2026-03-06T09:11:00Z,610,4,584,8
2026-03-06T09:12:00Z,1320,1,207,913
2026-03-06T09:13:00Z,1180,0,188,841
'@
            },
            @{
                Path = "evidence\\host\\service_status.txt"
                Content = @'
$ systemctl status portal-api.service

portal-api.service - Portal API service
   Loaded: loaded (/etc/systemd/system/portal-api.service; enabled)
   Active: activating (auto-restart) (Result: exit-code) since Fri 2026-03-06 09:12:02 UTC; 3s ago
  Process: 2241 ExecStart=/usr/bin/python3 /srv/portal/app.py (code=exited, status=1/FAILURE)
 Main PID: 2241 (code=exited, status=1/FAILURE)

Mar 06 09:11:58 web-02 app.py[2241]: worker pool saturated, request queue length exceeded threshold
Mar 06 09:12:01 web-02 systemd[1]: portal-api.service: Main process exited, code=exited, status=1/FAILURE
Mar 06 09:12:02 web-02 systemd[1]: portal-api.service: Failed with result 'exit-code'.
'@
            }
        )
    },
    @{
        BundleName = "m1-06-github-secret-leak"
        Description = @'
Challenge: GitHub Secret Leak

A developer committed sensitive credentials into version control.
Review the case pack, inspect the commit and review evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0331
Priority: P1
Queue: AppSec / Secrets Management

Summary:
The AppSec team received a GitHub Advanced Security alert on a recent pull request in the billing-service repository.

Analyst task:
Review the repository evidence, confirm what was exposed, and determine which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\git\\commit.txt"
                Content = @'
commit 48df8c1a92f08d5f213b8c7f5e6b0aa4c431d901
Author: Rahul Dev <rahul.dev@company.local>
Date:   Thu Mar 06 08:41:09 2026 +0530

    Prepare billing sync configuration for production rollout
'@
            },
            @{
                Path = "evidence\\git\\git_show.patch"
                Content = @'
diff --git a/config/.env.production b/config/.env.production
index d82f19d..ec88473 100644
--- a/config/.env.production
+++ b/config/.env.production
@@ -2,3 +2,5 @@ BILLING_REGION=ap-south-1
 BILLING_BUCKET=invoice-prod-bucket
 BILLING_SYNC_ENABLED=true
+AWS_ACCESS_KEY_ID=AKIAV7P4N3Q8L2M5R6S7
+AWS_SECRET_ACCESS_KEY=saVh4Ck9Lq2mN8pXr6Tu3Yb1Fd7Ze0WqHs5Jn2Ka
'@
            },
            @{
                Path = "evidence\\security\\secret_scanner_alert.json"
                Content = @'
{
  "provider": "github_advanced_security",
  "repository": "company-internal/billing-service",
  "alert_number": 417,
  "secret_type": "cloud credential",
  "location": "config/.env.production:4-5",
  "commit": "48df8c1a92f08d5f213b8c7f5e6b0aa4c431d901",
  "severity": "critical",
  "status": "open"
}
'@
            },
            @{
                Path = "evidence\\security\\pull_request_comment.txt"
                Content = @'
GitHub Pull Request Review
Reviewer: platform-security-bot
Decision: changes requested

Potential credential material detected in newly added configuration lines.
Remove the values from the pull request, rotate the affected secrets, and keep them out of repository history.
Reference: GHAS-SECRET-REVIEW-01
'@
            }
        )
    },
    @{
        BundleName = "m1-07-mis-sent-email"
        Description = @'
Challenge: Mis-sent Email

A support mailbox sent a spreadsheet to an unexpected external recipient.
Review the case pack, inspect the email and DLP evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0335
Priority: P1
Queue: Data Protection Office

Summary:
The mail gateway flagged an outbound spreadsheet from a support mailbox to an external address that closely resembles an internal review alias.

Analyst task:
Review the outbound email evidence, determine what was exposed, and identify which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\mail\\message.eml"
                Content = @'
From: support.ops@company.local
To: records.review@customerdocs.co
Cc: support.manager@company.local
Subject: March review file
Date: Fri, 06 Mar 2026 10:08:17 +0530
Message-ID: <20260306.100817.4421@company.local>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="===============441203=="

--===============441203==
Content-Type: text/plain; charset="utf-8"

Sharing the latest review sheet from yesterday's export.
Please confirm the contact and location columns marked for cleanup before today's import window.

--===============441203==
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; name="march_review.xlsx"
Content-Disposition: attachment; filename="march_review.xlsx"

[binary attachment omitted]
--===============441203==--
'@
            },
            @{
                Path = "evidence\\mail\\attachment_manifest.txt"
                Content = @'
Attachment Manifest

File name: march_review.xlsx
Worksheet count: 2
Columns observed: customer_id, full_name, phone_number, address, city, notes
Estimated row count: 1842
'@
            },
            @{
                Path = "evidence\\security\\dlp_alert.json"
                Content = @'
{
  "timestamp": "2026-03-06T04:39:02Z",
  "sender": "support.ops@company.local",
  "recipient": "records.review@customerdocs.co",
  "policy": "Outbound structured data review",
  "matched_classifiers": [
    "contact_information",
    "postal_address"
  ],
  "severity": "high",
  "policy_mode": "audit_only",
  "final_action": "delivered_notify"
}
'@
            },
            @{
                Path = "evidence\\security\\mail_gateway_log.txt"
                Content = @'
2026-03-06T04:38:57Z smtp-gateway-01 Accepted message id=20260306.100817.4421 from=support.ops@company.local to=records.review@customerdocs.co size=842913
2026-03-06T04:39:02Z smtp-gateway-01 DLP policy match id=20260306.100817.4421 rule="Outbound structured data review" action=notify policy_mode=audit_only
2026-03-06T04:39:04Z smtp-gateway-01 Delivered message id=20260306.100817.4421 recipient=records.review@customerdocs.co disposition=delivered relay=mx.customerdocs.co
'@
            }
        )
    },
    @{
        BundleName = "m1-08-config-file-tampering"
        Description = @'
Challenge: Unexpected Redirect After Reload

A web portal began redirecting users to an unexpected external destination after a configuration reload.
Review the case pack, compare the configuration evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0339
Priority: P1
Queue: Web Platform Security

Summary:
Users reported that the internal portal began redirecting login traffic to an unfamiliar external domain after a routine web-server reload.

Analyst task:
Review the configuration evidence, confirm what changed, and determine which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\config\\server.conf.baseline"
                Content = @'
server_name=portal.company.local
redirect=false
target=
maintenance_mode=false
'@
            },
            @{
                Path = "evidence\\config\\server.conf.current"
                Content = @'
server_name=portal.company.local
redirect=true
target=portal-company-login.com
maintenance_mode=false
'@
            },
            @{
                Path = "evidence\\logs\\nginx_reload.log"
                Content = @'
2026-03-06T10:42:08Z systemd[1]: Reloading nginx.service - A high performance web server and a reverse proxy server.
2026-03-06T10:42:09Z nginx[1550]: configuration file /etc/portal/server.conf test is successful
2026-03-06T10:42:10Z systemd[1]: Reloaded nginx.service - A high performance web server and a reverse proxy server.
'@
            },
            @{
                Path = "evidence\\validation\\curl_response.txt"
                Content = @'
$ curl -I https://portal.company.local/login
HTTP/1.1 302 Found
Server: nginx
Location: https://portal-company-login.com/login
X-Portal-Node: web-02
'@
            },
            @{
                Path = "evidence\\change_control\\config_audit.txt"
                Content = @'
Config Audit Summary

File: /etc/portal/server.conf
Observed change window: 2026-03-06 10:41:54 UTC
Expected approver: none recorded
Baseline comparison: file contents differ from approved template
Linked change ticket: none found
'@
            }
        )
    },
    @{
        BundleName = "m1-09-firewall-ddos-alert"
        Description = @'
Challenge: Firewall DDoS Alert

A firewall reported a large inbound surge before the customer portal began failing health checks.
Review the case pack, correlate the perimeter and service-health evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0342
Priority: P1
Queue: Network Defense

Summary:
The perimeter firewall reported a sudden inbound connection surge against the customer portal, followed by monitoring alerts and elevated user complaints.

Analyst task:
Review the network and service evidence, determine what security property was most impacted, and classify the incident accordingly.
'@
            },
            @{
                Path = "evidence\\firewall\\edge_firewall.log"
                Content = @'
2026-03-06T11:16:01Z edge-fw-01 notice inbound_connections_per_sec=8200 dst_ip=203.0.113.40 dst_port=443
2026-03-06T11:16:12Z edge-fw-01 notice inbound_connections_per_sec=22140 dst_ip=203.0.113.40 dst_port=443
2026-03-06T11:16:18Z edge-fw-01 alert inbound_connections_per_sec=35000 dst_ip=203.0.113.40 dst_port=443 action=rate-limit
2026-03-06T11:16:23Z edge-fw-01 alert traffic_source=multiple_ips country_mix=29 service=customer-portal status=degraded
'@
            },
            @{
                Path = "evidence\\firewall\\top_talkers.csv"
                Content = @'
src_ip,requests_per_sec,country,action
198.51.100.24,1840,NL,rate-limit
203.0.113.91,1762,BR,drop
192.0.2.144,1704,SG,rate-limit
198.51.100.200,933,DE,challenge
203.0.113.77,412,US,allow
'@
            },
            @{
                Path = "evidence\\service\\load_balancer_health.txt"
                Content = @'
Load Balancer Health Summary

VIP: customer-portal-lb
Healthy backends before spike: 6/6
Healthy backends at 11:16 UTC: 1/6
Failed backend health checks (60s): 147
Backend response state: intermittent 503 and timeout from remaining nodes
'@
            },
            @{
                Path = "evidence\\service\\uptime_monitor.txt"
                Content = @'
External Uptime Monitor

11:15 UTC  HTTP 200  412 ms
11:16 UTC  HTTP 503  4.8 s
11:17 UTC  TIMEOUT   10.0 s
11:18 UTC  TIMEOUT   10.0 s
'@
            },
            @{
                Path = "evidence\\network\\netflow_summary.txt"
                Content = @'
NetFlow Summary

Destination: 203.0.113.40:443
Peak new TCP sessions/sec: 34,912
Unique source IPs in 60s window: 5,842
Dominant pattern: short-lived SYN-heavy bursts from distributed sources
'@
            }
        )
    },
    @{
        BundleName = "m1-10-backup-corruption"
        Description = @'
Challenge: Backup Corruption

A recovery restore operation failed during backup validation after primary storage loss.
Review the case pack, inspect the recovery evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0348
Priority: P1
Queue: Disaster Recovery

Summary:
After a production storage failure, the infrastructure team attempted to restore the application database from the overnight backup. The recovery workflow halted during validation and the database has not returned to normal operation.

Analyst task:
Review the backup and restore evidence, determine what security property was primarily impacted, and classify the incident accordingly.
'@
            },
            @{
                Path = "evidence\\backup\\backup_manifest.txt"
                Content = @'
Backup Manifest

Job ID: nightly-db-backup-2026-03-05
Backup file: /backups/prod/customer-db-2026-03-05.tar.gz
Start time: 2026-03-05 23:00:02 UTC
Completion status: success
Recorded size: 18.4 GB
Recorded checksum (sha256): 874b7c2e5f9f0a0e9b31a0e1946737ded3931314db4f4374c6d4cbf6ab0f8e5a
'@
            },
            @{
                Path = "evidence\\restore\\restore_job.log"
                Content = @'
2026-03-06T11:54:10Z restorectl: starting restore for customer-db-2026-03-05.tar.gz
2026-03-06T11:54:18Z restorectl: verifying archive integrity
2026-03-06T11:54:20Z restorectl: archive checksum validation failed
2026-03-06T11:54:20Z restorectl: archive extraction failed: unexpected end of file
2026-03-06T11:54:21Z restorectl: restore aborted
'@
            },
            @{
                Path = "evidence\\restore\\checksum_validation.txt"
                Content = @'
$ sha256sum customer-db-2026-03-05.tar.gz
44b9fa4f8df3964b4888958037f1552cbd1c5c93d6aa6d9cf6e7db5b6f2fdc8a  customer-db-2026-03-05.tar.gz

Expected from manifest:
874b7c2e5f9f0a0e9b31a0e1946737ded3931314db4f4374c6d4cbf6ab0f8e5a
'@
            },
            @{
                Path = "evidence\\operations\\service_status.txt"
                Content = @'
Recovery Dashboard Snapshot

Application: customer-portal-db
Primary storage state: failed
Restore workflow state: halted awaiting valid backup media
Database node state: recovery_pending
Dependent application checks: degraded (database dependency unavailable)
'@
            }
        )
    },
    @{
        BundleName = "m1-11-aws-public-snapshot"
        Description = @'
Challenge: Unexpected Snapshot Sharing

A cloud database snapshot shows an unexpected sharing configuration change.
Review the case pack, inspect the snapshot attributes and cloud audit evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0353
Priority: P1
Queue: Cloud Security

Summary:
The cloud governance team detected that an RDS snapshot tied to production customer data had an unexpected change in its sharing configuration overnight.

Analyst task:
Review the snapshot evidence, confirm the exposure condition, and determine which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\aws\\snapshot_metadata.json"
                Content = @'
{
  "DBSnapshotIdentifier": "customer-db-backup-2026-03-05",
  "DBInstanceIdentifier": "customer-db-prod",
  "Engine": "postgres",
  "AllocatedStorage": 400,
  "SnapshotCreateTime": "2026-03-05T23:18:02Z",
  "Status": "available"
}
'@
            },
            @{
                Path = "evidence\\aws\\snapshot_attributes.json"
                Content = @'
{
  "DBSnapshotIdentifier": "customer-db-backup-2026-03-05",
  "DBSnapshotAttributesResult": {
    "DBSnapshotAttributes": [
      {
        "AttributeName": "restore",
        "AttributeValues": [
          "all"
        ]
      }
    ]
  }
}
'@
            },
            @{
                Path = "evidence\\aws\\approved_sharing_baseline.json"
                Content = @'
{
  "resource": "customer-db-backup-2026-03-05",
  "approved_restore_principals": [],
  "control_note": "Production database snapshots must remain private unless a documented exception is approved."
}
'@
            },
            @{
                Path = "evidence\\aws\\cloudtrail_event.json"
                Content = @'
{
  "eventTime": "2026-03-06T05:14:11Z",
  "eventSource": "rds.amazonaws.com",
  "eventName": "ModifyDBSnapshotAttribute",
  "userIdentity": {
    "type": "IAMUser",
    "userName": "ops-admin"
  },
  "requestParameters": {
    "dBSnapshotIdentifier": "customer-db-backup-2026-03-05",
    "attributeName": "restore",
    "valuesToAdd": [
      "all"
    ]
  }
}
'@
            },
            @{
                Path = "evidence\\security\\governance_alert.txt"
                Content = @'
Cloud Governance Alert

Control: RDS Snapshot Sharing Drift
Resource: customer-db-backup-2026-03-05
Observed condition: snapshot restore attribute changed from approved baseline
Impact note: validate whether restore permissions now extend beyond approved principals
'@
            }
        )
    },
    @{
        BundleName = "m1-12-packet-replay-attack"
        Description = @'
Challenge: Repeated Payment Authorizations

A payment workflow produced multiple successful authorizations for what should have been a single order.
Review the case pack, inspect the transaction and gateway evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0357
Priority: P1
Queue: Payment Fraud Monitoring

Summary:
The payment gateway flagged multiple successful authorizations associated with a single order during a four-second window.

Analyst task:
Review the payment and network evidence, determine what property of the transaction flow was compromised, and classify the incident accordingly.
'@
            },
            @{
                Path = "evidence\\payments\\gateway_events.csv"
                Content = @'
timestamp,order_ref,transaction_id,idempotency_key,card_ref,amount,status,source_ip
2026-03-06T12:15:01Z,ORD-2026-4401,99312,pay-ord-2026-4401,card_81a4,499.00,approved,10.60.4.25
2026-03-06T12:15:03Z,ORD-2026-4401,99312,pay-ord-2026-4401,card_81a4,499.00,approved,10.60.4.25
2026-03-06T12:15:05Z,ORD-2026-4401,99312,pay-ord-2026-4401,card_81a4,499.00,approved,10.60.4.25
'@
            },
            @{
                Path = "evidence\\payments\\transaction_ledger.txt"
                Content = @'
Ledger Extract

Transaction ID: 99312
Original order ref: ORD-2026-4401
Recorded debit events: 3
Expected debit events: 1
Reconciliation status: mismatch
'@
            },
            @{
                Path = "evidence\\payments\\idempotency_control.txt"
                Content = @'
Payment API Control Note

Endpoint: POST /payments/authorize
Control requirement: transaction_id and Idempotency-Key must be unique per authorization attempt.
Expected duplicate handling: repeated keys for the same order must return the original result and must not create additional debit events.
Retention window: 24 hours
'@
            },
            @{
                Path = "evidence\\network\\api_gateway.log"
                Content = @'
2026-03-06T12:15:01Z api-gw-02 POST /payments/authorize order=ORD-2026-4401 txn=99312 idem=pay-ord-2026-4401 status=200 client=10.60.4.25
2026-03-06T12:15:03Z api-gw-02 POST /payments/authorize order=ORD-2026-4401 txn=99312 idem=pay-ord-2026-4401 status=200 client=10.60.4.25
2026-03-06T12:15:05Z api-gw-02 POST /payments/authorize order=ORD-2026-4401 txn=99312 idem=pay-ord-2026-4401 status=200 client=10.60.4.25
'@
            },
            @{
                Path = "evidence\\security\\fraud_alert.txt"
                Content = @'
Fraud Monitoring Alert

Rule: duplicate_authorization_sequence
Order ref: ORD-2026-4401
Observed condition: 3 approved authorizations recorded within 4 seconds for the same payment context
Recommended check: compare gateway approvals with ledger state and idempotency controls
'@
            }
        )
    },
    @{
        BundleName = "m1-13-siem-alert-investigation"
        Description = @'
Challenge: Unusual SIEM Event Sequence

A SIEM alert highlights an unusual change in security-event behavior on a production server.
Review the case pack, correlate the SIEM and host evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0361
Priority: P1
Queue: Security Monitoring

Summary:
The SIEM flagged unusual security-event behavior on server01 after noticing abrupt auth-log changes alongside privileged shell activity.

Analyst task:
Review the detection evidence, confirm what changed in the logging pipeline, and determine which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\siem\\alert.json"
                Content = @'
{
  "timestamp": "2026-03-06T12:41:18Z",
  "rule": "linux_security_log_anomaly",
  "severity": "high",
  "host": "server01",
  "reason": "auth.log size dropped by 100% within 3 seconds of privileged shell activity"
}
'@
            },
            @{
                Path = "evidence\\siem\\timeline.csv"
                Content = @'
timestamp,host,event_type,details
2026-03-06T12:41:09Z,server01,sshd_login,root login from 10.40.8.19
2026-03-06T12:41:11Z,server01,process_start,/usr/bin/tail -n 50 /var/log/auth.log
2026-03-06T12:41:13Z,server01,process_start,/usr/bin/truncate -s 0 /var/log/auth.log
2026-03-06T12:41:18Z,server01,siem_alert,linux_security_log_anomaly
'@
            },
            @{
                Path = "evidence\\host\\auditd_excerpt.log"
                Content = @'
type=SYSCALL msg=audit(1741264871.108:439): arch=c000003e syscall=2 success=yes exit=3 a0=7ffc18d1d490 a1=0 a2=0 items=1 ppid=2210 pid=2231 auid=0 uid=0 gid=0 euid=0 tty=pts0 comm="tail" exe="/usr/bin/tail" key="log_read"
type=PATH msg=audit(1741264871.108:439): item=0 name="/var/log/auth.log" inode=942018 dev=fd:00 mode=0100640 ouid=0 ogid=4 rdev=00:00 nametype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0
type=SYSCALL msg=audit(1741264873.412:441): arch=c000003e syscall=2 success=yes exit=3 a0=7ffc18d1d521 a1=241 a2=1b6 items=1 ppid=2210 pid=2236 auid=0 uid=0 gid=0 euid=0 tty=pts0 comm="truncate" exe="/usr/bin/truncate" key="log_clear"
type=PATH msg=audit(1741264873.412:441): item=0 name="/var/log/auth.log" inode=942018 dev=fd:00 mode=0100640 ouid=0 ogid=4 rdev=00:00 nametype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0
'@
            },
            @{
                Path = "evidence\\analysis\\triage_notes.txt"
                Content = @'
Triage Notes

- Logging service remained online during the alert window.
- No outbound transfer alerts or storage-access anomalies were observed in parallel.
- Focus review on what changed in the local security-record workflow and how that affects trust in those records.
'@
            }
        )
    },
    @{
        BundleName = "m1-14-docker-misconfiguration"
        Description = @'
Challenge: Unexpected Database Reachability

A staging database service became reachable from outside its expected container network.
Review the case pack, inspect the container and host evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0366
Priority: P1
Queue: Platform Security

Summary:
An infrastructure review found that a Dockerized staging database may be reachable beyond the application network segment it was intended to serve.

Analyst task:
Review the deployment and host evidence, confirm the exposure condition, and determine which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\containers\\docker-compose.yml"
                Content = @'
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
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - app_internal
    secrets:
      - mysql_root_password

volumes:
  db_data:

networks:
  app_internal:

secrets:
  mysql_root_password:
    file: ./secrets/mysql_root_password.txt
'@
            },
            @{
                Path = "evidence\\host\\ss_listening.txt"
                Content = @'
$ ss -ltnp
State   Recv-Q  Send-Q   Local Address:Port   Peer Address:Port  Process
LISTEN  0       4096     0.0.0.0:22          0.0.0.0:*          users:(("sshd",pid=811,fd=3))
LISTEN  0       4096     0.0.0.0:3306        0.0.0.0:*          users:(("docker-proxy",pid=2381,fd=4))
LISTEN  0       4096     127.0.0.1:9100      0.0.0.0:*          users:(("node_exporter",pid=904,fd=3))
'@
            },
            @{
                Path = "evidence\\network\\external_scan.txt"
                Content = @'
$ nmap -Pn -p 3306 198.51.100.40

PORT     STATE SERVICE
3306/tcp open  mysql

Service Info: Host: staging-db.company.local
'@
            },
            @{
                Path = "evidence\\operations\\platform_note.txt"
                Content = @'
Platform Note

Deployment design note: staging app and db should communicate over the app_internal bridge network.
Change review note: no approved host-port exception record was attached to this deployment.
'@
            }
        )
    },
    @{
        BundleName = "m1-15-ransomware-lock"
        Description = @'
Challenge: Files Suddenly Unusable

Employees reported that business documents on a workstation suddenly became unreadable and a recovery note appeared.
Review the case pack, inspect the host impact evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0370
Priority: P1
Queue: Incident Response

Summary:
Multiple employees reported that shared documents on workstation WS-22 became unreadable and an unexpected recovery note appeared on the desktop.

Analyst task:
Review the host evidence, determine the primary security property affected, and classify the incident accordingly.
'@
            },
            @{
                Path = "evidence\\host\\ransom_note.txt"
                Content = @'
All your files are encrypted.
Pay 5 BTC to restore access.
Contact: restoredesk247@proton.me
'@
            },
            @{
                Path = "evidence\\host\\directory_listing.txt"
                Content = @'
$ dir C:\\Users\\analyst\\Documents

invoice_q1.xlsx.locked
team_roster.docx.locked
customers_2026.csv.locked
README_RESTORE_FILES.txt
'@
            },
            @{
                Path = "evidence\\host\\recent_file_events.log"
                Content = @'
2026-03-06T13:18:42Z file_rename src=C:\\Users\\analyst\\Documents\\invoice_q1.xlsx dst=C:\\Users\\analyst\\Documents\\invoice_q1.xlsx.locked
2026-03-06T13:18:43Z file_rename src=C:\\Users\\analyst\\Documents\\team_roster.docx dst=C:\\Users\\analyst\\Documents\\team_roster.docx.locked
2026-03-06T13:18:44Z file_rename src=C:\\Users\\analyst\\Documents\\customers_2026.csv dst=C:\\Users\\analyst\\Documents\\customers_2026.csv.locked
2026-03-06T13:18:45Z file_create path=C:\\Users\\analyst\\Documents\\README_RESTORE_FILES.txt
'@
            },
            @{
                Path = "evidence\\host\\restore_attempt.log"
                Content = @'
2026-03-06T13:21:08Z file_open error path=C:\\Users\\analyst\\Documents\\invoice_q1.xlsx.locked message="Access denied"
2026-03-06T13:21:14Z restore-test skipped reason="no valid recovery material available"
2026-03-06T13:21:21Z user_report status="documents cannot be opened"
'@
            },
            @{
                Path = "evidence\\operations\\impact_summary.txt"
                Content = @'
Business Impact Summary

Affected user group: finance and operations
Files sampled from shared workspace: 146
Files opened successfully during validation: 0
Open helpdesk tickets tied to file access issue: 7
Current workflow status: invoice processing and roster updates delayed
'@
            }
        )
    },
    @{
        BundleName = "m1-16-api-data-exposure"
        Description = @'
Challenge: Unexpected API Response Fields

An API response included user fields that were not expected for this client context.
Review the case pack, inspect the request and response evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0374
Priority: P1
Queue: Application Security

Summary:
An internal API security scan reported that a customer-management endpoint is returning response fields that are outside the documented client scope.

Analyst task:
Review the request and response evidence, identify what was leaked, and determine which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\api\\http_request.txt"
                Content = @'
GET /api/v1/users?limit=1 HTTP/1.1
Host: crm-api.company.local
Authorization: Bearer eyJhbGciOi...
Accept: application/json
'@
            },
            @{
                Path = "evidence\\api\\token_scope_context.txt"
                Content = @'
Token Context (decoded summary)

token_subject: web-portal-client
granted_scopes:
- users:read_basic
allowed_response_profile: public_user_profile_v1
restricted_fields_for_scope:
- password_hash
- reset_token
- mfa_secret
'@
            },
            @{
                Path = "evidence\\api\\http_response.json"
                Content = @'
{
  "users": [
    {
      "id": 4401,
      "name": "john",
      "email": "john@example.local",
      "password_hash": "$2b$12$6fA3nQy8mW2kLp9vYx4p8uKJtE1hQ9eWmB7sT3nR5yU1zX2cV4dA6",
      "reset_token": "r3s3t-t0ken-441",
      "role": "customer"
    }
  ]
}
'@
            },
            @{
                Path = "evidence\\api\\endpoint_spec_excerpt.txt"
                Content = @'
Endpoint: GET /api/v1/users

Documented response fields:
- id
- name
- email
- role

Response profile: public_user_profile_v1
Fields outside this profile require an elevated internal scope.
'@
            },
            @{
                Path = "evidence\\security\\api_scan_finding.txt"
                Content = @'
API Security Finding

Rule: response_schema_scope_mismatch
Endpoint: GET /api/v1/users
Observed fields outside allowed profile: password_hash, reset_token
Severity: critical
'@
            }
        )
    },
    @{
        BundleName = "m1-17-unauthorized-git-commit"
        Description = @'
Challenge: Unexpected Verification Logic Change

A repository shows an unplanned change in payment verification behavior after a main-branch update.
Review the case pack, inspect the commit and review-trail evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0378
Priority: P1
Queue: Application Security

Summary:
Engineering reported that payment-verification behavior changed unexpectedly after a main-branch update during the release window.

Analyst task:
Review the repository evidence, determine what was changed, and identify which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\git\\git_log.txt"
                Content = @'
commit 82hfd91bc7eab2d441ca9d11f6e9b00c4a7731ef
Author: Rahul Dev <rahul.dev@company-support.local>
Date:   Fri Mar 06 13:08:19 2026 +0530

    Refactor payment verification checks
'@
            },
            @{
                Path = "evidence\\git\\identity_policy_note.txt"
                Content = @'
Commit Identity Policy

Main branch changes must be merged through reviewed pull requests.
Verified commit identities must map to approved corporate SSO users under company.local.
Any direct token-authenticated update without linked review metadata requires investigation.
'@
            },
            @{
                Path = "evidence\\git\\git_show.patch"
                Content = @'
diff --git a/services/payment_verifier.py b/services/payment_verifier.py
index 4a10f6b..990bc1d 100644
--- a/services/payment_verifier.py
+++ b/services/payment_verifier.py
@@ -18,7 +18,7 @@ def verify_payment(signature_is_valid: bool, amount_matches: bool) -> bool:
     if not signature_is_valid:
         return False
 
-    if not amount_matches:
-        return False
+    if not amount_matches:
+        return True
 
     return True
'@
            },
            @{
                Path = "evidence\\git\\branch_protection_note.txt"
                Content = @'
Branch Protection Note

Protected branch: main
Expected rule: 1 approving review required
Observed event: token-authenticated push to main with no linked pull-request metadata
'@
            },
            @{
                Path = "evidence\\reviews\\maintainer_comment.txt"
                Content = @'
Maintainer Comment

This update is not in the approved payment patch scope.
Please confirm who authorized the verification-logic change and where the review record is stored.
'@
            }
        )
    },
    @{
        BundleName = "m1-18-cloudtrail-incident"
        Description = @'
Challenge: Unexpected Cloud Access Event

A cloud audit event shows external access to a sensitive storage object.
Review the case pack, inspect the cloud audit and storage-configuration evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0382
Priority: P1
Queue: Cloud Detection and Response

Summary:
The cloud monitoring team observed an external access event against a storage object containing customer data. Audit telemetry suggests object-access controls differ from the approved baseline.

Analyst task:
Review the audit trail and storage evidence, determine what was exposed, and identify which CIA pillar was impacted.
'@
            },
            @{
                Path = "evidence\\aws\\cloudtrail_event.json"
                Content = @'
{
  "eventTime": "2026-03-06T09:22:14Z",
  "eventSource": "s3.amazonaws.com",
  "eventName": "GetObject",
  "sourceIPAddress": "198.51.100.42",
  "requestParameters": {
    "bucketName": "customer-data-prod",
    "key": "exports/customer_database.csv"
  },
  "additionalEventData": {
    "AuthenticationMethod": "Anonymous"
  }
}
'@
            },
            @{
                Path = "evidence\\aws\\storage_policy_status.json"
                Content = @'
{
  "Bucket": "customer-data-prod",
  "PolicyStatus": {
    "IsPublic": true
  },
  "BlockPublicAccess": {
    "IgnorePublicAcls": false,
    "BlockPublicPolicy": false
  }
}
'@
            },
            @{
                Path = "evidence\\aws\\approved_storage_baseline.json"
                Content = @'
{
  "Bucket": "customer-data-prod",
  "ExpectedPolicyStatus": {
    "IsPublic": false
  },
  "ExpectedBlockPublicAccess": {
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true
  },
  "ControlNote": "Customer export objects must be limited to internal service roles."
}
'@
            },
            @{
                Path = "evidence\\aws\\object_inventory.txt"
                Content = @'
Object Inventory Snapshot

Bucket: customer-data-prod
Prefix: exports/
File: exports/customer_database.csv
Classification: Customer PII export
Row estimate: 18240
'@
            },
            @{
                Path = "evidence\\security\\governance_finding.txt"
                Content = @'
Governance Finding

Control: Sensitive storage access anomaly
Resource: s3://customer-data-prod/exports/customer_database.csv
Observed condition: object access event does not align with approved internal-only storage baseline
'@
            }
        )
    },
    @{
        BundleName = "m1-19-kubernetes-crash"
        Description = @'
Challenge: Kubernetes Service Instability

A Kubernetes workload began restarting repeatedly and service quality degraded sharply.
Review the case pack, inspect the Kubernetes health evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0386
Priority: P1
Queue: Platform Reliability

Summary:
The customer portal running in Kubernetes experienced repeated pod restarts in the production namespace, followed by severe service degradation.

Analyst task:
Review the cluster evidence, determine what security property was primarily impacted, and classify the incident accordingly.
'@
            },
            @{
                Path = "evidence\\k8s\\pod_describe.txt"
                Content = @'
Name:           portal-api-7d8966b998-g4h6n
Namespace:      prod
Status:         Running
Restart Count:  12
Last State:     Terminated
  Reason:       OOMKilled
  Exit Code:    137
Events:
  Warning  BackOff    12m (x18 over 22m)  kubelet  Back-off restarting failed container
  Warning  Unhealthy  11m (x14 over 18m)  kubelet  Readiness probe failed: Get "http://10.42.3.15:8080/health": context deadline exceeded
'@
            },
            @{
                Path = "evidence\\k8s\\deployment_status.txt"
                Content = @'
$ kubectl -n prod get deploy portal-api

NAME         READY   UP-TO-DATE   AVAILABLE   AGE
portal-api   0/4     4            0           27d
'@
            },
            @{
                Path = "evidence\\k8s\\baseline_health_snapshot.txt"
                Content = @'
Baseline Health Snapshot (30m before incident)

Service: portal-api.prod.svc.cluster.local
Success rate (5m): 99.4%
HTTP 503 count (5m): 4
Average latency p95: 380 ms
'@
            },
            @{
                Path = "evidence\\k8s\\service_monitor.txt"
                Content = @'
Service Monitor Snapshot

Service: portal-api.prod.svc.cluster.local
Success rate (5m): 6%
HTTP 503 count (5m): 1281
Average latency p95: 9.7 s
Observed condition: login and dashboard endpoints failing health objectives
'@
            },
            @{
                Path = "evidence\\host\\container_log_excerpt.txt"
                Content = @'
2026-03-06T13:44:01Z portal-api starting gunicorn workers
2026-03-06T13:44:18Z portal-api processing /dashboard requests
2026-03-06T13:44:25Z portal-api memory usage exceeded cgroup limit
2026-03-06T13:44:25Z portal-api worker terminated by kernel
'@
            }
        )
    },
    @{
        BundleName = "m1-20-dns-amplification-attack"
        Description = @'
Challenge: DNS Traffic Surge Investigation

A recursive DNS service received a large amplified traffic surge and query reliability degraded sharply.
Review the case pack, inspect the DNS and service-health evidence, and determine which CIA pillar was violated.

Flag format: CTF{pillar}
'@
        Files = @(
            @{
                Path = "evidence\\briefing\\ticket.txt"
                Content = @'
Incident Ticket: INC-2026-0390
Priority: P1
Queue: Network Operations

Summary:
The recursive DNS service handling internal name resolution showed severe instability during a high-volume UDP surge from distributed sources.

Analyst task:
Review the DNS and service evidence, determine what security property was primarily impacted, and classify the incident accordingly.
'@
            },
            @{
                Path = "evidence\\dns\\resolver_log.txt"
                Content = @'
2026-03-06T14:18:02Z named[1842]: client @0x7f91c1d1 198.51.100.22#48712 (corp.local): query: corp.local IN ANY +E(0) (203.0.113.53)
2026-03-06T14:18:03Z named[1842]: client @0x7f91c1d1 198.51.100.44#49110 (corp.local): query: corp.local IN ANY +E(0) (203.0.113.53)
2026-03-06T14:18:04Z named[1842]: rate limit drop response to 198.51.100.44#49110 for corp.local IN ANY
2026-03-06T14:18:06Z named[1842]: resolver timeout due to upstream saturation
'@
            },
            @{
                Path = "evidence\\network\\traffic_summary.csv"
                Content = @'
timestamp,udp_packets_per_sec,avg_response_bytes,top_query_type
2026-03-06T14:17:00Z,4200,148,AAAA
2026-03-06T14:18:00Z,28400,1720,ANY
2026-03-06T14:19:00Z,50120,1718,ANY
2026-03-06T14:20:00Z,47780,1699,ANY
'@
            },
            @{
                Path = "evidence\\service\\baseline_monitor_snapshot.txt"
                Content = @'
DNS Baseline Monitor Snapshot (15m before incident)

Resolver health: healthy
Failed lookup ratio (5m): 1.2%
Median query latency: 21 ms
Top query type: A
'@
            },
            @{
                Path = "evidence\\network\\top_sources.txt"
                Content = @'
Top Source Summary

Unique source IPs observed in 60s window: 4,918
Top sample sources:
- 198.51.100.22
- 198.51.100.44
- 203.0.113.91
- 192.0.2.31
'@
            },
            @{
                Path = "evidence\\service\\monitor_status.txt"
                Content = @'
DNS Service Monitor

Resolver health before spike: healthy
Resolver health during spike: degraded
Failed lookup ratio (5m): 81%
Median query latency during spike: 1320 ms
Observed condition: internal service lookups breached reliability objectives
'@
            }
        )
    }
)

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null

$selectedDefinitions = @($bundleDefinitions)
if ($BundleName.Count -gt 0) {
    $selectedDefinitions = @($bundleDefinitions | Where-Object { $_.BundleName -in $BundleName })
    if ($selectedDefinitions.Count -eq 0) {
        throw "No matching bundle definitions found."
    }
}

if ($BundleName.Count -eq 0) {
    Get-ChildItem $artifactRoot -Filter "m1-*.zip" -ErrorAction SilentlyContinue | Remove-Item -Force
} else {
    foreach ($definition in $selectedDefinitions) {
        $zipPath = Join-Path $artifactRoot ($definition.BundleName + ".zip")
        if (Test-Path $zipPath) {
            Remove-Item -Force $zipPath
        }
    }
}

foreach ($definition in $selectedDefinitions) {
    $bundle = New-BundleDirectory $definition.BundleName
    Write-TextFile -Path (Join-Path $bundle "description.txt") -Content $definition.Description

    foreach ($file in $definition.Files) {
        $targetPath = Join-Path $bundle $file.Path
        if ($file.Kind -eq "pcap") {
            New-PcapArtifact -OutputPath $targetPath
        } elseif ($file.Kind -eq "sniffed_credentials_pcap") {
            New-SniffedCredentialsPcap -OutputPath $targetPath
        } else {
            Write-TextFile -Path $targetPath -Content $file.Content
        }
    }

    Publish-Bundle -BundleName $definition.BundleName
}

Remove-Item -Recurse -Force $buildRoot
Get-ChildItem $artifactRoot | Sort-Object Name | Select-Object Name, Length
