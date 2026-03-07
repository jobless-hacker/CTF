param()

$ErrorActionPreference = "Stop"

$bundleName = "m8-07-open-security-group"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m8"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m8_07_realworld_build"
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

function New-SecurityGroupInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $groups = @("sg-app-front","sg-api-tier","sg-db-tier","sg-worker-tier","sg-monitoring")

    for ($i = 0; $i -lt 7100; $i++) {
        $ts = $base.AddSeconds($i * 5).ToString("o")
        $g = $groups[$i % $groups.Count]
        $lines.Add("$ts sg-inventory security_group=$g vpc=vpc-07a1 ingress_ports=80,443 exposure=restricted status=ok")
    }

    $lines.Add("2026-03-08T19:05:11Z sg-inventory security_group=sg-prod-web vpc=vpc-07a1 ingress_ports=22,80,443 exposure=public status=violation sensitive_open_port=22 cidr=0.0.0.0/0")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityGroupRulesCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,security_group,protocol,port,cidr,direction,risk,notes")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $groups = @("sg-app-front","sg-api-tier","sg-worker-tier")
    $ports = @(80,443,8080)
    $cidrs = @("10.0.0.0/16","172.16.0.0/16","203.0.113.0/24")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $g = $groups[$i % $groups.Count]
        $p = $ports[$i % $ports.Count]
        $c = $cidrs[$i % $cidrs.Count]
        $lines.Add("$ts,$g,tcp,$p,$c,ingress,low,baseline rule")
    }

    $lines.Add("2026-03-08T19:05:12Z,sg-prod-web,tcp,22,0.0.0.0/0,ingress,critical,sensitive management port exposed to internet")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-VpcFlowLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $srcs = @("10.0.10.12","10.0.20.25","10.0.30.44","10.0.40.67")
    $dsts = @("10.0.1.10","10.0.1.11","10.0.1.12")
    $ports = @(80,443,8080)

    for ($i = 0; $i -lt 6200; $i++) {
        $ts = $base.AddSeconds($i * 6).ToString("o")
        $src = $srcs[$i % $srcs.Count]
        $dst = $dsts[$i % $dsts.Count]
        $p = $ports[$i % $ports.Count]
        $lines.Add("$ts vpc-flow srcaddr=$src dstaddr=$dst dstport=$p protocol=tcp action=ACCEPT bytes=$((1200 + (($i * 23) % 900000)))")
    }

    $lines.Add("2026-03-08T19:05:13Z vpc-flow srcaddr=185.88.17.41 dstaddr=10.0.1.10 dstport=22 protocol=tcp action=ACCEPT bytes=842 note=internet_ssh_attempt")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-CloudTrailEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $events = @("DescribeSecurityGroups","DescribeInstances","DescribeVpcs")

    for ($i = 0; $i -lt 5400; $i++) {
        $entry = [ordered]@{
            eventTime = $base.AddSeconds($i * 7).ToString("o")
            eventSource = "ec2.amazonaws.com"
            eventName = $events[$i % $events.Count]
            awsRegion = "ap-south-1"
            sourceIPAddress = "10.50.2." + (($i % 200) + 10)
            userIdentity = [ordered]@{
                type = "AssumedRole"
                principalId = "AROAXXXXX:infra-audit"
            }
            readOnly = $true
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        eventTime = "2026-03-08T19:05:14Z"
        eventSource = "ec2.amazonaws.com"
        eventName = "AuthorizeSecurityGroupIngress"
        awsRegion = "ap-south-1"
        sourceIPAddress = "185.88.17.41"
        userIdentity = [ordered]@{
            type = "IAMUser"
            userName = "ops-temp-admin"
        }
        requestParameters = [ordered]@{
            groupId = "sg-prod-web"
            ipProtocol = "tcp"
            fromPort = 22
            toPort = 22
            cidrIp = "0.0.0.0/0"
        }
        additionalEventData = [ordered]@{
            exposedPort = 22
            publicIngress = $true
        }
        readOnly = $false
    }) | ConvertTo-Json -Compress))

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SgConfigAudit {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5100; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $lines.Add("$ts sg-config-audit rule=no-sensitive-public-ingress status=pass group=sg-app-front")
    }

    $lines.Add("2026-03-08T19:05:15Z sg-config-audit rule=no-sensitive-public-ingress status=violation group=sg-prod-web exposed_port=22 cidr=0.0.0.0/0")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("sg-posture-watch","public-ingress-watch","port-risk-watch","network-policy-watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 9).ToString("o")
            alert_id = "sg-" + ("{0:D8}" -f (70200000 + $i))
            severity = if (($i % 199) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine security group posture monitoring"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T19:05:16Z"
        alert_id = "sg-70259999"
        severity = "critical"
        type = "sensitive_port_publicly_exposed"
        status = "open"
        security_group = "sg-prod-web"
        exposed_port = 22
        detail = "sensitive SSH port is internet-accessible via 0.0.0.0/0 ingress"
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
        $evt = if (($i % 251) -eq 0) { "sg-exposure-review" } else { "normal-cloud-monitoring" }
        $sev = if ($evt -eq "sg-exposure-review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-cloud-07,$sev,security group exposure baseline telemetry")
    }

    $lines.Add("2026-03-08T19:05:17Z,open_security_group_confirmed,siem-cloud-07,high,correlated sg rules/cloudtrail/flow/audit evidence confirms internet exposure")
    $lines.Add("2026-03-08T19:05:20Z,sensitive_open_port_identified,siem-cloud-07,critical,sensitive open port identified as 22")
    $lines.Add("2026-03-08T19:05:28Z,incident_opened,siem-cloud-07,high,INC-2026-5807 open security group investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SecurityGroupTxt {
    param([string]$OutputPath)

    $content = @'
Inbound rules:
22/tcp open to 0.0.0.0/0
80/tcp open to 0.0.0.0/0
443/tcp open to 0.0.0.0/0
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
Security Group Exposure Policy (Excerpt)

1) Sensitive management ports must never be exposed to 0.0.0.0/0.
2) Public ingress must be restricted to approved application ports only.
3) SOC/CloudSec must identify and report exposed sensitive port values.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Open Security Group Triage Runbook (Excerpt)

