# M1-14 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Container deployment misconfiguration causing unintended database exposure.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Detect network exposure caused by container port-binding drift.
- Correlate config change, host listening state, and external verification.
- Separate expected public services from unexpected sensitive service exposure.

### Previous Artifact Weaknesses
- Small evidence set and straightforward answer path.
- Limited noise/false positives in network exposure context.
- Minimal change-management correlation.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. Docker Compose `ports` directive behavior:  
   https://docs.docker.com/reference/compose-file/services/#ports
2. Docker Engine port publishing and host exposure model:  
   https://docs.docker.com/engine/network/port-publishing/
3. Linux `ss` socket-inspection utility reference:  
   https://man7.org/linux/man-pages/man8/ss.8.html
4. Nmap scan interpretation basics (open-service verification):  
   https://nmap.org/book/man-port-scanning-basics.html
5. CIS Docker benchmark context for minimizing exposed services:  
   https://www.cisecurity.org/benchmark/docker
6. NIST SP 800-190 (application container security guidance):  
   https://csrc.nist.gov/pubs/sp/800/190/final

### Key Signals Adopted
- Compose diff from `127.0.0.1:3306:3306` to `3306:3306`.
- Docker runtime event showing publish on `0.0.0.0:3306`.
- Host LISTEN state and external scan confirming DB reachability.
- Governance alert + missing approved change for DB exposure.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `docker_events.log` (**8,404 lines**) container-runtime activity.
- `ss_listening_timeseries.csv` (**6,204 lines**) host socket state timeline.
- `external_scan_results.csv` (**4,603 lines**) external verification telemetry.
- `flow_telemetry.csv` (**9,204 lines**) network flow context.
- `governance_findings.csv` (**6,102 lines**) control findings with noise.
- `change_log.csv` (**1,702 lines**) approved vs draft change context.
- Compose baseline/current files + diff patch + incident briefing.

Realism upgrades:
- Multi-source infra/network evidence.
- High-volume logs with benign open-port noise.
- False positives and approved-public-service context.
- Change-control validation before final classification.

## Step 4 - Flag Engineering

Expected investigation path:
1. Confirm compose drift exposes DB port on all interfaces.
2. Validate runtime publish and host LISTEN evidence.
3. Confirm external reachability and external flow attempts.
4. Verify governance finding and lack of approved change.
5. Classify primary CIA impact.

Expected flag:
- `CTF{confidentiality}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-14-docker-misconfiguration.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for port-binding and exposure pivots.
- CSV filtering for timestamp-based correlation.
- Diff review of baseline vs current compose file.
