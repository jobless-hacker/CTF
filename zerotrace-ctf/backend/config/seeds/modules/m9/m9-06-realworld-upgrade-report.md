# M9-06 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Social media OSINT leak investigation with location attribution.
- Task target: identify location mentioned in suspicious public post.

### Learning Outcome
- Correlate direct post text with hashtag and inference telemetry.
- Filter high-noise social feed data to isolate target post context.
- Validate final location via SIEM normalized event trail.

### Previous Artifact Weaknesses
- Single post artifact exposed answer directly.
- No realistic social monitoring pipeline noise.
- Missing cross-source confidence validation workflow.

## Step 2 - Real-World Artifact Investigation

Reference patterns used:

1. Large social feed exports from continuous ingest pipelines.
2. Post content logs and hashtag aggregation records.
3. Geolocation inference output with confidence scoring.
4. SIEM timeline confirmation for final location attribution.

### Key Signals Adopted
- Target post references `Charminar` and `#Hyderabad`.
- Geolocation inference resolves target post location to `hyderabad`.
- SIEM timeline confirms final location event.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `social_feed_export.csv` (**6,802 lines**) noisy cross-platform post summary with target row.
- `post_content.log` (**7,201 lines**) content pipeline logs including target message line.
- `hashtag_aggregation.log` (**5,401 lines**) hashtag signal stream with `#Hyderabad` spike.
- `geo_inference.jsonl` (**5,601 lines**) geo model outputs with high-confidence target record.
- `entity_link_graph.csv` (**5,002 lines**) semantic link graph including `Charminar` pivot.
- `timeline_events.csv` (**5,103 lines**) SIEM confirmations and answer-ready event.
- `tweet.txt` direct low-fidelity clue.
- Incident briefing, case notes, and intel snapshot.

Realism upgrades:
- High-volume social OSINT pipeline noise with one true signal path.
- Multi-source corroboration required before answer extraction.
- Mimics practical SOC/open-source investigations.

## Step 4 - Flag Engineering

Expected investigation path:
1. Read incident context (`INC-2026-5906`).
2. Locate target post in feed/content logs.
3. Correlate hashtags, landmark linkage, and geo inference results.
4. Confirm location in SIEM timeline/intel notes.
5. Submit location value.

Expected answer:
- `CTF{hyderabad}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m9/m9-06-social-media-leak.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` pivots: `Charminar`, `#Hyderabad`, `post_9000123`, `location_confirmed`.
- Validate location through direct content plus model/siem outputs.
