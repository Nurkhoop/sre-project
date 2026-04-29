output "instance_public_ip" {
  description = "Public IP address of the provisioned VM."
  value       = aws_instance.sre_microservices.public_ip
}

output "frontend_url" {
  description = "HTTP URL for the deployed frontend."
  value       = "http://${aws_instance.sre_microservices.public_ip}"
}

output "grafana_url" {
  description = "Grafana URL."
  value       = "http://${aws_instance.sre_microservices.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus URL."
  value       = "http://${aws_instance.sre_microservices.public_ip}:9090"
}