1) Correlate SG inventory, rule exports, and CloudTrail ingress changes.
2) Validate exposure in VPC flow telemetry.
3) Confirm config-audit violations and alert/SIEM normalization.
4) Submit sensitive open port value.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-ThreatIntel {
    param([string]$OutputPath)

    $content = @'
Threat Intel Snapshot

Observed cloud abuse pattern: internet-exposed management ports via permissive SG rules.
Most frequently abused exposed port in this campaign: 22
Current incident normalized sensitive open port: 22
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M8-07 Open Security Group (Real-World Investigation Pack)

Scenario:
Cloud posture monitoring indicates internet-exposed ingress on a sensitive management port.

Task:
Analyze the investigation pack and identify the sensitive open port.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5807
Severity: High
Queue: SOC + CloudSec

Summary:
Potentially dangerous internet-exposed security group rule detected.

Scope:
- Security Group: sg-prod-web
- Objective: identify sensitive open port value
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate security group inventory, rules export, VPC flow logs, CloudTrail ingress events, config audit logs, security alerts, SIEM timeline, and policy/runbook context.
- Determine the sensitive open port.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-SecurityGroupInventory -OutputPath (Join-Path $bundleRoot "evidence\cloud\security_group_inventory.log")
New-SecurityGroupRulesCsv -OutputPath (Join-Path $bundleRoot "evidence\cloud\security_group_rules.csv")
New-VpcFlowLog -OutputPath (Join-Path $bundleRoot "evidence\cloud\vpc_flow.log")
New-CloudTrailEvents -OutputPath (Join-Path $bundleRoot "evidence\cloud\cloudtrail_events.jsonl")
New-SgConfigAudit -OutputPath (Join-Path $bundleRoot "evidence\cloud\sg_config_audit.log")
New-SecurityAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\open_sg_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-SecurityGroupTxt -OutputPath (Join-Path $bundleRoot "evidence\cloud\security_group.txt")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\security_group_exposure_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\open_security_group_triage_runbook.txt")
New-ThreatIntel -OutputPath (Join-Path $bundleRoot "evidence\intel\threat_intel_snapshot.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
