#!/bin/sh
set -e

DB_HOST="${DB_HOST:-app-db}"
DB_PORT="${DB_PORT:-5432}"

echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
while ! nc -z "$DB_HOST" "$DB_PORT"; do
    sleep 0.2
done
echo "PostgreSQL is ready"

exec "$@"
