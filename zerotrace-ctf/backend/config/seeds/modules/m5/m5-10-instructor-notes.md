# M5-10 Instructor Notes

## Objective
- Train learners to investigate unauthorized SSH key persistence and identify attacker key owner.
- Expected answer: `CTF{attacker}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5510`
   - node: `lin-ssh-02`
2. In `authorized_keys_snapshot.txt`, identify suspicious key comment entry.
3. In `ssh_key_inventory.csv`, locate unauthorized key-owner record.
4. In `key_fingerprint_catalog.csv`, map suspicious fingerprint to owner identity.
5. In `authorized_keys_integrity.log`, confirm key file modification timing.
6. In `sshd_auth.log`, confirm login acceptance using suspicious key owner.
7. In `ssh_key_alerts.jsonl` and `timeline_events.csv`, confirm normalized owner attribution.
8. Submit attacker key-owner value.

## Key Indicators
- Key-file pivot:
  - `attacker@evil`
- Inventory/fingerprint pivots:
  - `...,attacker,authorized_keys,unauthorized`
  - `...,attacker,untrusted,...`
- Auth pivot:
  - `Accepted publickey ... key_owner=attacker`
- Alert pivot:
  - `"suspicious_key_owner":"attacker"`
- SIEM pivot:
  - `unauthorized_key_owner_detected ... attacker`

## Suggested Commands / Tools
- `rg "attacker|authorized_keys|suspicious_key_owner|key_owner" evidence`
- Review:
  - `evidence/identity/authorized_keys_snapshot.txt`
  - `evidence/identity/ssh_key_inventory.csv`
  - `evidence/identity/key_fingerprint_catalog.csv`
  - `evidence/auth/sshd_auth.log`
