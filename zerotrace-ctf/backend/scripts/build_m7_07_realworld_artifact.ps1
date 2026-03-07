param()

$ErrorActionPreference = "Stop"

$bundleName = "m7-07-api-data-exposure"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m7"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m7_07_realworld_build"
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
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $ips = @("103.20.11.8","110.227.41.22","49.205.87.15","125.16.77.19")
    $routes = @("/api/v2/profile","/api/v2/orders","/api/v2/notifications","/api/v2/account")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $ip = $ips[$i % $ips.Count]
        $route = $routes[$i % $routes.Count]
        $code = if (($i % 131) -eq 0) { 304 } else { 200 }
        $bytes = 1200 + (($i * 19) % 16000)
        $reqId = "req-" + ("{0:D7}" -f (8800000 + $i))
        $lines.Add("$ts api-gw request_id=$reqId src_ip=$ip method=GET path=$route status=$code bytes=$bytes tenant=consumer-app")
    }

    $lines.Add("2026-03-08T09:42:12Z api-gw request_id=req-8807120 src_ip=185.199.110.42 method=GET path=/api/v2/admin/users/1442 status=200 bytes=2144 tenant=consumer-app note=response_contains_sensitive_field=password")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-ResponseSamples {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("alice","bob","charlie","dev01","support01")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $reqId = "req-" + ("{0:D7}" -f (8800000 + $i))
        $u = $users[$i % $users.Count]
        $entry = [ordered]@{
            timestamp_utc = $ts
            request_id = $reqId
            endpoint = "/api/v2/profile"
            status = 200
            response = [ordered]@{
                user = $u
                email = "$u@example.local"
                plan = "standard"
                phone = "9xxxxxxxxx"
            }
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T09:42:12Z"
        request_id = "req-8807120"
        endpoint = "/api/v2/admin/users/1442"
        status = 200
        response = [ordered]@{
            user = "john"
            email = "john@company.local"
            role = "customer"
            password = "TempPass!2026"
        }
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SchemaAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5300; $i++) {
        $ts = $base.AddSeconds($i * 7).ToString("o")
        $reqId = "req-" + ("{0:D7}" -f (8800000 + $i))
        $lines.Add("$ts schema-audit request_id=$reqId endpoint=/api/v2/profile expected_fields=user,email,plan,phone observed_fields=user,email,plan,phone status=ok")
    }

    $lines.Add("2026-03-08T09:42:13Z schema-audit request_id=req-8807120 endpoint=/api/v2/admin/users/1442 expected_fields=user,email,role observed_fields=user,email,role,password status=violation unexpected_field=password")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-DlpAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("pii-watch","data-minimization-watch","schema-drift-watch","api-review-watch")

    for ($i = 0; $i -lt 4200; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "dlp-" + ("{0:D8}" -f (77200000 + $i))
            severity = if (($i % 211) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine api response data quality review"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T09:42:14Z"
        alert_id = "dlp-77259999"
        severity = "critical"
        type = "api_sensitive_field_exposure"
        status = "open"
        request_id = "req-8807120"
        endpoint = "/api/v2/admin/users/1442"
        sensitive_field = "password"
        detail = "response payload includes restricted credential field"
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $evt = if (($i % 251) -eq 0) { "api-schema-review" } else { "normal-api-monitoring" }
        $sev = if ($evt -eq "api-schema-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-api-07,$sev,response schema baseline monitoring")
    }

    $lines.Add("2026-03-08T09:42:15Z,api_data_exposure_confirmed,siem-api-07,high,correlated gateway/schema/dlp evidence confirms sensitive field exposure")
    $lines.Add("2026-03-08T09:42:20Z,sensitive_field_identified,siem-api-07,critical,sensitive response field identified as password")
    $lines.Add("2026-03-08T09:42:30Z,incident_opened,siem-api-07,high,INC-2026-5707 api data exposure investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-OpenApiSnapshot {
    param([string]$OutputPath)

    $content = @'
openapi: 3.0.0
info:
  title: Consumer API
  version: 2.6.1
paths:
  /api/v2/admin/users/{id}:
    get:
      responses:
        "200":
          description: user profile
          content:
            application/json:
              schema:
                type: object
                properties:
                  user:
                    type: string
                  email:
                    type: string
                  role:
                    type: string
                additionalProperties: false
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-PatchDiff {
    param([string]$OutputPath)

    $content = @'
diff --git a/services/user_response_builder.ts b/services/user_response_builder.ts
index 9d772ac..cc129a1 100644
--- a/services/user_response_builder.ts
+++ b/services/user_response_builder.ts
@@ -41,7 +41,6 @@ export function toUserResponse(user: UserRecord) {
   return {
     user: user.username,
     email: user.email,
-    password: user.password,
     role: user.role
   };
 }
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
API Response Data Minimization Policy (Excerpt)

1) API responses must not expose credential fields in client payloads.
2) Response schema must enforce allow-listed fields only.
3) SOC/AppSec must identify and report exposed sensitive field names.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
API Data Exposure Triage Runbook (Excerpt)

1) Pivot on suspicious request id from gateway and schema audit.
2) Compare response payload against OpenAPI schema allow-list.
3) Confirm DLP and SIEM enrichment for normalized sensitive field.
4) Submit the sensitive field name and open remediation ticket.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed weak pattern: excessive API response fields on admin endpoints.
Commonly leaked credential key name: password
Current incident sensitive field indicator: password
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M7-07 API Data Exposure (Real-World Investigation Pack)

Scenario:
API telemetry indicates a production endpoint returned restricted sensitive data in client responses.

Task:
Analyze the investigation pack and identify the exposed sensitive field.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5707
Severity: High
Queue: SOC + AppSec

Summary:
Potential sensitive field exposure in API response payload.

Scope:
- Endpoint: /api/v2/admin/users/1442
- Suspicious request: req-8807120
- Objective: identify exposed sensitive field name
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate gateway logs, response samples, schema audit, DLP alerts, SIEM timeline, OpenAPI snapshot, patch diff, and policy/runbook context.
- Determine the exposed sensitive field in API response.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-GatewayAccessLog -OutputPath (Join-Path $bundleRoot "evidence\api\gateway_access.log")
New-ResponseSamples -OutputPath (Join-Path $bundleRoot "evidence\api\response_samples.jsonl")
New-SchemaAudit -OutputPath (Join-Path $bundleRoot "evidence\api\schema_audit.log")
New-DlpAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\dlp_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-OpenApiSnapshot -OutputPath (Join-Path $bundleRoot "evidence\dev\openapi_snapshot.yaml")
New-PatchDiff -OutputPath (Join-Path $bundleRoot "evidence\dev\service_patch.diff")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\api_response_data_minimization_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\api_data_exposure_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
