# M1-03 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Unauthorized modification of critical financial data.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Validate data tampering by correlating multiple evidence layers.
- Separate benign operational writes from malicious record mutation.
- Use change evidence (`before/after`) to classify security impact.

### Previous Artifact Weaknesses
- Small, low-noise dataset.
- Minimal source diversity.
- Easy answer path from one audit line without correlation.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MySQL Enterprise Audit log format and JSON event structures:  
   https://dev.mysql.com/doc/refman/8.0/en/audit-log-format.html
2. MySQL binary log inspection (`mysqlbinlog`) and row-update decoding:  
   https://dev.mysql.com/doc/refman/8.0/en/mysqlbinlog.html
3. AWS RDS Database Activity Streams event shape (managed DB activity telemetry):  
   https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/DBActivityStreams.html
4. Debezium change-event envelope (`before`, `after`, `op`, `source`, `ts_ms`):  
   https://debezium.io/documentation/reference/stable/connectors/mysql.html
5. OWASP logging guidance for integrity-relevant audit events:  
   https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html

### Key Signals Adopted
- High-volume DB audit stream with mixed benign events.
- CDC record showing explicit `before` and `after` value mutation.
- Binlog decoded row-update event with thread/position correlation.
- SIEM normalized high-risk mutation analytics.

## Step 3 - Artifact Design Upgrade

Upgraded artifact pack includes:
- `mysql_audit_events.jsonl` (**10,831 lines**) noisy DB audit stream.
- `debezium_customer_wallets.jsonl` (**1,801 lines**) CDC events.
- `db_events_normalized.csv` (**4,303 lines**) SIEM normalized events.
- `mysqlbinlog_decoded_excerpt.txt` binlog forensic pivot.
- Snapshot query outputs (`record_before.sql.txt`, `record_after.sql.txt`).
- Reconciliation alert + actor baseline profile + analyst notes.

Realism upgrades:
- Noisy nightly jobs and benign update bursts.
- Multiple users and source IPs.
- High-value outlier mutation embedded in large telemetry.
- Cross-source time correlation path.

## Step 4 - Flag Engineering

Expected path:
1. Confirm account-value mutation in before/after snapshots.
2. Locate actor/source in audit stream.
3. Confirm same mutation in CDC `before/after`.
4. Validate with binlog decode and SIEM risk analytics.
5. Map primary CIA impact.

Expected flag:
- `CTF{integrity}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-03-modified-database-record.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for account ID and actor pivots.
- `jq` for JSONL filtering (`op=="u"` and account-specific events).
- Spreadsheet/SIEM filters for risk-score pivots.
- Optional SQL-like analysis in notebook for timeline joins.

