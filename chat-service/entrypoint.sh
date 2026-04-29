#!/bin/sh
set -e

echo "Waiting for PostgreSQL..."
while ! nc -z app-db 5432; do
    sleep 0.2
done
echo "PostgreSQL is ready"

exec "$@"
