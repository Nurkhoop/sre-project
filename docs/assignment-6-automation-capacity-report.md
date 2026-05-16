# Assignment 6: Automation in SRE and Capacity Planning

## 1. Title

Automation and Capacity Planning in a Containerized Microservices System Following Incident Response and Infrastructure Provisioning

## 2. Objective

This assignment extends the previous incident response and Terraform work by adding SRE automation, monitoring-based alerting, capacity planning, and scaling recommendations for the Dockerized microservices system.

The work builds on:

- Assignment 4: Order Service incident response and postmortem analysis
- Assignment 5: Terraform-based infrastructure provisioning

## 3. System Context

The system consists of:

- Frontend served by Nginx
- Authentication Service
- User Service
- Product Service
- Order Service
- Payment Service
- Chat Service
- PostgreSQL database
- Prometheus
- Grafana
- Terraform infrastructure for Google Cloud Compute Engine
- Ansible deployment automation for VM configuration and stack deployment

The Assignment 4 incident was caused by an incorrect Order Service database hostname. Assignment 6 focuses on reducing the chance of a similar incident and improving detection, recovery, and capacity planning.

## 4. Implemented Automation Mechanisms

| Area | Implementation | Evidence |
|---|---|---|
| Automated deployment | Docker Compose starts the complete system with one command. Terraform provisions Google Cloud VM infrastructure. Ansible configures a VM, installs Docker and Kubernetes with k3s, validates manifests, and deploys the stack. | `docker-compose.yml`, `terraform-gcp/`, `ansible/` |
| Standard configuration | `.env.example` documents runtime variables and Compose uses variable interpolation with defaults. | `.env.example`, `docker-compose.yml` |
| Health checks | Backend services, frontend, database, Prometheus, and Grafana expose Docker health checks. | `docker-compose.yml` |
| Self-healing | Runtime containers use `restart: unless-stopped`. | `docker-compose.yml` |
| Metrics collection | FastAPI services expose `/metrics`; cAdvisor and node-exporter expose container and host metrics. | `monitoring/prometheus/prometheus.yml` |
| Alerting | Prometheus alert rules detect downtime, high error rate, high latency, high load, CPU, memory, and restart-loop symptoms. | `monitoring/prometheus/alerts.yml` |
| Configuration validation | Pre-deployment validation script checks required variables, URL format, database port format, and Compose rendering. | `scripts/validate-config.sh` |
| Log troubleshooting | Log inspection script searches for known incident patterns and prints Docker restart count. | `scripts/inspect-logs.sh` |
| Load simulation | Load-test script generates concurrent Order Service traffic through the frontend gateway. | `scripts/load-test.sh` |
| Kubernetes orchestration artifact | Manifests cover PostgreSQL, frontend, all six backend services, and HPA for Order and Payment from 2 to 5 replicas at 70% CPU utilization. | `k8s/` |

## 5. Health Checks and Self-Healing

Each backend service exposes:

- `/health` for service and database readiness
- `/metrics` for Prometheus scraping

Docker health checks call each service health endpoint. PostgreSQL uses `pg_isready`. Prometheus and Grafana use their own health endpoints.

Self-healing is implemented with:

```bash
restart: unless-stopped
```

This allows Docker to restart failed containers automatically unless the operator intentionally stops them.

## 6. Monitoring and Alerting

Prometheus scrapes:

- `auth-service`
- `user-service`
- `product-service`
- `order-service`
- `payment-service`
- `chat-service`
- `cadvisor`
- `node-exporter`

Implemented alert rules:

| Alert | Purpose |
|---|---|
| `OrderServiceDown` | Detects the critical incident from Assignment 4. |
| `PaymentServiceDown` | Detects payment handling outage. |
| `AnyMicroserviceDown` | Detects any backend service outage. |
| `HighErrorRate` | Detects elevated 5xx responses. |
| `HighRequestLatency` | Detects p95 latency above one second. |
| `OrderServiceHighLoad` | Detects high request rate on Order Service. |
| `HighContainerCpuUsage` | Detects CPU saturation. |
| `HighContainerMemoryUsage` | Detects high memory usage. |
| `PossibleContainerRestartLoop` | Detects repeated container start-time changes. |

Grafana dashboard panels show:

- Service availability
- Request rate
- 5xx errors
- p95 latency
- Container CPU usage
- Container memory usage
- Host CPU saturation
- Order Service load
- Error rate ratio
- Container start changes

## 7. Configuration Validation

Before deployment, the operator can run:

```bash
./scripts/validate-config.sh
```

The script validates:

- Required database variables
- Database port format
- User, Product, and Order service endpoint URL format
- Rendered Docker Compose configuration

This directly addresses the Assignment 4 root cause: invalid Order Service runtime configuration.

## 8. Log-Based Troubleshooting Automation

During an incident, the operator can run:

```bash
./scripts/inspect-logs.sh order-service
```

The script searches recent container logs for common root-cause patterns:

- Database hostname resolution failure
- Connection refused
- Timeout
- Python traceback
- Generic error messages
- Restart indicators

It also prints the Docker restart count for the selected service.

## 9. Capacity Planning Method

Capacity planning uses the following metrics:

| Metric | Source | Why it matters |
|---|---|---|
| Request rate | FastAPI Prometheus metrics | Shows incoming demand per service. |
| Error rate | FastAPI Prometheus metrics | Shows overload or application failure symptoms. |
| p95 latency | FastAPI Prometheus metrics | Shows user-facing performance degradation. |
| Container CPU | cAdvisor | Shows service resource pressure. |
| Container memory | cAdvisor | Shows memory pressure and leak risk. |
| Host CPU | node-exporter | Shows VM saturation. |
| Container start changes | cAdvisor | Indicates restart-loop symptoms. |

