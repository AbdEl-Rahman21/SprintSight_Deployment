#!/bin/bash
set -e

echo "Restoring PostgreSQL dump..."

pg_restore \
  --data-only \
  --no-owner \
  --no-privileges \
  --disable-triggers \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  /docker-entrypoint-initdb.d/03-data.dump

echo "Restore completed."

