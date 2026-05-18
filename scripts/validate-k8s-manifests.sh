#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

allowed_kinds="ConfigMap Deployment HorizontalPodAutoscaler Namespace Secret Service"
found=0

for path in k8s/*.yaml; do
  [ -e "${path}" ] || continue
  [ "$(basename "${path}")" = "kustomization.yaml" ] && continue
  found=1

  api_version="$(awk -F': *' '$1 == "apiVersion" {print $2; exit}' "${path}")"
  kind="$(awk -F': *' '$1 == "kind" {print $2; exit}' "${path}")"
  metadata="$(awk -F': *' '$1 == "metadata" {print $1; exit}' "${path}")"

  if [ -z "${api_version}" ] || [ -z "${kind}" ] || [ -z "${metadata}" ]; then
    echo "ERROR: ${path} must have apiVersion, kind, and metadata"
    exit 1
  fi

  case " ${allowed_kinds} " in
    *" ${kind} "*) ;;
    *)
      echo "ERROR: ${path} has unsupported kind ${kind}"
      exit 1
      ;;
  esac

  echo "OK: ${path} => ${kind}"
done

if [ "${found}" -eq 0 ]; then
  echo "ERROR: no Kubernetes manifests found"
  exit 1
fi

for service in order-service payment-service; do
  hpa="k8s/${service}-hpa.yaml"
  if [ ! -f "${hpa}" ]; then
    echo "ERROR: missing ${hpa}"
    exit 1
  fi

  if ! grep -q "minReplicas: 2" "${hpa}"; then
    echo "ERROR: ${service} HPA must have minReplicas: 2"
    exit 1
  fi

  if ! grep -q "maxReplicas: 5" "${hpa}"; then
    echo "ERROR: ${service} HPA must have maxReplicas: 5"
    exit 1
  fi

  if ! grep -q "averageUtilization: 70" "${hpa}"; then
    echo "ERROR: ${service} HPA must target 70% CPU"
    exit 1
  fi
done

echo "Kubernetes manifest validation passed."