Load can be generated with:

```bash
REQUESTS=300 CONCURRENCY=20 ./scripts/load-test.sh
```

The script creates repeated order requests through Nginx. This exercises:

- Frontend gateway routing
- Order Service
- Payment Service
- User Service dependency call
- Product Service dependency call
- PostgreSQL writes

## 10. Capacity Observations

Expected behavior under increased load:

- Order Service request rate increases first because the load test targets order creation.
- Order Service latency increases because each order requires dependency calls to User and Product services.
- Payment Service becomes critical after orders are created because it validates order existence and writes payment records.
- PostgreSQL becomes more important as all orders create database writes.
- If CPU or memory limits are too low, error rate and p95 latency increase.
- If database connectivity is misconfigured, `OrderServiceDown` and log inspection detect the failure quickly.

## 11. Capacity Analysis

| Component | Capacity Risk | Reason |
|---|---|---|
| Order Service | High | It performs validation, two downstream HTTP calls, and a database insert per order. |
| Payment Service | High | It validates orders through Order Service and writes transaction records. |
| PostgreSQL | Medium to high | It is shared by all services and handles order writes. |
| Product Service | Medium | It is called by every order request. |
| User Service | Medium | It is called by every order request. |
| Frontend/Nginx | Low | It mainly proxies requests and serves static files. |
| Auth/Chat | Low for this test | They are not on the main order creation path. |

The Order Service and Payment Service are the primary scaling candidates because
they sit on the transactional path and perform database writes.

## 12. Scaling Strategy

### Horizontal Scaling

For Docker Swarm, `docker-stack.yml` sets:

```yaml
order-service:
  deploy:
    replicas: 2
payment-service:
  deploy:
    replicas: 2
```

This distributes Order Service and Payment Service requests across multiple
replicas through Swarm routing mesh.

### Vertical Scaling

Terraform variables allow VM size changes:

- Google Cloud: `machine_type`
- Google Cloud disk: `boot_disk_size_gb`

Recommended next step when host CPU or memory is saturated:

- Increase VM CPU and memory through Terraform
- Re-run `terraform plan`
- Apply during a controlled maintenance window

### Database Optimization

Recommended improvements:

- Add connection pooling with PgBouncer or SQLAlchemy pooling
- Review indexes for high-volume tables
- Tune PostgreSQL memory settings on larger VMs
- Separate database from application VM for production-like deployments

## 13. Auto-Scaling Considerations

The local runtime remains Docker Compose, but the repository now includes Kubernetes manifests in `k8s/` to demonstrate declarative orchestration and automated scaling policy design.

Kubernetes artifact:

- `app-db-deployment.yaml`: PostgreSQL deployment with readiness probe.
- `frontend-deployment.yaml`: Nginx frontend deployment.
- `auth-service-deployment.yaml`, `user-service-deployment.yaml`, `product-service-deployment.yaml`, and `chat-service-deployment.yaml`: supporting backend service deployments.
- `order-service-deployment.yaml`: Deployment with two initial replicas, readiness/liveness probes, and CPU/memory requests and limits.
- `order-service-service.yaml`: ClusterIP service for internal routing.
- `order-service-hpa.yaml`: Horizontal Pod Autoscaler for CPU-based scaling.
- `payment-service-deployment.yaml`: Deployment with two initial replicas, readiness/liveness probes, and CPU/memory requests and limits.
- `payment-service-service.yaml`: ClusterIP service for internal routing.
- `payment-service-hpa.yaml`: Horizontal Pod Autoscaler for CPU-based scaling.

HPA policy:

| Setting | Value |
|---|---|
| Metric | CPU utilization |
| Threshold | 70% average CPU |
| Minimum replicas | 2 |
| Maximum replicas | 5 |

Validation command:

```bash
kubectl apply --dry-run=client -f k8s/
```

If no Kubernetes cluster is configured, the repository includes a local manifest validation command:

```bash
./scripts/validate-k8s-manifests.sh
```

For a real Kubernetes deployment, Metrics Server must be installed so HPA can read CPU metrics.

The proposed production approach is:

- Move runtime orchestration to Kubernetes
- Use Horizontal Pod Autoscaler based on CPU and request metrics
- Use managed PostgreSQL or a separately scaled database tier
- Keep Terraform as the infrastructure provisioning layer

## 14. Improvements After Assignment 4 and Assignment 5

| Previous Weakness | Improvement |
|---|---|
| Order Service misconfiguration caused outage | Added config validation and standard env template. |
| Manual recovery required | Added restart policies and log inspection automation. |
| Limited alert coverage | Added downtime, error, latency, CPU, memory, and restart-loop alerts. |
| Limited capacity analysis | Added cAdvisor, node-exporter, load-test script, and Grafana capacity panels. |
| Infrastructure existed but scaling was not described deeply | Added Docker Stack replicas and Terraform vertical scaling strategy. |
| Auto-scaling was only theoretical | Added Kubernetes HPA artifacts with CPU threshold policy. |
| Configuration management was not represented | Added Ansible playbook for VM setup, Docker installation, k3s/Kubernetes installation, manifest validation, and deployment automation. |
| Backend contained only five business services | Added Payment Service as the sixth independent microservice. |

## 15. Conclusion

The system now includes deployment automation, configuration validation, health checks, self-healing restart policies, monitoring-based alerting, load simulation, capacity metrics, and scaling recommendations. These improvements reduce manual operational work, improve incident detection, and provide a clear basis for capacity planning in line with SRE principles.
