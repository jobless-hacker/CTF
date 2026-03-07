param(
    [string[]]$BundleName = @()
)

$ErrorActionPreference = "Stop"

$artifactRoot = Join-Path $PSScriptRoot "..\\artifacts\\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$buildRoot = Join-Path $env:TEMP "m8_artifacts_build"

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
        bundle = "m8-01-public-storage-bucket"
        title = "M8-01 - Public Storage Bucket"
        difficulty = "Easy"
        scenario = "A cloud storage bucket was accidentally left public and contains business files."
        task = "Identify the sensitive payroll file exposed publicly."
        evidence_name = "bucket_listing.txt"
        evidence_content = @"
2026-05-10 payroll.xlsx
2026-05-10 employees.csv
2026-05-10 contracts.pdf
"@
    },
    @{
        bundle = "m8-02-leaked-cloud-credentials"
        title = "M8-02 - Leaked Cloud Credentials"
        difficulty = "Easy"
        scenario = "A configuration file in source control includes cloud access credentials."
        task = "Identify the exposed secret key."
        evidence_name = "config.json"
        evidence_content = @"
{
 "aws_access_key": "AKIA12345",
 "aws_secret_key": "SecretKey987"
}
"@
    },
    @{
        bundle = "m8-03-public-database-snapshot"
        title = "M8-03 - Public Database Snapshot"
        difficulty = "Easy"
        scenario = "Cloud inventory found a database snapshot with public visibility enabled."
        task = "Identify the exposed resource."
        evidence_name = "snapshot.json"
        evidence_content = @"
{
 "snapshot_id": "db-backup",
 "public": true
}
"@
    },
    @{
        bundle = "m8-04-overprivileged-iam-role"
        title = "M8-04 - Overprivileged IAM Role"
        difficulty = "Easy"
        scenario = "IAM role policy grants broad permissions that violate least privilege."
        task = "Identify the dangerous permission value."
        evidence_name = "iam_policy.json"
        evidence_content = @"
{
 "Effect": "Allow",
 "Action": "*",
 "Resource": "*"
}
"@
    },
    @{
        bundle = "m8-05-exposed-api-key"
        title = "M8-05 - Exposed API Key"
        difficulty = "Easy"
        scenario = "Application configuration artifact exposes a live payment API credential."
        task = "Identify the leaked API key."
        evidence_name = "api_config.txt"
        evidence_content = @"
PAYMENT_API_KEY=pk_live_9a82d2
"@
    },
    @{
        bundle = "m8-06-suspicious-cloudtrail-event"
        title = "M8-06 - Suspicious CloudTrail Event"
        difficulty = "Medium"
        scenario = "CloudTrail logs show unusual console access behavior requiring investigation."
        task = "Identify the suspicious source IP."
        evidence_name = "cloudtrail.json"
        evidence_content = @"
{
 "eventName": "ConsoleLogin",
 "sourceIPAddress": "185.22.33.41"
}
"@
    },
    @{
        bundle = "m8-07-open-security-group"
        title = "M8-07 - Open Security Group"
        difficulty = "Medium"
        scenario = "Security group rules were reviewed after suspicious scanning activity."
        task = "Identify the sensitive port exposed to the internet."
        evidence_name = "security_group.txt"
        evidence_content = @"
Inbound rules:
22/tcp open to 0.0.0.0/0
80/tcp open to 0.0.0.0/0
"@
    },
    @{
        bundle = "m8-08-misconfigured-storage-policy"
        title = "M8-08 - Misconfigured Storage Policy"
        difficulty = "Medium"
        scenario = "Storage policy audit found unrestricted public access definitions."
        task = "Identify the risky policy value."
        evidence_name = "bucket_policy.json"
        evidence_content = @"
{
 "Principal": "*",
 "Action": "s3:GetObject"
}
"@
    },
    @{
        bundle = "m8-09-compromised-access-token"
        title = "M8-09 - Compromised Access Token"
        difficulty = "Medium"
        scenario = "Cloud access logs include token data visible in plaintext."
        task = "Identify the exposed token."
        evidence_name = "access_log.txt"
        evidence_content = @"
token=abc123xyz
user=external_client
"@
    },
    @{
        bundle = "m8-10-exposed-backup-archive"
        title = "M8-10 - Exposed Backup Archive"
        difficulty = "Medium"
        scenario = "Backup listing shows an exposed archive containing full environment data."
        task = "Identify the full backup archive."
        evidence_name = "cloud_backup.txt"
        evidence_content = @"
daily_backup.tar
full_backup_2025.zip
logs_archive.tar
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

Write-Host "M8 artifact bundles generated in $artifactRoot"
