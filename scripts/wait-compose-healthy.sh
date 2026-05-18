#!/usr/bin/env bash
set -euo pipefail

TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-180}"
SLEEP_SECONDS="${SLEEP_SECONDS:-5}"

services=(
  auth-service
  user-service
  product-service
  order-service
  payment-service
  chat-service
  frontend
  app-db
  prometheus
  grafana
)

deadline=$((SECONDS + TIMEOUT_SECONDS))

while true; do
  pending=()

  for service in "${services[@]}"; do
    container_id="$(docker compose ps -q "${service}")"
    if [ -z "${container_id}" ]; then
      pending+=("${service}:missing")
      continue
    fi

    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${container_id}")"
    if [ "${status}" != "healthy" ]; then
      pending+=("${service}:${status}")
    fi
  done

  if [ "${#pending[@]}" -eq 0 ]; then
    echo "All expected Compose services are healthy."
    exit 0
  fi

  if [ "${SECONDS}" -ge "${deadline}" ]; then
    echo "Timed out waiting for healthy Compose services:"
    printf '  %s\n' "${pending[@]}"
    docker compose ps
    exit 1
  fi

  echo "Waiting for healthy Compose services: ${pending[*]}"
  sleep "${SLEEP_SECONDS}"
done
