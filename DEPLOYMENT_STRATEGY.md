# ZeroTrace CTF - DEPLOYMENT_STRATEGY (MVP)

## Scope

This document defines the deployment strategy for the ZeroTrace CTF MVP.

In scope:

- Frontend
- Backend API
- PostgreSQL database
- Static challenge attachments
- Admin panel
- Leaderboard
- Authentication system

Out of scope for MVP deployment strategy:

- Docker lab virtualization
- SOC ingestion pipelines
- Distributed microservices
- Multi-region deployment
- Dynamic lab orchestration

## Critical Rules (Non-Negotiable)

- Production must never share secrets with development.
- Admin credentials must not be hardcoded.
- All environments must use HTTPS.
- Logs must not expose sensitive information.
- Deployment must be repeatable and documented.
- Database backups must be automated.

## 1. Deployment Philosophy

### Environment Separation (Dev / Staging / Production)

- Three environments are required:
  - `Development` (local/internal developer use)
  - `Staging` (pre-production validation)
  - `Production` (live users)
- Each environment is isolated at configuration, secrets, and data levels.
- Staging is used to validate release candidates before production deployment.

### Infrastructure Simplicity for MVP

- MVP uses a simple single-region deployment model.
- Minimize moving parts to reduce operational complexity and misconfiguration risk.
- Prefer a small number of well-defined components over distributed services.
- Avoid introducing orchestration layers not required by MVP scope.

### Security-First Defaults

- Default-deny network exposure and privileged access.
- HTTPS enforced for all environments.
- Production runs with debug disabled and secure headers enabled.
- Administrative access is treated as a high-risk path and audited.

### Minimal Attack Surface

- Expose only required public endpoints.
- Keep database inaccessible from the public internet.
- Restrict management access to trusted operators only.
- Disable unused services and ports on deployment hosts.

## 2. Environment Architecture (High-Level)

### Frontend Hosting Model

- Frontend is deployed as static web assets.
- Static assets are served via a reverse proxy / web server.
- Frontend communicates only with the backend API over HTTPS.

### Backend Hosting Model

- Backend API runs as a long-lived application service in the same region as the frontend and database.
- Backend is reachable only through the reverse proxy (not directly exposed if avoidable).
- Backend is stateless at request level; session/auth state is token-based.

### Database Hosting Model

- PostgreSQL runs in the same region as the backend.
- Database is deployed as a private service endpoint not accessible from the public internet.
- Database access is limited to the backend service and authorized operators.

### Reverse Proxy (If Applicable)

- A reverse proxy terminates HTTPS and routes requests to:
  - frontend static assets
  - backend API
- Reverse proxy enforces HTTPS redirects and basic request hardening controls.
- Reverse proxy should limit direct exposure of backend service details.

### HTTPS Enforcement

- HTTPS is mandatory in all environments (including staging).
- HTTP requests must be redirected to HTTPS.
- TLS certificates must be valid and renewed before expiry.
- Mixed-content behavior is not permitted.

## 3. Environment Separation Strategy

### Separate Databases Per Environment

- Development, staging, and production each use separate PostgreSQL databases.
- No environment may connect to another environment’s database.
- Production data must never be used directly in development.

### Separate Secrets Per Environment

- Each environment has unique secrets for:
  - authentication token signing
  - flag hashing
  - database credentials
  - admin bootstrap / operational access (if applicable)
- Secret rotation in one environment must not affect the others.

### No Shared Credentials

- No shared database users or passwords across environments.
- No shared admin accounts across environments.
- CI/CD credentials for staging and production must be separate.

### Environment-Specific Config Files

- Each environment uses its own configuration set.
- Configuration values must match environment purpose (for example, debug disabled in production).
- Environment-specific configuration files must not be interchangeable without review.

## 4. Configuration Management

### Environment Variables

- Runtime configuration is supplied through environment variables or equivalent deployment-time configuration injection.
- Environment variables define non-code runtime behavior, including secrets and environment-specific endpoints.
- Required variables must be validated at startup; missing required values must fail deployment/startup.

### Secret Storage Principles

- Secrets are stored outside source control.
- Access to secrets is limited to operators and services that require them.
- Secrets must not be printed in logs, error messages, or admin interfaces.
- Secret changes require change tracking and deployment coordination.

### `.env` Handling Rules

- `.env` files are allowed only for local development and controlled staging setups.
- `.env` files containing secrets must not be committed to source control.
- Production secret values must not depend on local `.env` files copied manually from developer machines.

### No Secrets in Source Control

- Prohibit committing:
  - database passwords
  - authentication signing secrets
  - flag hashing secrets
  - admin credentials
  - TLS private keys
- Repository scanning and review must treat exposed secrets as security incidents.

### Production Config Immutability

- Production configuration changes must occur through a documented deployment/change process.
- Ad-hoc manual edits on production hosts are discouraged and must be tracked if unavoidable.
- Production runtime settings should be treated as versioned operational configuration.

## 5. CI/CD Strategy

