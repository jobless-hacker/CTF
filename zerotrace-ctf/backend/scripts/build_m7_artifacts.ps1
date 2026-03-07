param(
    [string[]]$BundleName = @()
)

$ErrorActionPreference = "Stop"

$artifactRoot = Join-Path $PSScriptRoot "..\\artifacts\\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$buildRoot = Join-Path $env:TEMP "m7_artifacts_build"

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
        bundle = "m7-01-suspicious-login-query"
        title = "M7-01 - Suspicious Login Query"
        difficulty = "Easy"
        scenario = "Access logs captured a crafted authentication request aimed at bypassing login checks."
        task = "Identify the vulnerability being exploited."
        evidence_name = "access.log"
        evidence_content = @"
10.10.4.22 - - [08/Jul/2026:10:11:33 +0530] "GET /login?user=admin' OR '1'='1 HTTP/1.1" 200 932
"@
    },
    @{
        bundle = "m7-02-reflected-script"
        title = "M7-02 - Reflected Script"
        difficulty = "Easy"
        scenario = "A web request to the search endpoint includes active script content in query input."
        task = "Identify the attack type."
        evidence_name = "request.txt"
        evidence_content = @"
GET /search?q=<script>alert(1)</script> HTTP/1.1
Host: app.local
User-Agent: Mozilla/5.0
"@
    },
    @{
        bundle = "m7-03-file-path-access"
        title = "M7-03 - File Path Access"
        difficulty = "Easy"
        scenario = "Download endpoint parameters include traversal patterns to read local files."
        task = "Identify the vulnerability."
        evidence_name = "web_request.log"
        evidence_content = @"
GET /download?file=../../etc/passwd HTTP/1.1
"@
    },
    @{
        bundle = "m7-04-broken-authentication"
        title = "M7-04 - Broken Authentication"
        difficulty = "Easy"
        scenario = "Authentication logs indicate weak credential policy and repeated risky admin logins."
        task = "Identify the authentication weakness."
        evidence_name = "auth.log"
        evidence_content = @"
admin login password: admin
admin login password: admin
admin login password: admin
"@
    },
    @{
        bundle = "m7-05-exposed-admin-panel"
        title = "M7-05 - Exposed Admin Panel"
        difficulty = "Easy"
        scenario = "Directory listing output from web root reveals high-risk internal paths."
        task = "Identify the sensitive directory."
        evidence_name = "directory_listing.txt"
        evidence_content = @"
/
index.html
login.php
admin/
"@
    },
    @{
        bundle = "m7-06-file-upload-abuse"
        title = "M7-06 - File Upload Abuse"
        difficulty = "Medium"
        scenario = "Server upload activity shows a suspicious executable script submitted via file upload."
        task = "Identify the malicious uploaded file."
        evidence_name = "upload.log"
        evidence_content = @"
user uploaded file: shell.php
"@
    },
    @{
        bundle = "m7-07-api-data-exposure"
        title = "M7-07 - API Data Exposure"
        difficulty = "Medium"
        scenario = "API response body includes credentials that should never be returned in plaintext."
        task = "Identify the exposed sensitive field."
        evidence_name = "api_response.json"
        evidence_content = @"
{
 "user":"john",
 "password":"123456"
}
"@
    },
    @{
        bundle = "m7-08-command-injection"
        title = "M7-08 - Command Injection"
        difficulty = "Medium"
        scenario = "Captured HTTP request parameters include shell command chaining."
        task = "Identify the injected command."
        evidence_name = "request_capture.txt"
        evidence_content = @"
GET /ping?host=8.8.8.8;cat /etc/passwd HTTP/1.1
"@
    },
    @{
        bundle = "m7-09-insecure-cookie"
        title = "M7-09 - Insecure Cookie"
        difficulty = "Medium"
        scenario = "HTTP response headers set session cookies without key browser-side protections."
        task = "Identify the missing cookie security flag."
        evidence_name = "http_headers.txt"
        evidence_content = @"
HTTP/1.1 200 OK
Set-Cookie: session=abc123
Content-Type: text/html
"@
    },
    @{
        bundle = "m7-10-sensitive-backup"
        title = "M7-10 - Sensitive Backup"
        difficulty = "Medium"
        scenario = "Web-exposed file listing includes an archive that should not be publicly reachable."
        task = "Identify the exposed backup file."
        evidence_name = "web_files.txt"
        evidence_content = @"
index.php
config.php
backup.zip
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

Write-Host "M7 artifact bundles generated in $artifactRoot"
