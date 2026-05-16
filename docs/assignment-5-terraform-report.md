# Assignment 5: Terraform Implementation Report

## Objective

Terraform is used to provision a reproducible Google Cloud VM environment for
the containerized microservices system.

## Implemented Files

- `terraform-gcp/main.tf`
- `terraform-gcp/variables.tf`
- `terraform-gcp/outputs.tf`
- `terraform-gcp/terraform.tfvars`

## Provisioned Infrastructure

The Google Cloud Terraform configuration provisions:

- One Compute Engine virtual machine
- Firewall rule allowing:
  - SSH on port `22`
  - HTTP frontend on port `80`
  - Backend API demo ports `8001-8006`
  - Grafana on port `3000`
  - Prometheus on port `9090`
- Public IP output

## Reproducibility Commands

```bash
cd terraform-gcp
terraform init
terraform plan
terraform apply
```

## Outputs

Terraform prints:

- `instance_public_ip`
- `frontend_url`
- `grafana_url`
- `prometheus_url`

## Notes

The provided `terraform-gcp/terraform.tfvars` contains the Google Cloud project,
zone, VM size, network, firewall, and SSH username settings for this deployment.
Adjust these values before applying in another Google Cloud project.

For local validation, the configuration can be checked with:

```bash
cd terraform-gcp
terraform fmt -check
terraform validate
```
