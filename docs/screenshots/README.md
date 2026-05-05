# Screenshot Plan for Final PDF

Save screenshots in this folder with these filenames.

## 1. Project and Code Structure

- `01-project-structure.png`: File tree showing `auth-service`, `user-service`, `product-service`, `order-service`, `chat-service`, `frontend`, `monitoring`, `terraform`, and `docs`.
- `02-docker-compose-file.png`: `docker-compose.yml` showing services, healthchecks, Prometheus, Grafana, and PostgreSQL.
- `03-terraform-files.png`: Terraform folder showing `main.tf`, `variables.tf`, `outputs.tf`, and `terraform.tfvars`.

## 2. Normal System Operation

- `04-docker-compose-up.png`: Terminal after `docker compose up --build -d`.
  On a cloud VM, use `docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d`.
- `05-running-containers.png`: Terminal after `docker compose ps`, with containers healthy/running.
- `06-frontend-home.png`: Frontend at `http://localhost:8080` showing service health cards.
- `07-auth-register-login.png`: Frontend after successful register/login, showing username, role, and token.
- `08-user-created.png`: Frontend after creating a user profile.
- `09-products-visible.png`: Frontend showing the product cards.
- `10-order-created.png`: Frontend after successful order creation.
- `11-chat-message-created.png`: Frontend after sending a chat message.

## 3. API and Health Checks

- `12-api-docs-auth.png`: `http://localhost:8001/docs`.
- `13-api-docs-order.png`: `http://localhost:8004/docs`.
- `14-health-endpoints.png`: Terminal with successful curl results for all `/health` endpoints.
- `15-metrics-endpoint.png`: Browser or terminal showing one `/metrics` endpoint.

## 4. Monitoring

- `16-prometheus-targets-up.png`: `http://localhost:9090/targets` showing all service targets `UP`.
- `17-prometheus-alert-rules.png`: `http://localhost:9090/rules` showing alert rules.
- `18-grafana-dashboard.png`: Grafana dashboard `SRE Microservices Overview`.
- `18a-config-validation.png`: Terminal showing successful `./scripts/validate-config.sh`.
- `18b-load-test-running.png`: Terminal showing `./scripts/load-test.sh` output with request status counts and approximate RPS.
- `18c-grafana-under-load.png`: Grafana dashboard showing request rate, latency, CPU, and memory during load.
- `18d-log-inspection.png`: Terminal showing `./scripts/inspect-logs.sh order-service`.
- `18e-kubernetes-hpa.png`: `k8s/order-service-hpa.yaml` showing CPU-based HPA policy.
- `18f-kubernetes-dry-run.png`: Optional terminal output from `kubectl apply --dry-run=client -f k8s/`.
- `18g-kubernetes-local-validation.png`: Terminal output from `./scripts/validate-k8s-manifests.sh` if no cluster is configured.

## 5. Incident Simulation

- `19-start-incident-command.png`: Terminal command starting the incident override.
- `20-order-service-failure-logs.png`: `docker compose logs order-service` showing DB hostname failure.
- `21-prometheus-order-down.png`: Prometheus targets showing Order Service down/unhealthy.
- `22-grafana-incident.png`: Grafana dashboard showing Order Service availability problem.
- `23-frontend-order-fails.png`: Frontend order creation failing during the incident.

## 6. Restoration

- `24-restore-order-service.png`: Terminal command restoring normal `order-service`.
- `25-order-health-restored.png`: `curl http://localhost:8004/health` returning ok.
- `26-prometheus-all-up-after-restore.png`: Prometheus targets all `UP` again.
- `27-order-created-after-restore.png`: Frontend successful order creation after recovery.

## 7. Terraform

- `28-terraform-init.png`: Successful `terraform init`.
- `29-terraform-validate.png`: Successful `terraform validate`.
- `30-terraform-plan.png`: `terraform plan` showing planned EC2/security group resources.
- `31-terraform-outputs.png`: Terraform outputs or output definitions showing public IP, frontend URL, Grafana URL, and Prometheus URL.

If you use Google Cloud instead of AWS, take the same screenshots from `terraform-gcp/`.
The plan should show a Compute Engine VM and firewall rules for `22`, `80`, `3000`, and `9090`.
