# Complete Testing Guide

This guide gives the exact commands to test the end-term SRE project from a
fresh local machine or cloud VM.

## 1. Local Docker Compose Test

Start Docker Desktop first. Then run:

```bash
docker compose up --build -d
docker compose ps
```

Open:

- Frontend: `http://localhost:8080`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000` with `admin` / `admin`

Run automated checks:

```bash
./scripts/validate-config.sh
./scripts/smoke-test.sh
```

Expected result:

- all six backend health checks pass
- frontend loads
- Prometheus is healthy
- Grafana is healthy
- user, order, and payment requests work

## 2. Monitoring Test

Open Prometheus targets:

```text
http://localhost:9090/targets
```

Confirm these targets are `UP`:

- `auth-service`
- `user-service`
- `product-service`
- `order-service`
- `payment-service`
- `chat-service`
- `cadvisor`
- `node-exporter`

Open alert rules:

```text
http://localhost:9090/rules
```

Confirm rules such as `OrderServiceDown`, `PaymentServiceDown`,
`AnyMicroserviceDown`, `HighErrorRate`, and `HighRequestLatency` are loaded.

Open Grafana:

```text
http://localhost:3000
```

Go to the `SRE Microservices Overview` dashboard and confirm availability,
request rate, latency, CPU, and memory panels show data.

## 3. Load and Capacity Test

Run:

```bash
REQUESTS=300 CONCURRENCY=20 PAYMENT_REQUESTS=100 ./scripts/load-test.sh
```

During the test, watch Grafana:

- request rate should increase
- Order and Payment services should show traffic
- CPU and memory panels should show resource usage
- error rate should stay low in normal operation

Use this output and Grafana metrics for the capacity planning section.

## 4. Incident Simulation Test

Start the broken Order Service configuration:

```bash
docker compose -f docker-compose.yml -f docker-compose.incident.yml up -d order-service
```

Check impact:

```bash
docker compose ps
docker compose logs order-service
./scripts/inspect-logs.sh order-service
```

Expected result:

- Order Service becomes unhealthy or unavailable
- order creation fails
- Prometheus/Grafana show the service problem
- logs mention the broken database hostname

Restore:

```bash
docker compose up -d order-service
curl http://localhost:8004/health
./scripts/smoke-test.sh
```

Expected result:

- Order Service health returns to `ok`
- order and payment creation work again
- Prometheus target returns to `UP`

## 5. Docker Swarm Test

Build local images:

```bash
docker compose build
docker image tag fastapi-microservices-master-auth-service:latest sre-auth-service:latest
docker image tag fastapi-microservices-master-user-service:latest sre-user-service:latest
docker image tag fastapi-microservices-master-product-service:latest sre-product-service:latest
docker image tag fastapi-microservices-master-order-service:latest sre-order-service:latest
docker image tag fastapi-microservices-master-payment-service:latest sre-payment-service:latest
docker image tag fastapi-microservices-master-chat-service:latest sre-chat-service:latest
docker image tag fastapi-microservices-master-frontend:latest sre-frontend:latest
```

Initialize Swarm and deploy:

```bash
docker swarm init
docker stack deploy -c docker-stack.yml sre-assignment
docker stack services sre-assignment
```

Expected result:

- `order-service` has 2 replicas
- `payment-service` has 2 replicas
- other services are running

Clean up after the Swarm test:

```bash
docker stack rm sre-assignment
docker swarm leave --force
```

## 6. Kubernetes Manifest Test

Validate manifests locally without a cluster:

```bash
./scripts/validate-k8s-manifests.sh
```

This local validator is enough to prove that the repository contains valid
Kubernetes manifest artifacts. It does not require a running cluster.

Before using `kubectl apply`, make sure `kubectl` has a real cluster context:

```bash
kubectl config get-contexts
kubectl config current-context
kubectl cluster-info
```

If `current-context is not set`, then Kubernetes is not configured yet. In that
case, enable Kubernetes in Docker Desktop, start minikube/kind, or use the k3s
cluster installed by Ansible on a VM.

If you have Docker Desktop Kubernetes, minikube, kind, or k3s running and a
current context is selected:

```bash
kubectl apply --dry-run=client -f k8s/
kubectl apply -f k8s/
kubectl get all -n sre-microservices
kubectl get hpa -n sre-microservices
```

Expected result:

- deployments exist for PostgreSQL, frontend, and all six backend services
- services exist for routing
- HPA exists for `order-service` and `payment-service`

Clean up:

```bash
kubectl delete namespace sre-microservices
```

If `kubectl apply` fails with an OpenAPI error like `failed to download openapi`
or tries to connect to `localhost:8080`, the manifests are not the problem. It
means `kubectl` is not connected to a Kubernetes API server.

## 7. Terraform Test

```bash
cd terraform-gcp
terraform init
terraform fmt -check
terraform validate
terraform plan
cd ..
```

Expected result:

- Terraform validates
- plan shows a Google Cloud Compute Engine VM and firewall rules

Use the Google Cloud project configured in `terraform-gcp/terraform.tfvars`.

## 8. Ansible Test

Create or provision a Linux VM first. Terraform can create this VM. Then copy
the sample inventory:

```bash
cp ansible/inventory.example.ini ansible/inventory.ini
```

Edit `ansible/inventory.ini`:

- replace `CHANGE_ME` in `ansible_host`
- replace `repo_url` with your GitHub repository URL
- keep `install_kubernetes=true`

Example:

```ini
[sre_nodes]
sre-vm ansible_host=34.123.45.67 ansible_user=student

[sre_nodes:vars]
app_dir=/opt/sre-microservices
repo_url=https://github.com/your-user/fastapi-microservices-master.git
install_kubernetes=true
deploy_kubernetes_manifests=false
```

First test SSH manually:

```bash
ssh student@34.123.45.67
```

If SSH does not connect, Ansible will not connect either.

Check syntax:

```bash
ANSIBLE_LOCAL_TEMP=/private/tmp ANSIBLE_REMOTE_TEMP=/tmp \
ansible-playbook --syntax-check -i ansible/inventory.ini ansible/deploy.yml
```

Deploy:

```bash
ANSIBLE_LOCAL_TEMP=/private/tmp ANSIBLE_REMOTE_TEMP=/tmp \
ansible-playbook -i ansible/inventory.ini ansible/deploy.yml
```

Expected result:

- Docker is installed
- k3s/Kubernetes is installed
- repository is cloned to `/opt/sre-microservices`
- Compose config is validated
- Kubernetes manifests are validated
- Docker Compose stack is deployed
- monitoring stack is running

To also apply Kubernetes manifests from Ansible, set:

```ini
deploy_kubernetes_manifests=true
```

Then run the playbook again.

## 9. Final PDF

For the final submission, export the project report to PDF and include the Git
repository link. The system can be verified with the commands in this guide.
