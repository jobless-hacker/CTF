param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-16-api-data-exposure"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m1_16_realworld_build"
$bundleRoot = Join-Path $buildRoot $bundleName

function Write-TextFile {
    param([string]$Path, [string]$Content)
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

function Write-LinesFile {
    param([string]$Path, [System.Collections.Generic.List[string]]$Lines)
    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    [System.IO.File]::WriteAllLines($Path, $Lines, [System.Text.Encoding]::UTF8)
}

function New-GatewayAccessLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T05:00:00", [DateTimeKind]::Utc)
    $paths = @("/v1/profile/summary","/v1/profile/preferences","/v1/orders/recent","/v1/notifications")
    $scopes = @("profile:read","orders:read","notification:read")

    for ($i = 0; $i -lt 11200; $i++) {
        $tsObj = $base.AddMilliseconds($i * 870)
        $ts = $tsObj.ToString("o")
        $path = $paths[$i % $paths.Count]
        $scope = $scopes[$i % $scopes.Count]
        $status = if (($i % 47) -eq 0) { 429 } elseif (($i % 173) -eq 0) { 500 } else { 200 }
        $bytes = 420 + (($i * 13) % 2100)
        $clientIp = "203.0.113.$(20 + ($i % 80))"
        $tokenId = "tk_$((410000 + ($i % 7200)))"
        $requestId = "req-$((700000 + $i))"
        $route = if ($path -eq "/v1/profile/summary") { "profile-public" } else { "public-api" }
        $lines.Add("$ts edge-gw request_id=$requestId client_ip=$clientIp method=GET path=$path token_id=$tokenId scope=$scope status=$status bytes=$bytes route=$route")
    }

    $lines.Add("2026-03-06T08:42:11Z edge-gw request_id=req-778411 client_ip=45.83.22.91 method=GET path=/v1/profile/summary token_id=tk_442188 scope=profile:read status=200 bytes=2148 route=profile-public")
    $lines.Add("2026-03-06T08:42:16Z edge-gw request_id=req-778412 client_ip=45.83.22.91 method=GET path=/v1/profile/summary token_id=tk_442188 scope=profile:read status=200 bytes=2161 route=profile-public")
    $lines.Add("2026-03-06T08:42:24Z edge-gw request_id=req-778413 client_ip=45.83.22.91 method=GET path=/v1/profile/summary token_id=tk_442188 scope=profile:read status=200 bytes=2149 route=profile-public")
    $lines.Add("2026-03-06T08:45:39Z edge-gw request_id=req-778590 client_ip=10.44.8.22 method=GET path=/v1/internal/users/export token_id=tk_900011 scope=admin:internal status=200 bytes=9821 route=internal-admin")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ServiceResponseSamples {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T05:00:00", [DateTimeKind]::Utc)
    $normalFields = @("user_id","display_name","tier","last_login_utc","avatar_url")

    for ($i = 0; $i -lt 8300; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddMilliseconds($i * 930).ToString("o")
            request_id = "req-$((700000 + $i))"
            endpoint = "/v1/profile/summary"
            serializer = if (($i % 311) -eq 0) { "ProfileSerializerV2" } else { "ProfileSerializerPublicV3" }
            response_fields = $normalFields
            pii_score = if (($i % 311) -eq 0) { 0.22 } else { 0.04 }
            token_scope = "profile:read"
            classification = "expected_public_shape"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $leakFields = @("user_id","display_name","email","phone","password_hash","mfa_recovery_codes","ssn_last4")
    $incidentEntries = @(
        [ordered]@{
            timestamp = "2026-03-06T08:42:11Z"
            request_id = "req-778411"
            endpoint = "/v1/profile/summary"
            serializer = "ProfileSerializerDebugV1"
            response_fields = $leakFields
            pii_score = 0.98
            token_scope = "profile:read"
            classification = "unexpected_sensitive_fields"
        },
        [ordered]@{
            timestamp = "2026-03-06T08:42:16Z"
            request_id = "req-778412"
            endpoint = "/v1/profile/summary"
            serializer = "ProfileSerializerDebugV1"
            response_fields = $leakFields
            pii_score = 0.99
            token_scope = "profile:read"
            classification = "unexpected_sensitive_fields"
        },
        [ordered]@{
            timestamp = "2026-03-06T08:42:24Z"
            request_id = "req-778413"
            endpoint = "/v1/profile/summary"
            serializer = "ProfileSerializerDebugV1"
            response_fields = $leakFields
            pii_score = 0.99
            token_scope = "profile:read"
            classification = "unexpected_sensitive_fields"
        },
        [ordered]@{
            timestamp = "2026-03-06T08:45:39Z"
            request_id = "req-778590"
            endpoint = "/v1/internal/users/export"
            serializer = "InternalUserExportSerializer"
            response_fields = @("user_id","email","password_hash","mfa_recovery_codes","ssn_last4","risk_label")
            pii_score = 0.99
            token_scope = "admin:internal"
            classification = "expected_internal_sensitive_shape"
        }
    )

    foreach ($entry in $incidentEntries) {
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-TokenIntrospection {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T04:00:00", [DateTimeKind]::Utc)
    $scopes = @("profile:read","orders:read","notification:read","profile:write")

    for ($i = 0; $i -lt 6200; $i++) {
        $entry = [ordered]@{
            timestamp = $base.AddSeconds($i * 2).ToString("o")
            token_id = "tk_$((410000 + ($i % 7200)))"
            subject = "usr_$((10000 + ($i % 9000)))"
            client_id = "mobile-app"
            active = $true
            scope = $scopes[$i % $scopes.Count]
            role = "customer"
            auth_context = "mfa"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T08:42:10Z"
        token_id = "tk_442188"
        subject = "usr_11872"
        client_id = "mobile-app"
        active = $true
        scope = "profile:read"
        role = "customer"
        auth_context = "mfa"
    }) | ConvertTo-Json -Compress))

    $lines.Add((([ordered]@{
        timestamp = "2026-03-06T08:45:38Z"
        token_id = "tk_900011"
        subject = "svc_support"
        client_id = "ops-console"
        active = $true
        scope = "admin:internal"
        role = "support_admin"
        auth_context = "hardware_key"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthzDecisions {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,request_id,endpoint,token_scope,policy_name,policy_version,decision,reason")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T05:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5400; $i++) {
        $ts = $base.AddSeconds($i * 3).ToString("o")
        $req = "req-$((700000 + $i))"
        $endpoint = if (($i % 9) -eq 0) { "/v1/profile/preferences" } else { "/v1/profile/summary" }
        $scope = "profile:read"
        $policy = "profile-response-shape-guard"
        $version = if (($i % 430) -eq 0) { "2.5.1" } else { "2.5.3" }
        $decision = "allow"
        $reason = if ($version -eq "2.5.1") { "legacy serializer exception enabled for compatibility" } else { "public response shape validated" }
        $lines.Add("$ts,$req,$endpoint,$scope,$policy,$version,$decision,$reason")
    }

    $lines.Add("2026-03-06T08:42:11Z,req-778411,/v1/profile/summary,profile:read,profile-response-shape-guard,2.5.1,allow,legacy serializer exception enabled for compatibility")
    $lines.Add("2026-03-06T08:42:16Z,req-778412,/v1/profile/summary,profile:read,profile-response-shape-guard,2.5.1,allow,legacy serializer exception enabled for compatibility")
    $lines.Add("2026-03-06T08:42:24Z,req-778413,/v1/profile/summary,profile:read,profile-response-shape-guard,2.5.1,allow,legacy serializer exception enabled for compatibility")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-WafAndDlp {
    param(
        [string]$WafPath,
        [string]$DlpPath
    )

    $waf = New-Object System.Collections.Generic.List[string]
    $baseWaf = [datetime]::SpecifyKind([datetime]"2026-03-06T05:00:00", [DateTimeKind]::Utc)
    for ($i = 0; $i -lt 4200; $i++) {
        $entry = [ordered]@{
            timestamp = $baseWaf.AddSeconds($i * 5).ToString("o")
            request_id = "req-$((700000 + ($i % 8500)))"
            rule_id = if (($i % 17) -eq 0) { "942100" } else { "920160" }
            severity = if (($i % 17) -eq 0) { "medium" } else { "low" }
            action = "allow"
            note = if (($i % 17) -eq 0) { "suspected sqli pattern false positive in search query" } else { "benign protocol anomaly" }
        }
        $waf.Add(($entry | ConvertTo-Json -Compress))
    }
    Write-LinesFile -Path $WafPath -Lines $waf

    $dlp = New-Object System.Collections.Generic.List[string]
    $dlp.Add("timestamp_utc,request_id,endpoint,detection_type,severity,token_scope,status,note")
    $baseDlp = [datetime]::SpecifyKind([datetime]"2026-03-06T05:00:00", [DateTimeKind]::Utc)
    for ($i = 0; $i -lt 3800; $i++) {
        $ts = $baseDlp.AddSeconds($i * 6).ToString("o")
        $req = "req-$((700000 + ($i % 8200)))"
        $endpoint = "/v1/profile/summary"
        $det = if (($i % 211) -eq 0) { "email+phone combo" } else { "none"
        }
        $severity = if ($det -eq "none") { "info" } else { "low" }
        $status = if ($det -eq "none") { "ignored" } else { "closed_false_positive" }
        $note = if ($det -eq "none") { "no sensitive field rule match" } else { "expected customer contact fields" }
        $dlp.Add("$ts,$req,$endpoint,$det,$severity,profile:read,$status,$note")
    }

    $dlp.Add("2026-03-06T08:42:12Z,req-778411,/v1/profile/summary,password_hash+ssn_last4,critical,profile:read,open,public endpoint returned restricted fields")
    $dlp.Add("2026-03-06T08:42:17Z,req-778412,/v1/profile/summary,password_hash+ssn_last4,critical,profile:read,open,public endpoint returned restricted fields")
    $dlp.Add("2026-03-06T08:42:25Z,req-778413,/v1/profile/summary,password_hash+ssn_last4,critical,profile:read,open,public endpoint returned restricted fields")
    $dlp.Add("2026-03-06T08:45:39Z,req-778590,/v1/internal/users/export,password_hash+ssn_last4,medium,admin:internal,acknowledged,expected for internal export route")

    Write-LinesFile -Path $DlpPath -Lines $dlp
}

function New-ReleaseLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("change_id,deployed_utc,service,version,actor,approval_status,change_summary")
    $base = [datetime]::SpecifyKind([datetime]"2026-02-20T10:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 1600; $i++) {
        $deployed = $base.AddMinutes($i * 35).ToString("o")
        $service = if (($i % 3) -eq 0) { "profile-api" } elseif (($i % 3) -eq 1) { "orders-api" } else { "notify-api" }
        $version = "v$((3 + ($i % 5))).$((10 + ($i % 9))).$((1 + ($i % 6)))"
        $actor = if (($i % 2) -eq 0) { "release-bot" } else { "platform-engineer" }
        $approval = "approved"
        $summary = if (($i % 71) -eq 0) { "serializer refactor with compatibility fallback" } else { "routine patch and performance tuning" }
        $lines.Add("CHG-$((89000 + $i)),$deployed,$service,$version,$actor,$approval,$summary")
    }

    $lines.Add("CHG-91211,2026-03-06T08:40:55Z,profile-api,v4.18.2,release-bot,approved,enable ProfileSerializerDebugV1 fallback behind feature flag PROFILE_SERIALIZER_COMPAT=1")
    $lines.Add("CHG-91212,2026-03-06T08:43:10Z,profile-api,v4.18.2,platform-engineer,approved,rollback PROFILE_SERIALIZER_COMPAT to 0 after privacy alert")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-16 Unexpected API Response Fields (Real-World Investigation Pack)

Scenario:
A public profile API began returning fields that should not be exposed to normal customer tokens.
Evidence includes API gateway traffic, response samples, token introspection, authorization decisions,
WAF telemetry, DLP detections, and release-change records.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4519
Severity: High
Queue: AppSec + API Platform

Summary:
Privacy controls alerted on unexpected sensitive fields in responses from /v1/profile/summary.
Client token scope appears to be normal customer read scope.

Scope:
- Service: profile-api
- Endpoint: /v1/profile/summary
- Impact window: 2026-03-06 08:42 UTC onward

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Verify if sensitive fields were returned to non-internal token scopes.
- Distinguish internal admin export traffic from public endpoint responses.
- Correlate release changes with response schema drift and DLP findings.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$publicSchema = @'
{
  "endpoint": "/v1/profile/summary",
  "allowed_fields": ["user_id", "display_name", "tier", "last_login_utc", "avatar_url"],
  "restricted_fields": ["password_hash", "mfa_recovery_codes", "ssn_last4"]
}
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\api\schema_contract_public.json") -Content $publicSchema

$internalSchema = @'
{
  "endpoint": "/v1/internal/users/export",
  "allowed_scope": "admin:internal",
  "allowed_fields": ["user_id", "email", "password_hash", "mfa_recovery_codes", "ssn_last4", "risk_label"]
}
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\api\schema_contract_internal.json") -Content $internalSchema

New-GatewayAccessLog -OutputPath (Join-Path $bundleRoot "evidence\api\gateway_access.log")
New-ServiceResponseSamples -OutputPath (Join-Path $bundleRoot "evidence\api\service_response_samples.jsonl")
New-TokenIntrospection -OutputPath (Join-Path $bundleRoot "evidence\auth\token_introspection.jsonl")
New-AuthzDecisions -OutputPath (Join-Path $bundleRoot "evidence\auth\authorization_decisions.csv")
New-WafAndDlp -WafPath (Join-Path $bundleRoot "evidence\security\waf_alerts.jsonl") -DlpPath (Join-Path $bundleRoot "evidence\security\privacy_dlp_findings.csv")
New-ReleaseLog -OutputPath (Join-Path $bundleRoot "evidence\operations\release_change_log.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
