#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090/-/healthy}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000/api/health}"

retry_curl() {
  local url="$1"
  local attempts="${2:-30}"
  local delay="${3:-2}"

  for attempt in $(seq 1 "${attempts}"); do
    if curl -fsS "${url}" >/dev/null; then
      return 0
    fi

    if [ "${attempt}" -lt "${attempts}" ]; then
      echo "Waiting for ${url} (${attempt}/${attempts})..."
      sleep "${delay}"
    fi
  done

  curl -fsS "${url}" >/dev/null
}

echo "Checking frontend gateway at ${BASE_URL}..."
retry_curl "${BASE_URL}/"

echo "Checking service health through Nginx..."
for service in auth users products orders payments chat; do
  echo "- ${service}"
  retry_curl "${BASE_URL}/health/${service}"
done

echo "Checking monitoring endpoints..."
retry_curl "${PROMETHEUS_URL}"
retry_curl "${GRAFANA_URL}"

echo "Creating test user..."
curl -fsS -X POST "${BASE_URL}/api/users/" \
  -H "Content-Type: application/json" \
  -d '{"username":"smoke-user","email":"smoke-user@example.com"}' >/dev/null || true

echo "Creating test order..."
order_response="$(curl -fsS -X POST "${BASE_URL}/api/orders/" \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"product_id":1,"quantity":1}')"
echo "${order_response}"

echo "Creating test payment..."
curl -fsS -X POST "${BASE_URL}/api/payments/" \
  -H "Content-Type: application/json" \
  -d '{"order_id":1,"amount":25.00,"method":"card"}'

echo
echo "Smoke test passed."
