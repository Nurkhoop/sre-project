# Deployment Guide

## Local Docker Compose Deployment

1. Build and start all services:

```bash
docker compose up --build -d
```

For a cloud VM, use the production override so the frontend is available on
standard HTTP port `80`:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
```

2. Verify containers:

```bash
docker compose ps
```

3. Open the application:

- Frontend: http://localhost:8080
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
- cAdvisor: http://localhost:8081
- node-exporter: http://localhost:9100/metrics

Cloud VM URLs:

- Frontend: `http://PUBLIC_IP`
- Prometheus: `http://PUBLIC_IP:9090`
- Grafana: `http://PUBLIC_IP:3000`

4. Verify service health:

```bash
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:8004/health
curl http://localhost:8005/health
curl http://localhost:8006/health
```

5. Check Docker health status:

```bash
docker compose ps
```

6. Run pre-deployment configuration validation:

```bash
./scripts/validate-config.sh
```

## Monitoring Validation

1. Open Prometheus at http://localhost:9090/targets.
2. Confirm all service targets are `UP`.
3. Open Prometheus rules at http://localhost:9090/rules.
4. Confirm `OrderServiceDown`, `PaymentServiceDown`, and `AnyMicroserviceDown` are loaded.
5. Open Grafana at http://localhost:3000.
6. Login with `admin` / `admin`.
7. Open the `SRE Microservices Overview` dashboard.

## Capacity Planning Validation

Generate a repeatable Order Service load:

```bash
REQUESTS=300 CONCURRENCY=20 ./scripts/load-test.sh
```

During the test, watch the Grafana dashboard panels for:

- Order Service request rate
- p95 latency
- 5xx errors
- container CPU usage
- container memory usage
- host CPU saturation

Create a payment after an order exists:

```bash
curl -X POST http://localhost:8080/api/payments/ \
  -H "Content-Type: application/json" \
  -d '{"order_id":1,"amount":25.00,"method":"card"}'
```

For log-based troubleshooting, run:

```bash
./scripts/inspect-logs.sh order-service
```

## Terraform VM Provisioning

1. Edit `terraform-gcp/terraform.tfvars`.
2. Run:

```bash
cd terraform-gcp
terraform init
terraform plan
terraform apply
```

3. SSH into the VM.
4. Clone the repository.
5. Run Docker Compose on the VM.
6. Access:

- `http://PUBLIC_IP`
- `http://PUBLIC_IP:3000`
- `http://PUBLIC_IP:9090`

## Ansible Deployment

Ansible can configure a fresh VM, install Docker and k3s/Kubernetes, validate
Compose and Kubernetes manifests, and deploy the same Compose stack:

```bash
cp ansible/inventory.example.ini ansible/inventory.ini
ansible-playbook -i ansible/inventory.ini ansible/deploy.yml
```

Update the VM IP address and Git repository URL in `ansible/inventory.ini`
before running the playbook.

The default inventory keeps Kubernetes manifest application disabled because
Docker Compose is the main runtime demo:

```ini
deploy_kubernetes_manifests=false
```

Set it to `true` only when the Kubernetes cluster can access the service images.

## Docker Stack Deployment

`docker-stack.yml` is provided for Docker Swarm environments. Build and tag the
images before deployment, then run:

```bash
docker stack deploy -c docker-stack.yml sre-assignment
```
