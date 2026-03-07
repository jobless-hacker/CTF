param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-12-packet-replay-attack"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_12_realworld_build"
$bundleRoot = Join-Path $buildRoot $bundleName

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

function Write-LinesFile {
    param(
        [string]$Path,
        [System.Collections.Generic.List[string]]$Lines
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    [System.IO.File]::WriteAllLines($Path, $Lines, [System.Text.Encoding]::UTF8)
}

function New-ApiGatewayRequests {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:40:00", [DateTimeKind]::Utc)
    $nodes = @("api-gw-01","api-gw-02","api-gw-03")
    $clients = @("10.60.4.21","10.60.4.25","10.60.4.29","10.60.4.31","10.60.5.8")

    for ($i = 0; $i -lt 16200; $i++) {
        $ts = $base.AddMilliseconds($i * 240)
        $stamp = $ts.ToString("o")
        $node = $nodes[$i % $nodes.Count]
        $client = $clients[$i % $clients.Count]
        $order = "ORD-2026-$((4100 + ($i % 2600)))"
        $txn = 88000 + ($i % 5200)
        $idem = "pay-$order"
        $status = 200
        $note = "auth-approved"

        # benign duplicate attempt blocked by idempotency
        if (($i % 701) -eq 0) {
            $status = 409
            $note = "duplicate-blocked-idempotency-hit"
        }

        $lines.Add("$stamp $node POST /payments/authorize order=$order txn=$txn idem=$idem status=$status client=$client note=$note")
    }

    # Incident replay sequence
    $lines.Add("2026-03-06T12:15:01Z api-gw-02 POST /payments/authorize order=ORD-2026-4401 txn=99312 idem=pay-ord-2026-4401 status=200 client=10.60.4.25 note=auth-approved")
    $lines.Add("2026-03-06T12:15:03Z api-gw-02 POST /payments/authorize order=ORD-2026-4401 txn=99312 idem=pay-ord-2026-4401 status=200 client=10.60.4.25 note=auth-approved-replayed")
    $lines.Add("2026-03-06T12:15:05Z api-gw-02 POST /payments/authorize order=ORD-2026-4401 txn=99312 idem=pay-ord-2026-4401 status=200 client=10.60.4.25 note=auth-approved-replayed")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-AuthorizationEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,order_ref,transaction_id,idempotency_key,card_ref,amount,status,source_ip,processor_ref,processing_node,replay_score")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:40:00", [DateTimeKind]::Utc)
    $nodes = @("pay-core-01","pay-core-02","pay-core-03")

    for ($i = 0; $i -lt 9200; $i++) {
        $ts = $base.AddMilliseconds($i * 300).ToString("o")
        $order = "ORD-2026-$((4100 + ($i % 2600)))"
        $txn = 88000 + ($i % 5200)
        $idem = "pay-$order"
        $card = "card_$((6000 + ($i % 5000)).ToString('x'))"
        $amt = "{0:N2}" -f (199 + (($i * 7) % 1400))
        $status = if (($i % 643) -eq 0) { "duplicate_rejected" } else { "approved" }
        $ip = "10.60.4.$(20 + ($i % 40))"
        $pref = "gw-$((100000 + $i))"
        $node = $nodes[$i % $nodes.Count]
        $score = if ($status -eq "duplicate_rejected") { 82 } else { 3 + ($i % 7) }
        $lines.Add("$ts,$order,$txn,$idem,$card,$amt,$status,$ip,$pref,$node,$score")
    }

    $lines.Add("2026-03-06T12:15:01Z,ORD-2026-4401,99312,pay-ord-2026-4401,card_81a4,499.00,approved,10.60.4.25,gw-inc-001,pay-core-02,94")
    $lines.Add("2026-03-06T12:15:03Z,ORD-2026-4401,99312,pay-ord-2026-4401,card_81a4,499.00,approved,10.60.4.25,gw-inc-002,pay-core-02,95")
    $lines.Add("2026-03-06T12:15:05Z,ORD-2026-4401,99312,pay-ord-2026-4401,card_81a4,499.00,approved,10.60.4.25,gw-inc-003,pay-core-02,96")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-LedgerEvents {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,ledger_id,order_ref,transaction_id,event_type,amount,currency,status,source_system")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:40:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 7600; $i++) {
        $ts = $base.AddMilliseconds($i * 360).ToString("o")
        $ledger = "LED-$((300000 + $i))"
        $order = "ORD-2026-$((4100 + ($i % 2600)))"
        $txn = 88000 + ($i % 5200)
        $etype = if (($i % 2) -eq 0) { "debit_reserved" } else { "debit_captured" }
        $amt = "{0:N2}" -f (199 + (($i * 5) % 1400))
        $status = "posted"
        $lines.Add("$ts,$ledger,$order,$txn,$etype,$amt,INR,$status,payment-ledger")
    }

    # Incident duplicate postings
    $lines.Add("2026-03-06T12:15:01Z,LED-INC-9001,ORD-2026-4401,99312,debit_reserved,499.00,INR,posted,payment-ledger")
    $lines.Add("2026-03-06T12:15:03Z,LED-INC-9002,ORD-2026-4401,99312,debit_reserved,499.00,INR,posted,payment-ledger")
    $lines.Add("2026-03-06T12:15:05Z,LED-INC-9003,ORD-2026-4401,99312,debit_reserved,499.00,INR,posted,payment-ledger")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

function New-IdempotencyAndCache {
    param(
        [string]$ControlPath,
        [string]$CachePath,
        [string]$FailoverPath
    )

    $control = @'
Payment API Control Note

Endpoint: POST /payments/authorize
Control requirement: transaction_id and Idempotency-Key must be unique per authorization attempt.
Expected duplicate handling: repeated keys for the same order must return the original result and must not create additional debit events.
Retention window: 24 hours
Storage backend: redis-idem-cluster
'@
    Write-TextFile -Path $ControlPath -Content $control

    $cache = New-Object System.Collections.Generic.List[string]
    $cache.Add("timestamp_utc,idempotency_key,cache_node,status,ttl_seconds,eviction_reason,order_ref")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:30:00", [DateTimeKind]::Utc)
    $nodes = @("redis-idem-01","redis-idem-02","redis-idem-03")

    for ($i = 0; $i -lt 6100; $i++) {
        $ts = $base.AddSeconds($i * 2).ToString("o")
        $order = "ORD-2026-$((4100 + ($i % 2600)))"
        $key = "pay-$order"
        $node = $nodes[$i % $nodes.Count]
        $status = if (($i % 53) -eq 0) { "expired" } else { "present" }
        $ttl = if ($status -eq "present") { 600 + (($i * 3) % 18000) } else { 0 }
        $reason = if ($status -eq "expired") { "normal_ttl_expiry" } else { "" }
        $cache.Add("$ts,$key,$node,$status,$ttl,$reason,$order")
    }

    # Incident cache key eviction
    $cache.Add("2026-03-06T12:14:58Z,pay-ord-2026-4401,redis-idem-02,evicted,0,failover_resync,ORD-2026-4401")
    $cache.Add("2026-03-06T12:15:00Z,pay-ord-2026-4401,redis-idem-02,missing,0,cache_miss_after_failover,ORD-2026-4401")
    Write-LinesFile -Path $CachePath -Lines $cache

    $fail = New-Object System.Collections.Generic.List[string]
    $baseFail = [datetime]::SpecifyKind([datetime]"2026-03-06T11:50:00", [DateTimeKind]::Utc)
    for ($i = 0; $i -lt 2400; $i++) {
        $ts = $baseFail.AddMilliseconds($i * 700).ToString("o")
        $msg = if (($i % 81) -eq 0) { "replica sync delay detected" } else { "cluster heartbeat ok" }
        $fail.Add("$ts redis-idem-cluster INFO $msg")
    }
    $fail.Add("2026-03-06T12:14:57Z redis-idem-cluster WARN leader election in progress due to network partition")
    $fail.Add("2026-03-06T12:14:58Z redis-idem-cluster WARN volatile key eviction burst triggered on redis-idem-02")
    $fail.Add("2026-03-06T12:15:00Z redis-idem-cluster INFO failover complete, cache warmup pending")
    Write-LinesFile -Path $FailoverPath -Lines $fail
}

function New-SecurityFindings {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp_utc,source,event_type,severity,entity,status,note")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-06T11:40:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 6900; $i++) {
        $ts = $base.AddSeconds($i * 3).ToString("o")
        $etype = if (($i % 17) -eq 0) { "suspicious_payment_retry" } else { "normal_payment_authorization" }
        $sev = if ($etype -eq "suspicious_payment_retry") { 28 } else { 5 }
        $status = if ($etype -eq "suspicious_payment_retry") { "closed_false_positive" } else { "informational" }
        $note = if ($etype -eq "suspicious_payment_retry") { "mobile-client retry pattern, idempotency blocked" } else { "normal flow" }
        $lines.Add("$ts,fraud-engine,$etype,$sev,payment-api,$status,$note")
    }

    $lines.Add("2026-03-06T12:15:06Z,fraud-engine,replay_signature_detected,92,ORD-2026-4401,open,repeated successful auth for same transaction_id and idempotency_key")
    $lines.Add("2026-03-06T12:15:07Z,siem,ledger_duplicate_debit_posting,94,txn-99312,open,multiple debit_reserved postings for single order")
    $lines.Add("2026-03-06T12:15:08Z,payment-core,idempotency_cache_bypass,90,redis-idem-02,open,key evicted during failover before replay window closed")

    Write-LinesFile -Path $OutputPath -Lines $lines
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-12 Repeated Payment Authorizations (Real-World Investigation Pack)

Scenario:
A payment workflow produced multiple successful authorizations for one order.
Evidence includes API gateway request logs, payment authorization records, ledger postings,
idempotency cache state, cache failover logs, and fraud/SIEM findings.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4486
Severity: High
Queue: Payment Fraud Monitoring + AppSec

Summary:
Fraud detection observed repeated successful payment authorizations for a single order/transaction.
Expected idempotency controls appear to have failed for a short interval.

Scope:
- Order: ORD-2026-4401
- Transaction ID: 99312
- Window: 2026-03-06 12:15:01Z - 12:15:05Z

Deliverable:
Classify the primary CIA impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$handoff = @'
Analyst handoff:
- Normal payment retries are common and often blocked by idempotency.
- Correlate order/transaction/idempotency key across gateway, auth, and ledger records.
- Validate cache behavior around the incident window before concluding replay impact.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_handoff.txt") -Content $handoff

$fraud = @'
Fraud analyst summary:
- Replay pattern confidence: high
- Duplicate authorization count for txn 99312: 3
- Distinct authorization references: gw-inc-001, gw-inc-002, gw-inc-003
- Recommended action: reverse duplicate debits and rotate replay-protection nonce keys
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\security\fraud_alert_summary.txt") -Content $fraud

New-ApiGatewayRequests -OutputPath (Join-Path $bundleRoot "evidence\network\api_gateway_requests.log")
New-AuthorizationEvents -OutputPath (Join-Path $bundleRoot "evidence\payments\authorization_events.csv")
New-LedgerEvents -OutputPath (Join-Path $bundleRoot "evidence\payments\transaction_ledger.csv")
New-IdempotencyAndCache -ControlPath (Join-Path $bundleRoot "evidence\payments\idempotency_control.txt") -CachePath (Join-Path $bundleRoot "evidence\payments\idempotency_cache_state.csv") -FailoverPath (Join-Path $bundleRoot "evidence\operations\cache_failover.log")
New-SecurityFindings -OutputPath (Join-Path $bundleRoot "evidence\security\normalized_findings.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
