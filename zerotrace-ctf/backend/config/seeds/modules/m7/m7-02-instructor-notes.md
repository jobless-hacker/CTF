# M7-02 Instructor Notes

## Objective
- Train learners to identify reflected script attack type from web/app/client evidence.
- Expected answer: `CTF{xss}`.

## Expected Investigation Path
1. Read `incident_ticket.txt` and `analyst_handoff.txt`:
   - incident: `INC-2026-5702`
   - endpoint: `/search`
2. In `request_log.txt` and `access.log`, locate script payload in query parameter.
3. In `render.log` and `response_snapshot.txt`, confirm payload is reflected unsanitized.
4. In `browser_console.log`, verify script execution indicators.
5. In `waf.log`, `web_attack_alerts.jsonl`, and `timeline_events.csv`, confirm final attack classification.
6. Submit attack type.

## Key Indicators
- Request/access pivot:
  - `/search?q=<script>alert(1)</script>`
- Render pivot:
  - `render_mode=raw term="<script>alert(1)</script>"`
- Response pivot:
  - `You searched for: <script>alert(1)</script>`
- WAF/Alert pivot:
  - `msg="XSS Attack Detected"`
  - `"attack_type":"xss"`
- SIEM pivot:
  - `attack_classified ... xss`

## Suggested Commands / Tools
- `rg "<script>alert\\(1\\)</script>|render_mode=raw|attack_type|attack_classified|xss" evidence`
- Review:
  - `evidence/network/request_log.txt`
  - `evidence/network/access.log`
  - `evidence/application/render.log`
  - `evidence/application/response_snapshot.txt`
  - `evidence/network/waf.log`
  - `evidence/client/browser_console.log`
  - `evidence/security/web_attack_alerts.jsonl`
  - `evidence/siem/timeline_events.csv`
