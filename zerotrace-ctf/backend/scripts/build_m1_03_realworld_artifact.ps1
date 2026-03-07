param()

$ErrorActionPreference = "Stop"

$bundleName = "m1-03-modified-database-record"
$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\m1"
$artifactRoot = [System.IO.Path]::GetFullPath($artifactRoot)
$zipPath = Join-Path $artifactRoot ($bundleName + ".zip")
$buildRoot = Join-Path $env:TEMP "m1_03_realworld_build"
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

function New-MySqlAuditEvents {
    param([string]$OutputPath)

    $rows = New-Object System.Collections.Generic.List[string]
    $baseUtc = [datetime]::SpecifyKind([datetime]"2026-03-05T22:30:00", [DateTimeKind]::Utc)

    $users = @("batch_recon","ops_reconciler","report_worker","billing_job","api_reader")
    $sourceIps = @("10.44.10.11","10.44.10.12","10.44.12.22","10.44.14.6","10.44.14.8")
    $tables = @("customer_wallets","payments","ledger_entries","settlement_batches","audit_health")
    $db = "fin_core"

    for ($i = 0; $i -lt 10800; $i++) {
        $ts = $baseUtc.AddSeconds($i * 2).ToString("yyyy-MM-dd HH:mm:ss")
        $user = $users[$i % $users.Count]
        $srcIp = $sourceIps[$i % $sourceIps.Count]
        $table = $tables[$i % $tables.Count]
        $event = if (($i % 17) -eq 0) { "update" } elseif (($i % 5) -eq 0) { "read" } else { "insert" }
        $sql = if ($event -eq "read") {
            "SELECT account_id, balance FROM $table WHERE account_id = $([int](50000 + ($i % 3000)));"
        } elseif ($event -eq "insert") {
            "INSERT INTO audit_health(run_id, status) VALUES('$([guid]::NewGuid().ToString().Substring(0,8))','ok');"
        } else {
            "UPDATE $table SET updated_at = NOW() WHERE account_id = $([int](50000 + ($i % 3000)));"
        }

        $obj = [ordered]@{
            timestamp = $ts
            id = $i
            class = "table_access_data"
            event = $event
            connection_id = 1200 + ($i % 200)
            status = 0
            account = [ordered]@{
                user = $user
                host = "app-server.internal"
            }
            login = [ordered]@{
                ip = $srcIp
                os = "Linux"
                user = $user
            }
            db = $db
            table = $table
            sqltext = $sql
        }
        $rows.Add(($obj | ConvertTo-Json -Depth 8 -Compress))
    }

    # False-positive suspicious but benign update burst
    for ($j = 0; $j -lt 22; $j++) {
        $obj = [ordered]@{
            timestamp = ([datetime]::SpecifyKind([datetime]"2026-03-06T00:01:00", [DateTimeKind]::Utc).AddSeconds($j * 2)).ToString("yyyy-MM-dd HH:mm:ss")
            id = 200000 + $j
            class = "table_access_data"
            event = "update"
            connection_id = 3331
            status = 0
            account = [ordered]@{
                user = "ops_reconciler"
                host = "recon-job.internal"
            }
            login = [ordered]@{
                ip = "10.44.10.12"
                os = "Linux"
                user = "ops_reconciler"
            }
            db = "fin_core"
            table = "settlement_batches"
            sqltext = "UPDATE settlement_batches SET status='reconciled' WHERE batch_date='2026-03-05';"
        }
        $rows.Add(($obj | ConvertTo-Json -Depth 8 -Compress))
    }

    # True malicious integrity-altering update
    $rows.Add((([ordered]@{
        timestamp = "2026-03-06 00:03:19"
        id = 900001
        class = "table_access_data"
        event = "update"
        connection_id = 4177
        status = 0
        account = [ordered]@{
            user = "web_admin"
            host = "unknown-client"
        }
        login = [ordered]@{
            ip = "10.44.18.25"
            os = "Linux"
            user = "web_admin"
        }
        db = "fin_core"
        table = "customer_wallets"
        sqltext = "UPDATE customer_wallets SET balance = 90000.00, last_updated_by='web_admin' WHERE account_id = 88314;"
    }) | ConvertTo-Json -Depth 8 -Compress))

    # Follow-up reads
    for ($k = 0; $k -lt 8; $k++) {
        $obj = [ordered]@{
            timestamp = ([datetime]::SpecifyKind([datetime]"2026-03-06T00:03:23", [DateTimeKind]::Utc).AddSeconds($k * 3)).ToString("yyyy-MM-dd HH:mm:ss")
            id = 900010 + $k
            class = "table_access_data"
            event = "read"
            connection_id = 4177
            status = 0
            account = [ordered]@{
                user = "web_admin"
                host = "unknown-client"
            }
            login = [ordered]@{
                ip = "10.44.18.25"
                os = "Linux"
                user = "web_admin"
            }
            db = "fin_core"
            table = "customer_wallets"
            sqltext = "SELECT account_id,balance,last_updated_by FROM customer_wallets WHERE account_id = 88314;"
        }
        $rows.Add(($obj | ConvertTo-Json -Depth 8 -Compress))
    }

    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [System.IO.File]::WriteAllLines($OutputPath, $rows, [System.Text.Encoding]::UTF8)
}

