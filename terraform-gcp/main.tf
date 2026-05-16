terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_firewall" "sre_microservices" {
  name    = "${var.project_name}-firewall"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3000", "8001-8006", "9090"]
  }

  source_ranges = [var.allowed_source_cidr]
  target_tags   = [var.network_tag]
}

resource "google_compute_instance" "sre_microservices" {
  name         = var.project_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [var.network_tag]

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = var.network

    access_config {
      // Ephemeral public IP.
    }
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y docker.io docker-compose-plugin git
    systemctl enable docker
    systemctl start docker
    id -u ${var.ssh_user} >/dev/null 2>&1 && usermod -aG docker ${var.ssh_user} || true
  SCRIPT
}
