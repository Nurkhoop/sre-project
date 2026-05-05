# Kubernetes Auto-Scaling Artifact

This folder provides a Kubernetes implementation artifact for Assignment 6.
It is not required for the local Docker Compose deployment, but it demonstrates
how the Order Service can be integrated with an orchestration platform and
scaled automatically using CPU thresholds.

## Files

- `namespace.yaml`: isolated namespace for the assignment.
- `order-service-configmap.yaml`: non-secret runtime configuration.
- `order-service-secret.yaml`: database password.
- `order-service-deployment.yaml`: Order Service deployment with probes and resource requests/limits.
- `order-service-service.yaml`: internal service discovery for Order Service.
- `order-service-hpa.yaml`: Horizontal Pod Autoscaler.

## Auto-Scaling Policy

The HPA policy scales `order-service` between 2 and 5 replicas when average CPU
utilization crosses 70%.

```yaml
minReplicas: 2
maxReplicas: 5
averageUtilization: 70
```

## Validation Command

If `kubectl` is installed, validate manifests without deploying:

```bash
kubectl apply --dry-run=client -f k8s/
```

If there is no Kubernetes cluster configured, use the local manifest validator:

```bash
./scripts/validate-k8s-manifests.sh
```

For a real cluster, Kubernetes Metrics Server must be installed for CPU-based
HPA decisions.
