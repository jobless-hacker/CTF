param(
    [string[]]$BundleName = @()
)

$ErrorActionPreference = "Stop"

$artifactRoot = Join-Path $PSScriptRoot "..\\artifacts\\m10"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$buildRoot = Join-Path $env:TEMP "m10_artifacts_build"

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

function Build-HiddenArchiveBundle {
    $bundle = "m10-02-hidden-archive"
    if ($BundleName.Count -gt 0 -and -not ($BundleName -contains $bundle)) {
        return
    }

    $bundlePath = New-BundleDirectory -Name $bundle
    $description = @"
M10-02 - Hidden Archive
Difficulty: Easy

Scenario:
A recovered archive from a compromised workstation appears to include a hidden file.

Task:
Extract the archive and identify the hidden file.

Flag format:
CTF{answer}
"@

    Write-TextFile -Path (Join-Path $bundlePath "description.txt") -Content $description

    $innerRoot = Join-Path $buildRoot "m10-02-archive-contents"
    if (Test-Path $innerRoot) {
        Remove-Item -Recurse -Force $innerRoot
    }
    New-Item -ItemType Directory -Force -Path $innerRoot | Out-Null
    Write-TextFile -Path (Join-Path $innerRoot "notes.txt") -Content "Forensics note"
    Write-TextFile -Path (Join-Path $innerRoot "report.txt") -Content "Incident report draft"
    Write-TextFile -Path (Join-Path $innerRoot "secret.txt") -Content "hidden indicator"

    $innerZip = Join-Path $bundlePath "evidence\\archive.zip"
    if (Test-Path $innerZip) {
        Remove-Item -Force $innerZip
    }
    Compress-Archive -Path (Join-Path $innerRoot "*") -DestinationPath $innerZip -Force

    Publish-Bundle -Bundle $bundle
}

$cases = @(
    @{
        bundle = "m10-01-suspicious-file-type"
        title = "M10-01 - Suspicious File Type"
        difficulty = "Easy"
        scenario = "A suspicious .bin file was carved from disk and its magic bytes were extracted."
        task = "Identify the real file type."
        evidence_name = "file.bin"
        evidence_content = @"
Hex signature:
89 50 4E 47 0D 0A 1A 0A
"@
    },
    @{
        bundle = "m10-03-image-metadata"
        title = "M10-03 - Image Metadata"
        difficulty = "Easy"
        scenario = "Image metadata from a recovered photo contains device details."
        task = "Identify the device used."
        evidence_name = "photo.jpg"
        evidence_content = @"
Metadata:
Camera: iPhone 13
Date: 2024-05-10
Location: Office
"@
    },
    @{
        bundle = "m10-04-timeline-event"
        title = "M10-04 - Timeline Event"
        difficulty = "Easy"
        scenario = "Timeline reconstruction captured user and admin actions before compromise."
        task = "Identify the suspicious action."
        evidence_name = "timeline.log"
        evidence_content = @"
10:02 user login
10:04 file accessed
10:05 admin password changed
"@
    },
    @{
        bundle = "m10-05-base64-artifact"
        title = "M10-05 - Base64 Artifact"
        difficulty = "Easy"
        scenario = "Encoded text from an artifact requires decoding."
        task = "Decode the message."
        evidence_name = "encoded.txt"
        evidence_content = @"
YXR0YWNr
"@
    },
    @{
        bundle = "m10-06-suspicious-executable"
        title = "M10-06 - Suspicious Executable"
        difficulty = "Medium"
        scenario = "Binary signature bytes were extracted from an unknown executable."
        task = "Identify the file format."
        evidence_name = "file_signature.txt"
        evidence_content = @"
4D 5A
"@
    },
    @{
        bundle = "m10-07-deleted-file-trace"
        title = "M10-07 - Deleted File Trace"
        difficulty = "Medium"
        scenario = "Filesystem logs include records of file deletions during anti-forensics activity."
        task = "Identify the deleted sensitive file."
        evidence_name = "filesystem.log"
        evidence_content = @"
deleted file: credentials.txt
deleted file: logs.txt
"@
    },
    @{
        bundle = "m10-08-hex-artifact"
        title = "M10-08 - Hex Artifact"
        difficulty = "Medium"
        scenario = "A short hex fragment was found in a memory dump."
        task = "Identify the ASCII word."
        evidence_name = "hex_dump.txt"
        evidence_content = @"
66 6C 61 67
"@
    },
    @{
        bundle = "m10-09-stego-image"
        title = "M10-09 - Stego Image"
        difficulty = "Medium"
        scenario = "Steganography notes indicate a keyword hidden in an image."
        task = "Identify the hidden keyword."
        evidence_name = "picture.png"
        evidence_content = @"
Hidden note inside image:
keyword: shadow
"@
    },
    @{
        bundle = "m10-10-forensic-report"
        title = "M10-10 - Forensic Report"
        difficulty = "Medium"
        scenario = "Final incident report includes attribution details for the attacker."
        task = "Identify the attacker alias."
        evidence_name = "incident_report.txt"
        evidence_content = @"
Investigation Summary

Attacker alias discovered:
darktrace
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
Build-HiddenArchiveBundle

Write-Host "M10 artifact bundles generated in $artifactRoot"
