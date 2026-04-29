# Google Cloud Terraform Deployment

This folder is the Google Cloud version of Assignment 5.

It provisions:

- One Compute Engine VM
- Firewall access for:
  - SSH `22`
  - HTTP `80`
  - Grafana `3000`
  - Prometheus `9090`
- Public IP outputs

## Prerequisites

1. Create or select a Google Cloud project.
2. Enable billing for the project.
3. Enable the Compute Engine API.
4. Install and authenticate the Google Cloud CLI:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

Terraform uses Application Default Credentials from `gcloud auth application-default login`.

## Configure Variables

Edit `terraform.tfvars`:

```hcl
project_id = "your-google-cloud-project-id"
zone       = "us-central1-a"
```

For better SSH security, replace:

```hcl
allowed_source_cidr = "0.0.0.0/0"
```

with your own public IP:

```bash
curl ifconfig.me
```

Example:

```hcl
allowed_source_cidr = "93.185.10.20/32"
```

## Terraform Commands

```bash
cd terraform-gcp
terraform init
terraform validate
terraform plan
terraform apply
```

After apply, Terraform prints:

- `instance_public_ip`
- `frontend_url`
- `grafana_url`
- `prometheus_url`

## Deploy the Application on the VM

SSH into the VM from Google Cloud Console or from your terminal:

```bash
gcloud compute ssh student@sre-microservices-assignment --zone us-central1-a
```

Clone the repository and start Docker Compose:

```bash
git clone YOUR_REPOSITORY_URL
cd fastapi-microservices-master
docker compose up --build -d
docker compose ps
```

For public cloud access on port `80`, either change the frontend port mapping in
`docker-compose.yml` from `8080:80` to `80:80`, or run:

```bash
docker compose up --build -d
```

and access the frontend with:

```text
http://PUBLIC_IP:8080
```

If your assignment strictly expects HTTP on port `80`, use this temporary override:

```bash
docker compose up --build -d
docker compose stop frontend
docker run -d --name sre-frontend-public --network fastapi-microservices-master_default -p 80:80 fastapi-microservices-master-frontend
```

## Cleanup

To avoid cloud charges:

```bash
terraform destroy
```