### Branch Strategy (`main`, `develop`)

- `develop`:
  - integration branch for active MVP development
  - deploy target for staging (after validation)
- `main`:
  - release branch for production deployments
  - only tested and approved changes are merged

### Pull Request Validation

- All changes must be merged via pull request.
- Pull requests require:
  - code review
  - test validation
  - security-impact review for auth/RBAC/flag/XP/admin changes
- Documentation changes to security, API, or deployment behavior must be reviewed with the same discipline.

### Automated Testing Before Merge

- Minimum pre-merge validation:
  - unit tests
  - integration/API tests
  - security-focused regression checks for protected routes and submission flow
  - lint/type/static validation checks (as defined by the project)
- Failing validation blocks merge.

### Deployment Trigger Rules

- Staging deployment trigger:
  - merge to `develop` after successful validation
- Production deployment trigger:
  - merge to `main` (or approved release tag) after staging validation and manual approval
- No direct deployment from feature branches to production.

### Manual Approval Before Production

- Production deployment requires explicit human approval.
- Approval must confirm:
  - test status
  - migration readiness
  - rollback readiness
  - backup readiness
- Emergency deployments must still be documented and reviewed after execution.

## 6. Database Strategy

### Migration Workflow

- Schema changes are applied through versioned migrations.
- Migrations are executed as a controlled deployment step, not ad-hoc.
- Production migrations require pre-deployment review and staging validation.
- Migration order must be deterministic and documented.

### Backup Policy

- Automated database backups are mandatory.
- Backup schedule must support recovery from operational error and security incidents.
- Backups must be stored securely and access-controlled.
- Backup jobs must be monitored for success/failure.

### Restore Testing

- Backup restore must be tested on a regular schedule in a non-production environment.
- Restore tests must validate:
  - database integrity
  - expected schema version
  - critical tables present (users, challenges, attempts, XP, admin logs)
- Unverified backups are treated as a risk.

### Data Retention Rules

- Retain backups according to an explicit retention schedule.
- Retention must support:
  - short-term operational restores
  - incident investigation windows
  - rollback recovery points
- Retention periods must be documented and reviewed as data volume grows.

### No Destructive Schema Changes in Production

- Avoid destructive schema changes in MVP production releases.
- Prefer additive schema changes with controlled cleanup later.
- If a destructive change becomes unavoidable, require:
  - explicit approval
  - validated backup
  - tested rollback/restore plan

## 7. Static File Handling

### Secure Storage of Challenge Attachments

- Challenge attachments are stored in a controlled server-side location separate from application source.
- Attachment storage path must be managed by deployment configuration.
- Only expected static challenge artifacts are permitted.

### Prevent Directory Traversal

- Attachment access must not trust user-provided paths.
- File references must be resolved against controlled attachment metadata, not raw path input.
- Path normalization and access checks are required before serving any file.

### Controlled Public Access

- Attachments should be accessible only through authorized application/reverse-proxy routes.
- Access policy must follow challenge visibility:
  - published challenge attachments are accessible to authorized users
  - unpublished challenge attachments are not publicly accessible
- Direct directory listing must be disabled.

### File Size Limits

- Define and enforce attachment size limits for MVP.
- Oversized files must be rejected during admin challenge management workflow.
- Storage usage must be monitored to prevent disk exhaustion.

## 8. Security Controls

### HTTPS Only

- Enforce HTTPS for all endpoints and environments.
- Redirect all HTTP traffic to HTTPS.
- Reject insecure callbacks/links in deployment configuration where applicable.

### Rate Limiting

- Apply request rate limiting at API and/or reverse proxy level for:
  - authentication endpoints
  - flag submission endpoint
  - high-risk public routes
- Validate rate limiting in staging before production releases.

### Firewall Considerations

- Expose only required public ports (web traffic).
- Restrict administrative access ports to authorized operator sources where possible.
- Do not expose database ports publicly.
- Deny unused inbound traffic by default.

### Restrict Admin Routes

- Admin routes are protected by backend role checks.
- Optional network-level restrictions (for example, operator IP allowlisting) may be used in staging/production if operationally feasible.
- Admin route access and actions must be logged.

### Disable Debug Mode in Production

- Debug mode and verbose internal error output must be disabled in production.
- Production error responses must not expose stack traces or internal configuration values.

### Secure Headers

- Reverse proxy and/or backend must enforce secure HTTP headers suitable for MVP web application use.
- Header policy must reduce common browser-side risks (clickjacking, content sniffing, script injection exposure).

## 9. Logging & Monitoring

### Application Logs

- Capture structured application events for operational troubleshooting.
- Log request outcomes and important workflow events without sensitive payload disclosure.
- Separate normal operational logs from security/audit-relevant logs where possible.

### Error Logs

- Capture backend and deployment/runtime errors with sufficient context for debugging.
- Errors must not log secrets, plaintext flags, or credential data.
- Repeated error spikes must be detectable.

### Admin Activity Logs

