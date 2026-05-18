# Ansible Deployment Automation

This folder provides the configuration management artifact for the end-term SRE
project. The playbook prepares a Linux VM, installs Docker, installs Docker
Compose v2 as a CLI plugin, installs Kubernetes through k3s, pulls the project
repository, validates Compose and Kubernetes configuration, and starts the
application plus monitoring stack.

## Usage

1. Copy `inventory.example.ini` to `inventory.ini`.
2. Replace `CHANGE_ME` values with the VM public IP and Git repository URL.
3. Run:

```bash
ansible-playbook -i ansible/inventory.ini ansible/deploy.yml
```

Example `inventory.ini`:

```ini
[sre_nodes]
sre-vm ansible_host=34.123.45.67 ansible_user=student

[sre_nodes:vars]
app_dir=/opt/sre-microservices
repo_url=https://github.com/your-user/fastapi-microservices-master.git
install_kubernetes=true
deploy_kubernetes_manifests=false
```

Before running the full playbook, verify SSH access:

```bash
ssh student@34.123.45.67
```

If your cloud VM uses another username, replace `student` with that username.
Common usernames are `ubuntu`, `debian`, `student`, or your cloud account user.

If Ansible prints `Could not resolve hostname change_me`, the inventory file
still contains the placeholder and must be edited.

By default, the playbook installs k3s and validates Kubernetes manifests. It
does not apply the Kubernetes manifests automatically because the Docker Compose
stack is the main demo runtime. To apply the Kubernetes manifests too, set:

```ini
deploy_kubernetes_manifests=true
```

in `ansible/inventory.ini`.

## CI/CD Deployment

CI and image publishing do not require VM access. The GitHub Actions `CI`
workflow validates configuration and builds images, while `Release Images`
publishes service images to GitHub Container Registry.

The `Deploy` workflow is intentionally manual-only. It creates a temporary
`ansible/inventory.ci.ini` file and runs this playbook against the VM only after
the VM owner or repository admin adds deployment secrets.

The GitHub Actions inventory sets `install_kubernetes=false` because Compose is
the production deployment path and Kubernetes validation requires extra tools on
the VM. Kubernetes manifests remain available as optional artifacts.

Required repository secrets:

- `VM_HOST`: public IP address or DNS name of the VM.
- `VM_USER`: SSH username for the VM.
- `VM_SSH_PRIVATE_KEY`: private SSH key with access to the VM.

Recommended repository variables:

- `APP_DIR`: deployment directory on the VM, for example `/opt/sre-microservices`.
- `DEPLOY_BRANCH`: Git branch checked out on the VM, normally `main`.

The playbook accepts these CI/CD variables:

```bash
ansible-playbook -i ansible/inventory.ci.ini ansible/deploy.yml \
  --extra-vars "repo_version=main image_repository=ghcr.io/nurkhoop/sre-project image_tag=latest"
```

If VM secrets are not available, the VM owner can deploy published images
manually on the server:

```bash
IMAGE_TAG=latest docker compose \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  -f docker-compose.images.yml \
  pull

IMAGE_TAG=latest docker compose \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  -f docker-compose.images.yml \
  up -d --no-build
```

For rollback, rerun the manual `Deploy` workflow or the VM commands with a
previous immutable image tag such as `main-abc1234` or `v1.0.0`.

## Covered SRE Criteria

- Configuration management
- Automated dependency installation
- Docker Compose v2 plugin installation without relying on the apt package name
- Kubernetes installation with k3s
- Automated deployment
- Monitoring stack deployment
- Kubernetes manifest validation and optional apply
- Repeatable recovery after VM reprovisioning
- CI/CD deployment using published immutable container images
- Rollback by redeploying a previous image tag
