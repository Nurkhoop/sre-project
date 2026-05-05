#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"

required_vars=(
  DB_HOST
  DB_PORT
  DB_NAME
  DB_USER
  DB_PASSWORD
  USER_SERVICE_URL
  PRODUCT_SERVICE_URL
)

if [ -f "${ROOT_DIR}/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
  set +a
fi

DB_HOST="${DB_HOST:-app-db}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-app_db_dev}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
USER_SERVICE_URL="${USER_SERVICE_URL:-http://user-service:8000}"
PRODUCT_SERVICE_URL="${PRODUCT_SERVICE_URL:-http://product-service:8000}"

echo "Validating required environment variables..."
for var_name in "${required_vars[@]}"; do
  if [ -z "${!var_name:-}" ]; then
    echo "ERROR: ${var_name} is empty or undefined"
    exit 1
  fi
done

echo "Checking database port format..."
if ! [[ "${DB_PORT}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: DB_PORT must be numeric"
  exit 1
fi

echo "Checking service URL formats..."
for service_url in "${USER_SERVICE_URL}" "${PRODUCT_SERVICE_URL}"; do
  if ! [[ "${service_url}" =~ ^https?:// ]]; then
    echo "ERROR: ${service_url} must start with http:// or https://"
    exit 1
  fi
done

echo "Rendering Docker Compose configuration..."
docker compose -f "${COMPOSE_FILE}" config >/dev/null

echo "Configuration validation passed."
