#!/bin/bash

echo "=== Fixing Docker Compose ContainerConfig Error ==="

# Stop all containers
echo "1. Stopping all containers..."
docker-compose down

# Remove the problematic container
echo "2. Removing old container..."
docker rm -f fluentfly-api 2>/dev/null || true

# Remove the image to force a clean rebuild
echo "3. Removing old image..."
docker rmi fluentfly-ai_api 2>/dev/null || true

# Clean up dangling images
echo "4. Cleaning up dangling images..."
docker image prune -f

# Rebuild and start
echo "5. Rebuilding and starting services..."
docker-compose up -d --build --force-recreate

echo ""
echo "=== Done! Checking status ==="
docker-compose ps
