# Postmortem Analysis

## Incident Overview

The Order Service became unavailable after an incorrect database hostname was deployed.
The failure was isolated to the transactional ordering workflow.

## Customer Impact

Users could not create orders during the incident. Product browsing, user creation,
authentication, and chat remained available.

## Root Cause Analysis

The root cause was invalid runtime configuration: `DB_HOST=broken-order-db`.
Because the service depends on PostgreSQL at startup, the invalid hostname prevented
the application from becoming healthy.

## Detection and Response Evaluation

Detection was effective because Prometheus and Grafana exposed service availability.
Response required manual log inspection and manual redeployment.

## Resolution Summary

The invalid database hostname was removed and `order-service` was restarted with
the correct `DB_HOST=app-db` configuration.

## Lessons Learned

- Configuration errors can create production-like outages even when application code is correct.
- Health checks and metrics make the failure visible quickly.
- Service isolation prevented the incident from taking down all services.
- A rollback path should be documented before deployment.

## Action Items

- Add automated alerts when Prometheus target `up == 0`. Implemented in `monitoring/prometheus/alerts.yml`.
- Add CI validation for required environment variables.
- Add Docker healthchecks to all services. Implemented in `docker-compose.yml`.
- Add a staging deployment where incident-style configuration changes can be tested.
- Store production configuration in reviewed IaC or secrets management.
