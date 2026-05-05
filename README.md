# SRE Microservices Assignment

This project implements a containerized microservices system with Infrastructure as Code,
monitoring, and an incident response simulation.

## Architecture

- Frontend: JavaScript application served by Nginx
- API gateway: Nginx reverse proxy
- Microservices: `auth-service`, `user-service`, `product-service`, `order-service`, `chat-service`
- Database: PostgreSQL
- Monitoring: Prometheus and Grafana
- Infrastructure as Code: Terraform AWS EC2 provisioning

## Run Locally

```bash
docker compose up --build -d
```

Open:

- Frontend: http://localhost:8080
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
- cAdvisor: http://localhost:8081
- node-exporter: http://localhost:9100/metrics

On a cloud VM, expose the frontend on standard HTTP port `80`:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
```

Open:

- Frontend: `http://PUBLIC_IP`
- Prometheus: `http://PUBLIC_IP:9090`
- Grafana: `http://PUBLIC_IP:3000`

Grafana credentials:

- Username: `admin`
- Password: `admin`

## Service Ports

- Auth Service: http://localhost:8001/docs
- User Service: http://localhost:8002/docs
- Product Service: http://localhost:8003/docs
- Order Service: http://localhost:8004/docs
- Chat Service: http://localhost:8005/docs

Each service exposes:

- `/health`
- `/metrics`

Docker Compose also defines container healthchecks for PostgreSQL, frontend,
Prometheus, Grafana, and all five FastAPI services.

Runtime containers use `restart: unless-stopped` for basic self-healing.

Authentication supports simple roles:

- `user`
- `admin`

## Incident Simulation

The incident breaks the Order Service database hostname:

```bash
docker compose -f docker-compose.yml -f docker-compose.incident.yml up -d order-service
docker compose ps
docker compose logs order-service
```

Restore service:

```bash
docker compose up -d order-service
curl http://localhost:8004/health
```

## Assignment 6 Automation

Validate configuration before deployment:

```bash
./scripts/validate-config.sh
```

Inspect logs for common incident patterns:

```bash
./scripts/inspect-logs.sh order-service
```

Generate load for capacity planning:

```bash
REQUESTS=300 CONCURRENCY=20 ./scripts/load-test.sh
```

## Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Replace placeholder values in `terraform/terraform.tfvars` before applying.

Google Cloud alternative:

```bash
cd terraform-gcp
terraform init
terraform plan
terraform apply
```

Use this folder if your assignment VM is on Google Cloud Compute Engine.

## Docker Stack

`docker-stack.yml` is included for Docker Swarm style deployment. Build and tag the
service images first, then deploy with:

```bash
docker stack deploy -c docker-stack.yml sre-assignment
```

## Kubernetes Auto-Scaling Artifact

The `k8s/` folder demonstrates Kubernetes integration and automated scaling for
Assignment 6. The Order Service HPA scales from 2 to 5 replicas when average CPU
utilization reaches 70%.

Validate without deploying:

```bash
kubectl apply --dry-run=client -f k8s/
```

If no Kubernetes cluster is configured, use:

```bash
./scripts/validate-k8s-manifests.sh
```

## Documentation

- Deployment guide: `docs/deployment-guide.md`
- Final report draft: `docs/final-report.md`
- Architecture diagram: `docs/architecture.md`
- Assignment 4 incident report: `docs/assignment-4-incident-report.md`
- Postmortem: `docs/postmortem.md`
- Assignment 5 Terraform report: `docs/assignment-5-terraform-report.md`
- Assignment 6 automation and capacity report: `docs/assignment-6-automation-capacity-report.md`
- Screenshot checklist: `docs/screenshot-checklist.md`
- Screenshot filename plan: `docs/screenshots/README.md`
