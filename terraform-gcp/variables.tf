variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "project_name" {
  description = "Name used for the VM and firewall resources."
  type        = string
  default     = "sre-microservices-assignment"
}

variable "region" {
  description = "Google Cloud region."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Google Cloud zone."
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Compute Engine VM machine type."
  type        = string
  default     = "e2-medium"
}

variable "boot_image" {
  description = "Boot image for the VM."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 20
}

variable "network" {
  description = "VPC network name."
  type        = string
  default     = "default"
}

variable "network_tag" {
  description = "Network tag used by the firewall rule."
  type        = string
  default     = "sre-microservices"
}

variable "allowed_source_cidr" {
  description = "CIDR allowed to access SSH, HTTP, Grafana, backend demo APIs, and Prometheus."
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_user" {
  description = "Linux username used for SSH access."
  type        = string
  default     = "student"
}
