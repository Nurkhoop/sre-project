#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ruby -e '
  require "yaml"

  required = {
    "k8s/namespace.yaml" => "Namespace",
    "k8s/order-service-configmap.yaml" => "ConfigMap",
    "k8s/order-service-secret.yaml" => "Secret",
    "k8s/order-service-deployment.yaml" => "Deployment",
    "k8s/order-service-service.yaml" => "Service",
    "k8s/order-service-hpa.yaml" => "HorizontalPodAutoscaler"
  }

  required.each do |path, kind|
    document = YAML.load_file(path)
    unless document.is_a?(Hash)
      abort("ERROR: #{path} is not a YAML object")
    end
    unless document["apiVersion"] && document["metadata"] && document["kind"] == kind
      abort("ERROR: #{path} must be kind #{kind} with apiVersion and metadata")
    end
    puts "OK: #{path} => #{document["kind"]}"
  end

  hpa = YAML.load_file("k8s/order-service-hpa.yaml")
  target = hpa.dig("spec", "metrics", 0, "resource", "target", "averageUtilization")
  min_replicas = hpa.dig("spec", "minReplicas")
  max_replicas = hpa.dig("spec", "maxReplicas")

  unless target == 70 && min_replicas == 2 && max_replicas == 5
    abort("ERROR: HPA policy must scale from 2 to 5 replicas at 70% CPU")
  end

  puts "Kubernetes manifest validation passed."
' "$ROOT_DIR"
