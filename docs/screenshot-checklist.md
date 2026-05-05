# Screenshot Checklist

Use `docs/screenshots/README.md` as the full filename plan.

Minimum screenshots for a good final PDF:

- Project structure with five services.
- `docker compose ps` showing running/healthy containers.
- Frontend with service health cards.
- Successful auth, user creation, product display, order creation, and chat.
- Prometheus targets all `UP`.
- Prometheus alert rules.
- Grafana dashboard.
- Configuration validation script output.
- Load test script output.
- Grafana dashboard under load with CPU, memory, RPS, and latency panels.
- Log inspection script output for `order-service`.
- Kubernetes `order-service-hpa.yaml` showing CPU threshold auto-scaling.
- Optional `kubectl apply --dry-run=client -f k8s/` validation output.
- If there is no Kubernetes cluster, `./scripts/validate-k8s-manifests.sh` output.
- Incident command, failing Order Service logs, and monitoring showing the failure.
- Restoration command, Order Service health restored, and successful order after recovery.
- Terraform files, `terraform init`, `terraform validate`, and `terraform plan`.
