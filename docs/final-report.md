# Design and Deployment of a Containerized Microservices System with Terraform-Based Infrastructure Provisioning and Incident Response Simulation

## 1. Introduction

This project demonstrates a small production-style microservices system for an SRE assignment. The system is containerized with Docker, deployed with Docker Compose, monitored with Prometheus and Grafana, and provisioned with Terraform.

## 2. Objectives

- Implement a containerized microservices architecture.
- Use Terraform for reproducible infrastructure provisioning.
- Deploy services using Docker Compose and provide Docker Stack configuration.
- Demonstrate a six-service backend architecture with payment handling.
- Collect metrics and visualize service health.
- Simulate a realistic Order Service incident.
- Document incident response and postmortem analysis.
- Add SRE automation and capacity planning controls after the incident.

## 3. Technology Stack

- Backend: Python FastAPI
- Frontend: HTML, CSS, JavaScript served by Nginx
- Database: PostgreSQL
- Containerization: Docker
- Orchestration: Docker Compose, Docker Stack, and Kubernetes artifacts
- Monitoring: Prometheus and Grafana
- Infrastructure as Code: Terraform Google Cloud Compute Engine
- Configuration Management: Ansible

## 4. System Architecture

The system contains six backend microservices:

- `auth-service`: registration, login, token validation, and simple role-based authorization
- `user-service`: user profile creation and lookup
- `product-service`: product listing and product lookup
- `order-service`: transactional order creation
- `payment-service`: payment handling simulation for created orders
- `chat-service`: user-to-user message creation and listing

The frontend is served by Nginx. Nginx also acts as an API gateway and routes browser requests to the internal services. PostgreSQL is used as the shared database for the assignment demo.

See `docs/architecture.md` for the Mermaid architecture diagram.

## 5. Functional Requirements Coverage

| Requirement | Implementation |
|---|---|
| Web interface | `frontend` container |
| Authentication | `auth-service` |
| Authorization | `auth-service` roles: `user` and `admin` |
| Product retrieval | `product-service` |
| Order creation | `order-service` |
| Payment simulation | `payment-service` |
| Inter-service communication | `order-service` calls `user-service` and `product-service`; `payment-service` calls `order-service` |
| Metrics | `/metrics` endpoint in each service |
| Failure logging | Docker logs and service health endpoints |

## 6. Non-Functional Requirements Coverage

| Requirement | Implementation |
|---|---|
| Scalability | Independent service containers |
| Fault isolation | Order Service incident does not stop all services |
| Observability | Prometheus metrics, cAdvisor, node-exporter, and Grafana dashboard |
| Automated deployment | Docker Compose, Terraform, config validation, and runtime restart policies |
| Reproducibility | Versioned Compose, Terraform, and monitoring configs |
| Containerized execution | Dockerfiles for all application services |

## 7. Container Deployment

```bash
docker compose up --build -d
docker compose ps
```

Important local URLs:

- Frontend: `http://localhost:8080`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`

## 8. Monitoring and Alerts

Every backend service exposes `/health` and `/metrics`.

Prometheus scrapes all backend services, cAdvisor, and node-exporter. Grafana provides a dashboard named `SRE Microservices Overview`. Prometheus alert rules are configured in `monitoring/prometheus/alerts.yml`. The main incident alert is `OrderServiceDown`, with additional rules for error rate, latency, CPU, memory, service load, and restart-loop symptoms.

## 8.1 Automation and Capacity Planning

Assignment 6 adds:

- `restart: unless-stopped` policies for self-healing container restarts.
- `.env.example` for standardized runtime configuration.
- `scripts/validate-config.sh` for pre-deployment configuration validation.
- `scripts/inspect-logs.sh` for log-based incident troubleshooting.
- `scripts/load-test.sh` for repeatable capacity testing.
- Docker Stack resource limits and two `order-service` and `payment-service` replicas for horizontal scaling demonstration.
- Kubernetes manifests cover PostgreSQL, frontend, all six backend services, and HPA policies for transactional services.
- Ansible deployment automation for VM configuration, Docker installation, k3s/Kubernetes installation, Kubernetes manifest validation, and repeatable stack deployment.
- GitHub Actions workflows validate configuration, build service images, publish immutable GHCR tags, deploy the VM through Ansible, and support rollback by redeploying a previous image tag.

Detailed capacity analysis is documented in `docs/assignment-6-automation-capacity-report.md`.

## 9. Infrastructure as Code

Terraform provisions one Google Cloud Compute Engine VM, firewall rules for ports `22`, `80`, `3000`, `8001-8006`, and `9090`, and public IP outputs.

```bash
cd terraform-gcp
terraform init
terraform plan
terraform apply
```

Before a real apply, verify values in `terraform-gcp/terraform.tfvars`.

## 10. Incident Simulation

The simulated incident is an invalid database hostname for `order-service`.

```bash
docker compose -f docker-compose.yml -f docker-compose.incident.yml up -d order-service
```

Expected result:

- Order Service becomes unavailable.
- Order creation fails in the frontend.
- Prometheus target for Order Service becomes unhealthy.
- Grafana availability panel shows the issue.
- Logs show connection failure to `broken-order-db`.

Restore:

```bash
docker compose up -d order-service
```

## 11. Postmortem Summary

Root cause: invalid runtime configuration for Order Service database hostname.

Impact: order creation unavailable while other services continued running.

Resolution: restore correct database hostname and restart Order Service.

Action items:

- Add healthchecks.
- Add Prometheus alerts.
- Validate environment variables before deployment.
- Use staged configuration review before production rollout.

## 12. Conclusion

The project demonstrates the combination of microservices, containerization, Infrastructure as Code, observability, and incident response practices in a simple, reproducible student-level system.
