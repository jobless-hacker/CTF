param(
    [string[]]$BundleName = @()
)

$ErrorActionPreference = "Stop"

$artifactRoot = Join-Path $PSScriptRoot "..\\artifacts\\m3"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$buildRoot = Join-Path $env:TEMP "m3_artifacts_build"

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

function Build-TextCaseBundle {
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

function Build-ArchiveLeakBundle {
    $bundle = "m3-09-archive-leak"
    if ($BundleName.Count -gt 0 -and -not ($BundleName -contains $bundle)) {
        return
    }

    $bundlePath = New-BundleDirectory -Name $bundle
    $description = @"
M3-09 - Archive Leak
Difficulty: Medium

Scenario:
A breach archive was recovered from an exposed web path and may contain sensitive strategic documents.

Task:
Inspect the archive and identify the strategic company document.

Flag format:
CTF{answer}
"@
    Write-TextFile -Path (Join-Path $bundlePath "description.txt") -Content $description

    $innerRoot = Join-Path $buildRoot "m3-09-breach-archive-contents"
    if (Test-Path $innerRoot) {
        Remove-Item -Recurse -Force $innerRoot
    }
    New-Item -ItemType Directory -Force -Path $innerRoot | Out-Null
    Write-TextFile -Path (Join-Path $innerRoot "customer_list.xlsx") -Content "placeholder"
    Write-TextFile -Path (Join-Path $innerRoot "contracts.pdf") -Content "placeholder"
    Write-TextFile -Path (Join-Path $innerRoot "company_strategy.docx") -Content "placeholder"

    $innerZip = Join-Path $bundlePath "evidence\\breach_archive.zip"
    if (Test-Path $innerZip) {
        Remove-Item -Force $innerZip
    }
    Compress-Archive -Path (Join-Path $innerRoot "*") -DestinationPath $innerZip -Force

    Publish-Bundle -Bundle $bundle
}

$cases = @(
    @{
        bundle = "m3-01-public-spreadsheet"
        title = "M3-01 - Public Spreadsheet"
        difficulty = "Easy"
        scenario = "A spreadsheet containing customer contact information was accidentally exposed."
        task = "Identify the email belonging to Bob."
        evidence_name = "spreadsheet.csv"
        evidence_content = @"
name,email,phone
Alice,alice@example.com,5551112222
Bob,bob@company.com,5552223333
Charlie,charlie@corp.com,5553334444
"@
    },
    @{
        bundle = "m3-02-github-credentials"
        title = "M3-02 - GitHub Credentials"
        difficulty = "Easy"
        scenario = "A developer pushed sensitive database configuration into a public repository."
        task = "Identify the leaked database password."
        evidence_name = "repo_commit.txt"
        evidence_content = @"
commit 8d39f3

Added database configuration

DB_HOST=prod-db.company.com
DB_USER=admin
DB_PASSWORD=SuperSecret123
"@
    },
    @{
        bundle = "m3-03-misconfigured-storage"
        title = "M3-03 - Misconfigured Storage"
        difficulty = "Easy"
        scenario = "An object storage bucket was publicly listable."
        task = "Identify the file containing payroll data."
        evidence_name = "bucket_listing.txt"
        evidence_content = @"
2026-04-11 payroll.xlsx
2026-04-11 employees.csv
2026-04-11 contracts.pdf
"@
    },
    @{
        bundle = "m3-04-database-dump"
        title = "M3-04 - Database Dump"
        difficulty = "Easy"
        scenario = "A leaked SQL dump includes plaintext credentials."
        task = "Identify the admin password."
        evidence_name = "users.sql"
        evidence_content = @"
INSERT INTO users VALUES
('john','john123'),
('alice','welcome1'),
('admin','AdminPass!');
"@
    },
    @{
        bundle = "m3-05-pastebin-leak"
        title = "M3-05 - Pastebin Leak"
        difficulty = "Easy"
        scenario = "Credentials were posted in an external paste leak."
        task = "Identify the VPN username."
        evidence_name = "paste.txt"
        evidence_content = @"
Company Credentials

vpn_user: corpvpn
vpn_pass: vpnAccess2025
"@
    },
    @{
        bundle = "m3-06-internal-document"
        title = "M3-06 - Internal Document"
        difficulty = "Medium"
        scenario = "A confidential internal planning document was exposed."
        task = "Identify the confidential project name."
        evidence_name = "document.txt"
        evidence_content = @"
CONFIDENTIAL PROJECT

Project Name: Falcon
Launch Date: Q4
"@
    },
    @{
        bundle = "m3-07-cloud-access-leak"
        title = "M3-07 - Cloud Access Leak"
        difficulty = "Medium"
        scenario = "Cloud configuration leaked with access credentials present."
        task = "Identify the exposed AWS secret key."
        evidence_name = "config.json"
        evidence_content = @"
{
 "aws_access_key": "AKIA12345",
 "aws_secret_key": "XyZSecretKey987"
}
"@
    },
    @{
        bundle = "m3-08-log-file-exposure"
        title = "M3-08 - Log File Exposure"
        difficulty = "Medium"
        scenario = "Server logs were exposed and include sensitive token values."
        task = "Identify the exposed token."
        evidence_name = "server.log"
        evidence_content = @"
2026-04-11 request token=9f8a7b6c
"@
    },
    @{
        bundle = "m3-10-web-backup-exposure"
        title = "M3-10 - Web Backup Exposure"
        difficulty = "Medium"
        scenario = "A web directory listing exposed backup files."
        task = "Identify the full website backup file."
        evidence_name = "backup_listing.txt"
        evidence_content = @"
backup_2024.zip
backup_2025.zip
site_backup_full.tar
"@
    }
)

if (Test-Path $buildRoot) {
    Remove-Item -Recurse -Force $buildRoot
}
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

foreach ($case in $cases) {
    Build-TextCaseBundle -Case $case
}
Build-ArchiveLeakBundle

Write-Host "M3 artifact bundles generated in $artifactRoot"
