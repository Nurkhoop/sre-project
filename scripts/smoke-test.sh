#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"

echo "Checking frontend gateway at ${BASE_URL}..."
curl -fsS "${BASE_URL}/" >/dev/null

echo "Checking service health through Nginx..."
for service in auth users products orders payments chat; do
  echo "- ${service}"
  curl -fsS "${BASE_URL}/health/${service}" >/dev/null
done

echo "Checking monitoring endpoints..."
curl -fsS "http://localhost:9090/-/healthy" >/dev/null
curl -fsS "http://localhost:3000/api/health" >/dev/null

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
