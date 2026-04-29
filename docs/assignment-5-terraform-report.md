# Assignment 5: Terraform Implementation Report

## Objective

Terraform is used to provision a reproducible VM environment for the containerized
microservices system.

## Implemented Files

- `terraform/main.tf`
- `terraform/variables.tf`
- `terraform/outputs.tf`
- `terraform/terraform.tfvars`

## Provisioned Infrastructure

The AWS Terraform configuration provisions:

- One AWS EC2 virtual machine
- Security group allowing:
  - SSH on port `22`
  - HTTP on port `80`
  - Grafana on port `3000`
  - Prometheus on port `9090`
- Public IP output

## Reproducibility Commands

```bash
cd terraform
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

The provided `terraform.tfvars` contains placeholders. Replace the AMI ID,
EC2 key pair, and SSH CIDR before applying in a real AWS account.

For local validation, the configuration was checked with:

```bash
terraform fmt -check
terraform validate
```

## Google Cloud Alternative

The project also includes `terraform-gcp/` for Google Cloud Compute Engine.
This version provisions:

- One Compute Engine VM
- Firewall rules for ports `22`, `80`, `3000`, and `9090`
- Public IP output

Commands:

```bash
cd terraform-gcp
terraform init
terraform plan
terraform apply
```

This option can be used when the deployment server is a Google Cloud VM.
