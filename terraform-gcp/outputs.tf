output "instance_name" {
  description = "Name of the provisioned VM."
  value       = google_compute_instance.sre_microservices.name
}

output "instance_public_ip" {
  description = "Public IP address of the provisioned VM."
  value       = google_compute_instance.sre_microservices.network_interface[0].access_config[0].nat_ip
}

output "frontend_url" {
  description = "HTTP URL for the deployed frontend."
  value       = "http://${google_compute_instance.sre_microservices.network_interface[0].access_config[0].nat_ip}"
}

output "grafana_url" {
  description = "Grafana URL."
  value       = "http://${google_compute_instance.sre_microservices.network_interface[0].access_config[0].nat_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus URL."
  value       = "http://${google_compute_instance.sre_microservices.network_interface[0].access_config[0].nat_ip}:9090"
}
