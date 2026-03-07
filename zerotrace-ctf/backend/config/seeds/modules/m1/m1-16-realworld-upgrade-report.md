# M1-16 Real-World Artifact Upgrade Report

## Step 1 - Current Challenge Understanding

### Security Concept
- Sensitive data exposure via API response-shape drift on a public endpoint.
- CIA mapping target: identify the **primary impacted pillar**.

### Learning Outcome
- Correlate API gateway access, token scope, response payload shape, and privacy detections.
- Distinguish expected internal sensitive responses from unexpected public exposure.
- Connect release/config drift to customer-facing leakage.

### Previous Artifact Weaknesses
- Very small request/response evidence.
- No realistic API traffic noise or triage complexity.
- Minimal authz/policy/release context for root-cause validation.

## Step 2 - Real-World Artifact Investigation

Reference sources used:

1. OWASP API Security Top 10 (API3: Broken Object Property Level Authorization / excessive data exposure context):  
   https://owasp.org/API-Security/
2. RFC 6749 OAuth 2.0 (token scope model):  
   https://www.rfc-editor.org/rfc/rfc6749
3. RFC 7662 OAuth 2.0 Token Introspection:  
   https://www.rfc-editor.org/rfc/rfc7662
4. NIST SP 800-53 Rev.5 SI-10 Information Input Validation / data handling control context:  
   https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final
5. MITRE ATT&CK T1530 (Data from Cloud Storage/Object-like exposure patterns by misconfiguration drift):  
   https://attack.mitre.org/techniques/T1530/

### Key Signals Adopted
- Public endpoint `/v1/profile/summary` returning restricted fields.
- Customer token scope `profile:read` receiving `password_hash` and `ssn_last4`.
- DLP alerts tied to request IDs in exposure window.
- Policy exception path (`legacy serializer compatibility`) and release flag drift.
- Internal admin route with sensitive fields as controlled/expected contrast.

## Step 3 - Artifact Design Upgrade

Upgraded pack includes:
- `gateway_access.log` (**11,204 lines**) high-volume API ingress telemetry.
- `service_response_samples.jsonl` (**8,304 lines**) response-shape evidence with noise.
- `token_introspection.jsonl` (**6,202 lines**) scope/subject validity context.
- `authorization_decisions.csv` (**5,404 lines**) policy decision stream.
- `waf_alerts.jsonl` (**4,200 lines**) non-blocking noisy security alerts.
- `privacy_dlp_findings.csv` (**3,805 lines**) privacy-control evidence and severity.
- `release_change_log.csv` (**1,603 lines**) deployment/change correlation.
- API schema contract files + briefing files.

Realism upgrades:
- Multi-source API/security/ops evidence instead of single payload file.
- Large noisy datasets with false positives.
- Requires joining request IDs across systems.
- Includes benign internal sensitive endpoint to force correct scoping analysis.

## Step 4 - Flag Engineering

Expected investigation path:
1. Start from ticket and identify impacted endpoint/time window.
2. Match gateway request IDs (`req-778411/12/13`) to response samples.
3. Confirm sensitive fields returned under customer scope `profile:read`.
4. Validate token context (active customer token, not admin token).
5. Cross-check DLP critical findings and release-change toggle causing serializer drift.
6. Classify primary CIA impact.

Expected flag:
- `CTF{confidentiality}`

## Step 5 - Generated Artifact Pack

Output ZIP:
- `backend/artifacts/m1/m1-16-api-data-exposure.zip`

## Step 6 - Instructor Notes (Summary)

Suggested tools:
- `rg` / `grep` for request ID and field pivots.
- CSV filtering for policy and DLP timelines.
- `jq` for JSONL streams (response samples, token introspection, WAF).
- Cross-source correlation by request ID + timestamp window.
