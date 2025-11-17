#!/bin/bash
set -e

echo "Starting database initialization..."

# Wait for PostgreSQL to be ready
until pg_isready -h localhost -U postgres; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "PostgreSQL is ready!"

# Run schema creation
echo "Creating database schema..."
psql -U postgres -d fluentfly -f /docker-entrypoint-initdb.d/01-schema.sql

# Run seed data
echo "Seeding database..."
psql -U postgres -d fluentfly -f /docker-entrypoint-initdb.d/02-seed.sql

echo "Database initialization complete!"
