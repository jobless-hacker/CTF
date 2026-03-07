param()

$ErrorActionPreference = "Stop"

$bundleName = "m5-10-unauthorized-ssh-key"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m5"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot "$bundleName.zip"
$buildRoot = Join-Path $env:TEMP "m5_10_realworld_build"
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

function New-KeyInventory {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,node,user,key_type,fingerprint,key_owner,source,status")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $owners = @("ops-team","devops","backup-bot","ci-runner","sec-admin")
    $nodes = @("lin-ssh-01","lin-ssh-02","lin-ssh-03")

    for ($i = 0; $i -lt 7400; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("o")
        $node = $nodes[$i % $nodes.Count]
        $user = if (($i % 5) -eq 0) { "deploy" } else { "emp_{0:D4}" -f ($i % 3800) }
        $owner = $owners[$i % $owners.Count]
        $finger = "SHA256:{0}" -f ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("fp_{0:D8}" -f $i))).TrimEnd("="))
        $lines.Add("$ts,$node,$user,ssh-rsa,$finger,$owner,authorized_keys,baseline")
    }

    $lines.Add("2026-03-08T09:14:27Z,lin-ssh-02,deploy,ssh-rsa,SHA256:q8zzot1XW8fVxW2OJgJ8Imh2MRYsSBA2ue6YV9w8wL4,attacker,authorized_keys,unauthorized")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthorizedKeysSnapshot {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# snapshot: /home/deploy/.ssh/authorized_keys (lin-ssh-02)")
    $lines.Add("# collection_time_utc: 2026-03-08T09:15:00Z")

    for ($i = 0; $i -lt 6700; $i++) {
        $suffix = "{0:x8}" -f (120000000 + $i)
        $comment = if (($i % 9) -eq 0) { "deploy@company" } else { "ops-key-{0:D4}@company" -f ($i % 1400) }
        $lines.Add("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ$suffix $comment")
    }

    $lines.Add("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUNAUTHKEY1337 attacker@evil")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-FileIntegrityEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $events = @("IN_OPEN","IN_CLOSE_WRITE","IN_ATTRIB","IN_ACCESS")

    for ($i = 0; $i -lt 5600; $i++) {
        $ts = $base.AddSeconds($i * 10).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $evt = $events[$i % $events.Count]
        $user = if (($i % 4) -eq 0) { "deploy" } else { "opsadmin" }
        $lines.Add("$ts inotify node=lin-ssh-02 user=$user event=$evt path=/home/deploy/.ssh/authorized_keys")
    }

    $lines.Add("2026-03-08T09:14:26Z inotify node=lin-ssh-02 user=deploy event=IN_MODIFY path=/home/deploy/.ssh/authorized_keys")
    $lines.Add("2026-03-08T09:14:27Z inotify node=lin-ssh-02 user=deploy event=IN_CLOSE_WRITE path=/home/deploy/.ssh/authorized_keys")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SshAuthLog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $users = @("deploy","opsadmin","appsvc","backup")

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddSeconds($i * 8).ToString("MMM dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $acct = $users[$i % $users.Count]
        $ip = "10.$(44 + ($i % 20)).$((10 + $i) % 220).$((30 + $i) % 220)"
        $lines.Add("$ts lin-ssh-02 sshd[$(18000 + ($i % 900))]: Accepted publickey for $acct from $ip port $((31000 + $i) % 65000) ssh2 key_owner=trusted")
    }

    $lines.Add("Mar 08 09:15:01 lin-ssh-02 sshd[24119]: Accepted publickey for deploy from 203.0.113.88 port 49822 ssh2 key_owner=attacker")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-KeyFingerprintCatalog {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,fingerprint,owner,trust_level,notes")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $finger = "SHA256:{0}" -f ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("known_{0:D8}" -f $i))).TrimEnd("="))
        $owner = if (($i % 2) -eq 0) { "ops-team" } else { "devops" }
        $lines.Add("$ts,$finger,$owner,trusted,baseline catalog entry")
    }

    $lines.Add("2026-03-08T09:15:00Z,SHA256:q8zzot1XW8fVxW2OJgJ8Imh2MRYsSBA2ue6YV9w8wL4,attacker,untrusted,key not in approved owner roster")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SshKeyAlerts {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)
    $types = @("authorized_keys_watch","new_key_owner_watch","ssh_auth_correlation","file_integrity_watch")

    for ($i = 0; $i -lt 4300; $i++) {
        $entry = [ordered]@{
            timestamp_utc = $base.AddSeconds($i * 11).ToString("o")
            alert_id = "key-" + ("{0:D8}" -f (98000000 + $i))
            severity = if (($i % 167) -eq 0) { "medium" } else { "low" }
            type = $types[$i % $types.Count]
            status = "closed_noise"
            detail = "routine ssh key telemetry"
        }
        $lines.Add(($entry | ConvertTo-Json -Compress))
    }

    $lines.Add((([ordered]@{
        timestamp_utc = "2026-03-08T09:15:01Z"
        alert_id = "key-99911107"
        severity = "critical"
        type = "unauthorized_ssh_key_owner"
        status = "open"
        detail = "new unapproved ssh key owner observed in deploy authorized_keys"
        suspicious_key_owner = "attacker"
        node = "lin-ssh-02"
    }) | ConvertTo-Json -Compress))
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-SiemTimeline {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,event_type,system,severity,details")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-07T00:00:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 5000; $i++) {
        $ts = $base.AddSeconds($i * 9).ToString("o")
        $evt = if (($i % 251) -eq 0) { "ssh_key_review" } else { "routine_ssh_monitoring" }
        $sev = if ($evt -eq "ssh_key_review") { "medium" } else { "low" }
        $lines.Add("$ts,$evt,siem-ssh-01,$sev,ssh key baseline telemetry")
    }

    $lines.Add("2026-03-08T09:14:27Z,authorized_keys_modified,siem-ssh-01,high,new key appended to /home/deploy/.ssh/authorized_keys")
    $lines.Add("2026-03-08T09:15:01Z,unauthorized_key_owner_detected,siem-ssh-01,critical,suspicious key owner identified as attacker")
    $lines.Add("2026-03-08T09:15:08Z,incident_opened,siem-ssh-01,high,INC-2026-5510 unauthorized ssh key investigation")
    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-Policy {
    param([string]$OutputPath)

    $content = @'
SSH Key Management Policy (Excerpt)

1) Only approved key owners may be present in production authorized_keys.
2) Unauthorized key-owner names must be extracted and reported in triage.
3) New key append events require correlation with authentication activity.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

