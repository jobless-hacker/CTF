# M9-06 Instructor Notes

## Objective
- Train learners to investigate location leakage from social media OSINT data.
- Expected answer: `CTF{hyderabad}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5906`
   - goal: identify leaked location
2. In `social_feed_export.csv` and `post_content.log`, locate target post (`post_9000123`).
3. In `hashtag_aggregation.log`, confirm `#Hyderabad` signal.
4. In `geo_inference.jsonl`, confirm high-confidence `hyderabad` inference for target.
5. In `entity_link_graph.csv`, validate landmark link (`Charminar`) for target post.
6. In `timeline_events.csv` and `threat_intel_snapshot.txt`, confirm final location.
7. Submit location.

## Key Indicators
- Post/landmark pivot:
  - `post_9000123`
  - `Charminar`
- Location pivot:
  - `hyderabad`
  - `#Hyderabad`
- SIEM pivot:
  - `location_confirmed`

## Suggested Commands / Tools
- `rg "post_9000123|Charminar|#Hyderabad|hyderabad|location_confirmed" evidence`
- Review:
  - `evidence/tweet.txt`
  - `evidence/osint/social_feed_export.csv`
  - `evidence/osint/post_content.log`
  - `evidence/osint/hashtag_aggregation.log`
  - `evidence/osint/geo_inference.jsonl`
  - `evidence/osint/entity_link_graph.csv`
  - `evidence/siem/timeline_events.csv`
  - `evidence/intel/threat_intel_snapshot.txt`
