# M1-20 Instructor Notes

## Objective
- Train learners to investigate DNS amplification impact and map it to the CIA triad.
- Expected answer: `CTF{availability}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - target service: `dns-recursive-01`
   - window: `2026-03-06T09:44Z` onward
2. In `resolver_query.log`, identify suspicious query behavior:
   - burst of `qtype=ANY`
   - large `resp_bytes`
   - repeated suspicious source blocks
3. In `dns_netflow.csv`, confirm amplification-class inbound UDP/53 flows.
4. In `firewall_alerts.jsonl`, validate critical `DNS_AMP_FLOOD_DETECTED`.
5. In `resolver_health_timeseries.csv`, confirm service degradation:
   - extreme QPS surge
   - SERVFAIL/timeout growth
   - packet drops and high CPU
6. In `service_probes.csv`, confirm user-facing failures/timeouts.
7. In `change_records.csv`, verify no approved disruptive change causing the event.
8. Classify CIA impact.

## Key Indicators
- Query pivot: `qtype=ANY`
- Attack pivot: `dns-amplification-suspected` netflow class
- Alert pivot: `DNS_AMP_FLOOD_DETECTED`
- Impact pivots: probe `failed/timeout`, high SERVFAIL/timeout rates

## Suggested Commands / Tools
- `rg "qtype=ANY|amplification-pattern|DNS_AMP_FLOOD_DETECTED|timeout" evidence`
- CSV filtering in:
  - `dns_netflow.csv`
  - `resolver_health_timeseries.csv`
  - `service_probes.csv`
  - `change_records.csv`
- `jq` filtering on `firewall_alerts.jsonl` by `rule` and `severity`.