- Admin challenge changes and role changes must be logged as audit events.
- Admin logs are required for accountability and incident reconstruction.
- Admin logs must be retained and protected from normal modification.

### Log Retention Policy

- Define retention periods for:
  - application logs
  - error logs
  - admin audit logs
- Retention must balance operational usefulness, security review needs, and storage capacity.
- Log rotation is required to prevent disk exhaustion.

### Basic Alerting Rules

Minimum alerting for MVP:

- Service unavailable / health check failure
- Repeated authentication failures spike
- High flag submission failure rate spike
- Database backup failure
- Low disk space / high disk usage
- Repeated application error spikes

## 10. Rollback Strategy

### Deployment Rollback Process

- Each deployment must be traceable to a specific release artifact/version.
- Rollback must restore the previous known-good application release for frontend and backend.
- Rollback steps must be documented and rehearsed in staging.
- Rollback execution must be logged as an operational event.

### Database Rollback Considerations

- Database rollback is higher risk than application rollback.
- Prefer forward-fix migrations where possible.
- If database rollback is required:
  - use validated backups / restore points
  - confirm schema/data compatibility with target application version
  - execute through documented recovery procedure
- No assumptions that application rollback alone is safe after schema changes.

### Feature Flag Usage (If Any)

- MVP may use minimal configuration-based feature flags only if needed for safe rollout.
- Feature flags must default to secure behavior.
- Feature flags must not replace authorization checks or core security controls.

### Incident Response Outline

- Detect and classify incident (availability, security, data integrity)
- Contain impact (disable affected path, rollback, or restrict access)
- Recover service (restore application/database state as needed)
- Validate integrity (XP, challenges, admin actions, logs)
- Document incident and corrective actions

## 11. Performance & Scaling (MVP Level)

### Expected Traffic Model

- MVP assumes low to moderate traffic with bursty submission behavior during usage peaks.
- Most traffic is read-heavy (tracks, challenge detail, leaderboard) with write spikes on flag submissions and admin updates.
- Abuse patterns (high-frequency submissions) must be considered in capacity planning.

### Vertical Scaling Approach

- MVP scaling strategy is vertical first:
  - increase CPU/memory/storage on the single-region host as needed
  - tune database resources and storage I/O before adding infrastructure complexity
- Capacity increases must be planned before saturation.

### Horizontal Scaling Future Note

- Horizontal scaling is not an MVP requirement.
- Future horizontal scaling will require:
  - session/token handling review
  - shared rate-limiting strategy
  - shared attachment storage strategy
  - database connection and read/write scaling strategy

### Database Indexing Strategy

- Indexing must prioritize MVP read/write paths:
  - authentication lookups
  - challenge listing/order
  - attempt logging and abuse review
  - XP and leaderboard queries
  - admin log filters
- Index performance and bloat should be reviewed periodically as data grows.

## 12. Production Hardening Checklist

Use this checklist before first production release and after major infrastructure changes.

### Application and Runtime

- Debug mode disabled
- Verbose error output disabled
- Production configuration validated at startup
- Environment variables validated (required values present, no placeholder defaults)
- Secure headers enabled
- Rate limits configured and tested

### Credentials and Secrets

- Test accounts removed or disabled
- Default passwords removed
- Admin credentials are not hardcoded
- Production secrets differ from development/staging
- Secret access limited to required services/operators

### Data Protection

- Database not publicly exposed
- Automated backups enabled
- Backup success notifications/alerts verified
- Backup restore tested in non-production environment
- Log retention and rotation configured

### Access Control and Security

- Admin routes protected and verified with player-token rejection tests
- HTTPS enforced with valid certificates
- Firewall rules reviewed (only required ports open)
- Management access restricted to authorized operators

### Content and Attachments

- Attachment directory listing disabled
- Attachment access rules validated for unpublished challenges
- File size limits enforced and tested

### Operational Readiness

- Deployment runbook documented
- Rollback runbook documented
- On-call / responder contact path defined (MVP level)

## 13. Post-MVP Expansion Considerations

These are not MVP deployment requirements, but future architecture planning must account for them.

### Docker Lab Orchestration

- Separate control plane from lab execution plane
- Lifecycle orchestration, cleanup, and resource quotas
- Isolation boundaries between user labs and platform services

### Container Isolation

- Strong workload isolation controls
- Privilege restrictions
- Image integrity and provenance controls
- Escape detection and containment strategy

### Multi-Region Support

- Region failover strategy
- Data replication and consistency model
- Geo-aware traffic routing
- Expanded backup and disaster recovery planning

### WAF Integration

- Additional request filtering for public endpoints
- Bot mitigation enhancements
- Managed rule tuning without blocking legitimate flag submissions

### Audit Log Expansion

- Longer retention and tamper-evidence controls
- Broader administrative and security event coverage
- External archival/export for compliance or forensic needs

## Deployment Governance and Documentation Rule

- All deployment procedures (deploy, rollback, backup restore, secret rotation) must be documented and version-controlled.
- Changes to deployment topology, security controls, environment separation, or backup policy must update this document before rollout.
