param(
    [string[]]$BundleName = @()
)

$ErrorActionPreference = "Stop"

$artifactRoot = Join-Path $PSScriptRoot "..\\artifacts\\m9"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$buildRoot = Join-Path $env:TEMP "m9_artifacts_build"

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
        bundle = "m9-01-image-metadata"
        title = "M9-01 - Image Metadata"
        difficulty = "Easy"
        scenario = "A recovered image contains geolocation metadata from a mobile device."
        task = "Identify the city where the photo was taken."
        evidence_name = "photo.jpg"
        evidence_content = @"
EXIF Metadata:
GPS Latitude: 17.3850
GPS Longitude: 78.4867
"@
    },
    @{
        bundle = "m9-02-suspicious-username"
        title = "M9-02 - Suspicious Username"
        difficulty = "Easy"
        scenario = "An online profile was linked to suspicious forum activity."
        task = "Identify the username."
        evidence_name = "profile.txt"
        evidence_content = @"
Forum account discovered during investigation:

username: shadowfox92
joined: 2023
posts: hacking discussions
"@
    },
    @{
        bundle = "m9-03-domain-investigation"
        title = "M9-03 - Domain Investigation"
        difficulty = "Easy"
        scenario = "WHOIS output was captured for a suspicious external domain."
        task = "Identify the registrar."
        evidence_name = "whois.txt"
        evidence_content = @"
Domain Name: suspicious-site.com
Registrar: NameCheap Inc.
Creation Date: 2024
"@
    },
    @{
        bundle = "m9-04-document-metadata"
        title = "M9-04 - Document Metadata"
        difficulty = "Easy"
        scenario = "A leaked internal report includes metadata fields."
        task = "Identify the document author."
        evidence_name = "report.pdf"
        evidence_content = @"
PDF Metadata
Author: John Carter
Company: SecureTech
"@
    },
    @{
        bundle = "m9-05-website-archive"
        title = "M9-05 - Website Archive"
        difficulty = "Easy"
        scenario = "Archived web content points to legacy infrastructure."
        task = "Identify the old portal domain."
        evidence_name = "archive.txt"
        evidence_content = @"
Old version of company site archived at:

oldportal.company.net
"@
    },
    @{
        bundle = "m9-06-social-media-leak"
        title = "M9-06 - Social Media Leak"
        difficulty = "Medium"
        scenario = "A public social post includes a location clue."
        task = "Identify the location mentioned."
        evidence_name = "tweet.txt"
        evidence_content = @"
Excited to visit Charminar today! #Hyderabad
"@
    },
    @{
        bundle = "m9-07-hidden-image-info"
        title = "M9-07 - Hidden Image Info"
        difficulty = "Medium"
        scenario = "Detailed image metadata was extracted for device attribution."
        task = "Identify the camera model."
        evidence_name = "image_metadata.txt"
        evidence_content = @"
Camera Model: Canon EOS 80D
Lens: 18-135mm
"@
    },
    @{
        bundle = "m9-08-email-exposure"
        title = "M9-08 - Email Exposure"
        difficulty = "Medium"
        scenario = "Email headers were analyzed to trace sender infrastructure."
        task = "Identify the sender IP."
        evidence_name = "email_header.txt"
        evidence_content = @"
Received: from 203.0.113.88
by mail.server.com
"@
    },
    @{
        bundle = "m9-09-subdomain-discovery"
        title = "M9-09 - Subdomain Discovery"
        difficulty = "Medium"
        scenario = "DNS reconnaissance found multiple subdomains in use."
        task = "Identify the development subdomain."
        evidence_name = "dns_records.txt"
        evidence_content = @"
www.company.com
mail.company.com
dev.company.com
"@
    },
    @{
        bundle = "m9-10-public-code-leak"
        title = "M9-10 - Public Code Leak"
        difficulty = "Medium"
        scenario = "A public commit reveals details about a developer account."
        task = "Identify the developer username."
        evidence_name = "github_commit.txt"
        evidence_content = @"
commit 92ad8f

Author: alice_dev
Added API integration code
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

Write-Host "M9 artifact bundles generated in $artifactRoot"
