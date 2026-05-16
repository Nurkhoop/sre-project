#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ruby -e '
  require "yaml"

  allowed_kinds = [
    "ConfigMap",
    "Deployment",
    "HorizontalPodAutoscaler",
    "Namespace",
    "Secret",
    "Service"
  ]

  paths = Dir["k8s/*.yaml"].sort
  abort("ERROR: no Kubernetes manifests found") if paths.empty?

  paths.each do |path|
    document = YAML.load_file(path)
    unless document.is_a?(Hash)
      abort("ERROR: #{path} is not a YAML object")
    end
    unless document["apiVersion"] && document["metadata"] && allowed_kinds.include?(document["kind"])
      abort("ERROR: #{path} must have apiVersion, metadata, and an allowed kind")
    end
    puts "OK: #{path} => #{document["kind"]}"
  end

  ["order-service", "payment-service"].each do |service|
    hpa = YAML.load_file("k8s/#{service}-hpa.yaml")
    target = hpa.dig("spec", "metrics", 0, "resource", "target", "averageUtilization")
    min_replicas = hpa.dig("spec", "minReplicas")
    max_replicas = hpa.dig("spec", "maxReplicas")

    unless target == 70 && min_replicas == 2 && max_replicas == 5
      abort("ERROR: #{service} HPA policy must scale from 2 to 5 replicas at 70% CPU")
    end
  end

  puts "Kubernetes manifest validation passed."
' "$ROOT_DIR"
