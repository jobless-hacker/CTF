# M2-03 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Unknown process detection and triage in production endpoint telemetry.
- Task target: identify the suspicious process name.

### Learning Outcome
- Correlate process identity with behavior (CPU, network, reputation).
- Validate findings against approved runtime baseline.
- Separate benign unsigned exceptions from malicious execution.

### Previous Artifact Weaknesses
- Single process list with low investigative depth.
- No resource/network/EDR/reputation context.
- Minimal noise and little SOC realism.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. MITRE ATT&CK T1059 / T1105 / T1496 (execution, download, resource hijacking):  
   https://attack.mitre.org/techniques/T1059/  
   https://attack.mitre.org/techniques/T1105/  
   https://attack.mitre.org/techniques/T1496/
2. NIST SP 800-61 incident analysis workflow:  
   https://csrc.nist.gov/pubs/sp/800/61/r2/final
3. Linux process and system telemetry investigation practices (host + network + hash reputation correlation).

### Key Signals Adopted
- Unknown process name `cryptominer` absent from approved baseline.
- Parent-chain evidence shows download + execute flow from `/tmp/.xmr/`.
- Sustained >95% CPU and abnormal outbound connection to mining-pool port `4444`.
- EDR critical cryptomining behavior detection.
- Hash reputation marked malicious with high detections.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `process_snapshot.csv` (**8,604 lines**) host process telemetry.
- `process_creation.log` (**7,603 lines**) process-chain evidence.
- `resource_usage_timeseries.csv` (**5,404 lines**) CPU/memory behavior.
- `process_connections.csv` (**5,104 lines**) per-process network context.
- `edr_process_alerts.jsonl` (**3,902 lines**) endpoint detection stream.
- `hash_reputation.csv` (**2,402 lines**) reputation and detection context.
- `approved_runtime_baseline.txt` (**12 lines**) policy baseline.
- Briefing files.

Realism upgrades:
- Multi-source endpoint + network + detection + policy evidence.
- High-volume baseline telemetry with benign noise.
- Explicit behavioral triage path, not static process-name guessing.

## Step 4 - Flag Engineering

Expected investigation path:
1. Start from ticket and isolate incident window.
2. Find out-of-baseline process in snapshot.
3. Confirm execution chain and origin path in process creation logs.
4. Validate resource-hijacking behavior and mining-pool network flows.
5. Confirm EDR and hash-reputation malicious signals.
6. Return suspicious process name.

Expected answer:
- `CTF{cryptominer}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m2/m2-03-unknown-process.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for process-name pivots across files.
- CSV filtering for CPU/memory/network behavior by PID.
- `jq` for EDR critical-signal extraction.