function New-Runbook {
    param([string]$OutputPath)

    $content = @'
Unauthorized SSH Key Triage Runbook (Excerpt)

1) Inspect authorized_keys snapshots and key inventory diffs.
2) Correlate file-integrity events and ssh auth acceptance records.
3) Resolve key fingerprint to key-owner identity from catalog/alerts.
4) Remove unauthorized key and rotate credentials.
'@
    Write-TextFile -Path $OutputPath -Content $content
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M5-10 Unauthorized SSH Key (Real-World Investigation Pack)

Scenario:
SOC monitoring detected suspicious modifications to a production account's authorized_keys file.

Task:
Analyze the investigation pack and identify the attacker key owner.

Flag format:
CTF{answer}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-5510
Severity: High
Queue: SOC + Linux Ops + IAM

Summary:
A new SSH key was appended to deploy account and quickly used for login from external source.

Scope:
- Node: lin-ssh-02
- Window: 2026-03-08 09:14 UTC
- Goal: identify attacker key owner
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Correlate key inventory, authorized_keys snapshot, file-integrity events, ssh auth logs, key fingerprint catalog, security alerts, SIEM timeline, and policy/runbook guidance.
- Determine the attacker key owner value.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

New-KeyInventory -OutputPath (Join-Path $bundleRoot "evidence\identity\ssh_key_inventory.csv")
New-AuthorizedKeysSnapshot -OutputPath (Join-Path $bundleRoot "evidence\identity\authorized_keys_snapshot.txt")
New-FileIntegrityEvents -OutputPath (Join-Path $bundleRoot "evidence\filesystem\authorized_keys_integrity.log")
New-SshAuthLog -OutputPath (Join-Path $bundleRoot "evidence\auth\sshd_auth.log")
New-KeyFingerprintCatalog -OutputPath (Join-Path $bundleRoot "evidence\identity\key_fingerprint_catalog.csv")
New-SshKeyAlerts -OutputPath (Join-Path $bundleRoot "evidence\security\ssh_key_alerts.jsonl")
New-SiemTimeline -OutputPath (Join-Path $bundleRoot "evidence\siem\timeline_events.csv")
New-Policy -OutputPath (Join-Path $bundleRoot "evidence\policy\ssh_key_management_policy.txt")
New-Runbook -OutputPath (Join-Path $bundleRoot "evidence\policy\unauthorized_ssh_key_triage_runbook.txt")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
