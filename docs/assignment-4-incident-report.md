# Assignment 4: Incident Response Simulation

## Incident Summary

The simulated incident introduces an invalid database hostname for `order-service`.
This prevents the service from connecting to PostgreSQL and causes order creation to fail.

## Impact Assessment

Customers can still browse products, create users, authenticate, and use chat.
Transactional order creation is unavailable while the incident is active.

## Severity Classification

Severity: SEV-2

Reason: A core business function is unavailable, but the entire platform is not down.

## Timeline of Events

- T+00: Incorrect database hostname deployed through `docker-compose.incident.yml`.
- T+01: `order-service` cannot connect to PostgreSQL.
- T+02: Prometheus target for `order-service` changes to unhealthy or unavailable.
- T+03: Grafana dashboard shows reduced service availability.
- T+04: Logs are inspected with `docker compose logs order-service`.
- T+05: Root cause identified as `DB_HOST=broken-order-db`.
- T+06: Correct configuration restored by redeploying normal Compose configuration.
- T+07: `/health`, Prometheus targets, and frontend order creation are verified.

## Detection

Detection sources:

- Grafana service availability panel
- Prometheus `/targets` page
- Prometheus `OrderServiceDown` alert rule
- Frontend order creation failure
- Docker container logs

## Root Cause

The `order-service` environment variable `DB_HOST` was set to an invalid hostname.
The service entrypoint waited for a database host that did not exist, preventing startup.

## Mitigation Steps

1. Confirm affected service:

```bash
docker compose ps
docker compose logs order-service
```

2. Remove incident override and redeploy:

```bash
docker compose up -d order-service
```

3. Validate recovery:

```bash
curl http://localhost:8004/health
```

## Resolution Confirmation

The incident is resolved when:

- `order-service` container is running.
- `http://localhost:8004/health` returns `{"status":"ok"}`.
- Prometheus target for `order-service` is `UP`.
- Grafana service availability returns to normal.
- A new order can be created from the frontend.
