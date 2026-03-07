# M1-03 Instructor Notes

## Objective
- Train learners to detect unauthorized data mutation in financial systems.
- Expected answer: `CTF{integrity}`.

## Expected Investigation Path
1. Start with `incident_ticket.txt` and incident window.
2. Validate mismatch in `record_before.sql.txt` vs `record_after.sql.txt`.
3. Search `mysql_audit_events.jsonl` for:
   - `account_id = 88314`
   - actor `web_admin`
   - source IP `10.44.18.25`
4. Correlate with CDC event in `debezium_customer_wallets.jsonl`:
   - `op = "u"`
   - `before.balance = 1200`
   - `after.balance = 90000`
5. Confirm forensic consistency with `mysqlbinlog_decoded_excerpt.txt`.
6. Validate SIEM risk context in `db_events_normalized.csv` (high-risk mutation analytics).
7. Classify primary CIA impact.

## Key Indicators
- Target account: `88314`
- Value delta: `1200.00` -> `90000.00`
- Actor: `web_admin`
- Source: `10.44.18.25`
- Binlog thread/position around `00:03:19Z`

## Suggested Commands / Tools
- `rg "88314|web_admin|90000.00" mysql_audit_events.jsonl db_events_normalized.csv`
- `jq -c 'select(.after.account_id==88314)' debezium_customer_wallets.jsonl`
- `rg "Update_rows|account_id|90000.00" mysqlbinlog_decoded_excerpt.txt`
- Timeline pivot in spreadsheet/SIEM on `timestamp` + `db_user` + `src_ip`

