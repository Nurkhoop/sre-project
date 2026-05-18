# Kubernetes Auto-Scaling Artifact

This folder provides Kubernetes implementation artifacts for Assignment 6.
It is not required for the local Docker Compose deployment, but it demonstrates
how the full application stack can be integrated with an orchestration platform.
Order and Payment also include CPU-based auto-scaling policies.

## Files

- `namespace.yaml`: isolated namespace for the assignment.
- `app-db-*.yaml`: PostgreSQL deployment, secret, and service.
- `auth-service-*.yaml`: Authentication Service deployment and service.
- `user-service-*.yaml`: User Service deployment and service.
- `product-service-*.yaml`: Product Service deployment and service.
- `order-service-configmap.yaml`: non-secret runtime configuration.
- `order-service-secret.yaml`: database password.
- `order-service-deployment.yaml`: Order Service deployment with probes and resource requests/limits.
- `order-service-service.yaml`: internal service discovery for Order Service.
- `order-service-hpa.yaml`: Horizontal Pod Autoscaler.
- `payment-service-configmap.yaml`: non-secret runtime configuration.
- `payment-service-secret.yaml`: database password.
- `payment-service-deployment.yaml`: Payment Service deployment with probes and resource requests/limits.
- `payment-service-service.yaml`: internal service discovery for Payment Service.
- `payment-service-hpa.yaml`: Horizontal Pod Autoscaler.
- `chat-service-*.yaml`: Chat Service deployment and service.
- `frontend-*.yaml`: Nginx frontend deployment and NodePort service.

## Auto-Scaling Policy

The HPA policy scales `order-service` and `payment-service` between 2 and 5
replicas when average CPU utilization crosses 70%.

```yaml
minReplicas: 2
maxReplicas: 5
averageUtilization: 70
```

## Validation Command

Validate manifests locally without a cluster:

```bash
./scripts/validate-k8s-manifests.sh
```

If `kubectl` is installed and connected to a real Kubernetes context, validate
manifests without deploying:

```bash
kubectl apply --dry-run=client -f k8s/
```

Check the current context with:

```bash
kubectl config current-context
kubectl cluster-info
```

For a real cluster, Kubernetes Metrics Server must be installed for CPU-based
HPA decisions.

## Production Image Overlay

The root `k8s/kustomization.yaml` keeps the existing plain manifests renderable
with Kustomize. The `k8s/base` directory mirrors those manifests so the nested
production overlay can render with default Kustomize load restrictions. The
optional production overlay rewrites local demo images to GitHub Container
Registry images and sets application image pull policy to `Always`.

Render the production manifests:

```bash
kubectl kustomize k8s/overlays/prod
```

Apply them to a configured cluster:

```bash
kubectl apply -k k8s/overlays/prod
```

Check application rollout status:

```bash
kubectl rollout status deployment/auth-service -n sre-microservices
kubectl rollout status deployment/frontend -n sre-microservices
```

The Compose deployment remains the primary runtime path for this project. The
Kustomize overlay is provided as an optional Kubernetes CD artifact.
