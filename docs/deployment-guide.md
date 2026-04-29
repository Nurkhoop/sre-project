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
```

5. Check Docker health status:

```bash
docker compose ps
```

## Monitoring Validation

1. Open Prometheus at http://localhost:9090/targets.
2. Confirm all service targets are `UP`.
3. Open Prometheus rules at http://localhost:9090/rules.
4. Confirm `OrderServiceDown` and `AnyMicroserviceDown` are loaded.
5. Open Grafana at http://localhost:3000.
6. Login with `admin` / `admin`.
7. Open the `SRE Microservices Overview` dashboard.

## Terraform VM Provisioning

AWS version:

1. Edit `terraform/terraform.tfvars`.
2. Run:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

3. Copy the repository to the VM.
4. Run Docker Compose on the VM.
5. Access:

- `http://PUBLIC_IP`
- `http://PUBLIC_IP:3000`
- `http://PUBLIC_IP:9090`

Google Cloud version:

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

## Docker Stack Deployment

`docker-stack.yml` is provided for Docker Swarm environments. Build and tag the
images before deployment, then run:

```bash
docker stack deploy -c docker-stack.yml sre-assignment
```