function New-DebeziumCdcEvents {
    param([string]$OutputPath)

    $rows = New-Object System.Collections.Generic.List[string]
    $baseUtc = [datetime]::SpecifyKind([datetime]"2026-03-05T23:30:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 1800; $i++) {
        $acct = 50000 + ($i % 3000)
        $beforeBal = [math]::Round((800 + (($i * 7) % 2200)) + 0.00, 2)
        $afterBal = [math]::Round($beforeBal + (($i % 2) * 15.50), 2)
        $op = if (($i % 9) -eq 0) { "u" } else { "r" }

        $event = [ordered]@{
            op = $op
            ts_ms = [int64](($baseUtc.AddSeconds($i * 3) - [datetime]'1970-01-01').TotalMilliseconds)
            source = [ordered]@{
                connector = "mysql"
                db = "fin_core"
                table = "customer_wallets"
                file = "mysql-bin.002341"
                pos = 500000 + ($i * 83)
                server_id = 3342
            }
            before = if ($op -eq "u") {
                [ordered]@{
                    account_id = $acct
                    balance = $beforeBal
                    last_updated_by = "batch_recon"
                }
            } else { $null }
            after = [ordered]@{
                account_id = $acct
                balance = if ($op -eq "u") { $afterBal } else { $beforeBal }
                last_updated_by = "batch_recon"
            }
        }
        $rows.Add(($event | ConvertTo-Json -Depth 10 -Compress))
    }

    # malicious CDC change event
    $mal = [ordered]@{
        op = "u"
        ts_ms = 1772755399000
        source = [ordered]@{
            connector = "mysql"
            db = "fin_core"
            table = "customer_wallets"
            file = "mysql-bin.002341"
            pos = 991223
            server_id = 3342
            thread = 4177
        }
        before = [ordered]@{
            account_id = 88314
            balance = 1200.00
            last_updated_by = "batch_recon"
        }
        after = [ordered]@{
            account_id = 88314
            balance = 90000.00
            last_updated_by = "web_admin"
        }
    }
    $rows.Add(($mal | ConvertTo-Json -Depth 10 -Compress))

    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [System.IO.File]::WriteAllLines($OutputPath, $rows, [System.Text.Encoding]::UTF8)
}

function New-SiemNormalizedCsv {
    param([string]$OutputPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("timestamp,source,db_user,src_ip,action,target_table,rows_affected,risk_score,analytic")
    $base = [datetime]::SpecifyKind([datetime]"2026-03-05T23:50:00", [DateTimeKind]::Utc)

    for ($i = 0; $i -lt 4300; $i++) {
        $ts = $base.AddSeconds($i).ToString("o")
        $user = if (($i % 31) -eq 0) { "ops_reconciler" } else { "batch_recon" }
        $ip = if ($user -eq "ops_reconciler") { "10.44.10.12" } else { "10.44.10.11" }
        $table = if (($i % 15) -eq 0) { "settlement_batches" } else { "customer_wallets" }
        $action = if (($i % 8) -eq 0) { "UPDATE" } else { "SELECT" }
        $risk = if ($action -eq "UPDATE") { 32 } else { 12 }
        $analytic = if ($action -eq "UPDATE") { "db_write_volume_baseline" } else { "db_read_normal" }
        $lines.Add("$ts,mysql_audit,$user,$ip,$action,$table,1,$risk,$analytic")
    }

    # malicious record
    $lines.Add("2026-03-06T00:03:19Z,mysql_audit,web_admin,10.44.18.25,UPDATE,customer_wallets,1,96,high_value_balance_mutation")
    $lines.Add("2026-03-06T00:03:20Z,cdc_stream,web_admin,10.44.18.25,UPDATE,customer_wallets,1,98,before_after_delta_anomaly")

    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.Encoding]::UTF8)
}

Remove-Item -Recurse -Force $buildRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "evidence") | Out-Null

$description = @'
Challenge: M1-03 Modified Database Record (Real-World Investigation Pack)

Scenario:
Finance reconciliation flagged a wallet-balance anomaly. The pack contains production-style DB telemetry:
high-volume MySQL audit events, CDC stream output, SIEM-normalized event feed, binlog decode excerpt,
and reconciliation alerts.

Task:
Investigate the evidence and determine which CIA pillar was primarily violated.

