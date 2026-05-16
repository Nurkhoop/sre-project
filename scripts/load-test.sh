#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
CONCURRENCY="${CONCURRENCY:-10}"
REQUESTS="${REQUESTS:-100}"
PAYMENT_REQUESTS="${PAYMENT_REQUESTS:-50}"

echo "Preparing load-test data through frontend API gateway at ${BASE_URL}..."
curl -fsS -X POST "${BASE_URL}/api/users/" \
  -H "Content-Type: application/json" \
  -d '{"username":"load-user","email":"load-user@example.com"}' >/dev/null || true

echo "Running ${REQUESTS} order requests with concurrency ${CONCURRENCY}..."
start_epoch="$(date +%s)"

seq 1 "${REQUESTS}" | xargs -P "${CONCURRENCY}" -I{} sh -c '
  code="$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$0/api/orders/" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\":1,\"product_id\":1,\"quantity\":1}")"
  printf "%s\n" "$code"
' "${BASE_URL}" | sort | uniq -c

end_epoch="$(date +%s)"
duration=$((end_epoch - start_epoch))
if [ "${duration}" -lt 1 ]; then
  duration=1
fi

echo "Approximate generated RPS: $((REQUESTS / duration))"
echo "Creating baseline order for payment load..."
curl -fsS -X POST "${BASE_URL}/api/orders/" \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"product_id":1,"quantity":1}' >/dev/null || true

echo "Running ${PAYMENT_REQUESTS} payment requests with concurrency ${CONCURRENCY}..."
seq 1 "${PAYMENT_REQUESTS}" | xargs -P "${CONCURRENCY}" -I{} sh -c '
  code="$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$0/api/payments/" \
    -H "Content-Type: application/json" \
    -d "{\"order_id\":1,\"amount\":25.00,\"method\":\"card\"}")"
  printf "%s\n" "$code"
' "${BASE_URL}" | sort | uniq -c

echo "Check Prometheus/Grafana for request rate, error rate, CPU, memory, and latency impact."
