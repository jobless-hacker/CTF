# M3-01 Instructor Notes

## Objective
- Train learners to investigate a cloud-based data exposure and extract a specific leaked contact email.
- Expected answer: `CTF{bob@company.com}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - leaked object: `shared/public/customer_contacts_snapshot.csv`
   - incident window: around `2026-03-07 09:40-09:42 UTC`
2. In `object_listing.csv`, confirm object ACL is `public-read`.
3. In `public_share_access.log`, confirm external retrieval of leaked object.
4. In `dlp_exposure_alerts.jsonl`, confirm restricted-data exposure alerts.
5. In `crm_export_audit.csv`, verify export to public location was `not_approved`.
6. In `customer_contacts_snapshot.csv`, locate Bob's record and extract email.
7. Confirm timeline sequence in `timeline_events.csv`.
8. Return Bob's email as flag value.

## Key Indicators
- Leaked file: `customer_contacts_snapshot.csv`
- Governance issue: `not_approved` export destination
- Exposure signal: external bulk download from public path
- Target value: `bob@company.com`

## Suggested Commands / Tools
- `rg "customer_contacts_snapshot.csv|public-read|not_approved|bob@company.com" evidence`
- CSV filtering in:
  - `customer_contacts_snapshot.csv`
  - `object_listing.csv`
  - `crm_export_audit.csv`
  - `timeline_events.csv`
- `jq` high/critical filtering in `dlp_exposure_alerts.jsonl`.