Flag format:
CTF{pillar}
'@
Write-TextFile -Path (Join-Path $bundleRoot "description.txt") -Content $description

$ticket = @'
Incident: INC-2026-4427
Severity: Critical
Queue: Fraud Analytics + Database Security

Summary:
A single account balance changed from expected value to an outlier amount during reconciliation.
Multiple noisy write events exist from nightly jobs and can create false positives.

Scope:
- Database: fin_core
- Table: customer_wallets
- Account under review: 88314
- Window: 2026-03-05 23:55 UTC to 2026-03-06 00:10 UTC

Deliverable:
Classify primary CIA impact from evidence.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\incident_ticket.txt") -Content $ticket

$notes = @'
Analyst notes:
- Do not rely on a single source. Correlate audit logs, CDC events, and reconciliation/siem feeds.
- Nightly jobs update settlement metadata at high volume and are usually benign.
- Focus on value-changing updates in customer_wallets and actor/source context.
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\briefing\analyst_notes.txt") -Content $notes

$before = @'
mysql> SELECT account_id, customer_name, balance, last_updated_by, last_updated_at
    -> FROM customer_wallets
    -> WHERE account_id = 88314;

+------------+---------------+---------+-----------------+---------------------+
| account_id | customer_name | balance | last_updated_by | last_updated_at     |
+------------+---------------+---------+-----------------+---------------------+
| 88314      | Alex M        | 1200.00 | batch_recon     | 2026-03-05 23:58:14 |
+------------+---------------+---------+-----------------+---------------------+
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\database\record_before.sql.txt") -Content $before

$after = @'
mysql> SELECT account_id, customer_name, balance, last_updated_by, last_updated_at
    -> FROM customer_wallets
    -> WHERE account_id = 88314;

+------------+---------------+----------+-----------------+---------------------+
| account_id | customer_name | balance  | last_updated_by | last_updated_at     |
+------------+---------------+----------+-----------------+---------------------+
| 88314      | Alex M        | 90000.00 | web_admin       | 2026-03-06 00:03:19 |
+------------+---------------+----------+-----------------+---------------------+
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\database\record_after.sql.txt") -Content $after

$binlog = @'
mysqlbinlog --base64-output=DECODE-ROWS -vv mysql-bin.002341

# at 990988
# 2026-03-06T00:03:19.112001Z server id 3342 end_log_pos 991145 CRC32 0x91efc112 Query thread_id=4177 exec_time=0 error_code=0
SET TIMESTAMP=1772755399/*!*/;
BEGIN
/*!*/;
# at 991145
# 2026-03-06T00:03:19.113004Z server id 3342 end_log_pos 991223 CRC32 0xa72bc181 Table_map: `fin_core`.`customer_wallets` mapped to number 818
# at 991223
# 2026-03-06T00:03:19.113990Z server id 3342 end_log_pos 991331 CRC32 0x9c2273ab Update_rows: table id 818 flags: STMT_END_F
### UPDATE `fin_core`.`customer_wallets`
### WHERE
###   @1=88314 /* account_id */
###   @4=1200.00 /* balance */
###   @7='batch_recon' /* last_updated_by */
### SET
###   @4=90000.00 /* balance */
###   @7='web_admin' /* last_updated_by */
# at 991331
# 2026-03-06T00:03:19.114501Z server id 3342 end_log_pos 991362 CRC32 0x11194faa Xid = 908221
COMMIT/*!*/;
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\binlog\mysqlbinlog_decoded_excerpt.txt") -Content $binlog

$recon = @'
Fraud Reconciliation Alert

Account: 88314
Expected ledger total: 1200.00
Observed wallet balance: 90000.00
Related payment transaction: not found
Anomaly score: 97/100
Engine notes: detected outlier delta and actor mismatch against normal update profile
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\recon\reconciliation_alert.txt") -Content $recon

$profile = @'
db_user,typical_source_ips,typical_actions,high_risk_tables
batch_recon,10.44.10.11|10.44.10.12,SELECT|UPDATE(settlement metadata),settlement_batches
ops_reconciler,10.44.10.12,UPDATE(settlement metadata),settlement_batches
web_admin,10.44.16.5,SELECT(admin dashboard),none
'@
Write-TextFile -Path (Join-Path $bundleRoot "evidence\recon\actor_baseline_profile.csv") -Content $profile

New-MySqlAuditEvents -OutputPath (Join-Path $bundleRoot "evidence\database\mysql_audit_events.jsonl")
New-DebeziumCdcEvents -OutputPath (Join-Path $bundleRoot "evidence\cdc\debezium_customer_wallets.jsonl")
New-SiemNormalizedCsv -OutputPath (Join-Path $bundleRoot "evidence\siem\db_events_normalized.csv")

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleRoot "*") -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $buildRoot

Get-Item $zipPath | Select-Object FullName, Length, LastWriteTime
