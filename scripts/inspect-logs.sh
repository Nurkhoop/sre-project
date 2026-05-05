#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-order-service}"
LINES="${LINES:-200}"

patterns=(
  "could not translate host name"
  "connection refused"
  "Connection refused"
  "timeout"
  "Traceback"
  "ERROR"
  "Restarting"
)

echo "Inspecting recent logs for ${SERVICE}..."
logs="$(docker compose logs --tail "${LINES}" "${SERVICE}" 2>&1 || true)"

if [ -z "${logs}" ]; then
  echo "No logs returned for ${SERVICE}."
  exit 0
fi

found=0
for pattern in "${patterns[@]}"; do
  if grep -F -i "${pattern}" <<<"${logs}" >/dev/null; then
    echo
    echo "Matched pattern: ${pattern}"
    grep -F -i "${pattern}" <<<"${logs}" || true
    found=1
  fi
done

restart_count="$(docker inspect -f '{{.RestartCount}}' "$(docker compose ps -q "${SERVICE}")" 2>/dev/null || echo "unknown")"
echo
echo "Docker restart count for ${SERVICE}: ${restart_count}"

if [ "${found}" -eq 0 ]; then
  echo "No known incident patterns found in the last ${LINES} log lines."
fi
