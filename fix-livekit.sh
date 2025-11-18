#!/bin/bash

echo "🔧 Complete Fix: LiveKit + API Health"
echo "======================================"

# Stop everything
echo ""
echo "1️⃣ Stopping all containers..."
sudo docker-compose down

# Remove old LiveKit images
echo ""
echo "2️⃣ Cleaning up old LiveKit images..."
sudo docker rm -f fluentfly-livekit 2>/dev/null || true
sudo docker rmi livekit/livekit-server:latest 2>/dev/null || true
sudo docker rmi livekit/livekit-server:v1.5.3 2>/dev/null || true

# Pull stable LiveKit version
echo ""
echo "3️⃣ Pulling stable LiveKit v1.5.3..."
sudo docker pull livekit/livekit-server:v1.5.3

# Rebuild API (for health check fix)
echo ""
echo "4️⃣ Rebuilding API container..."
sudo docker-compose build api

# Start all services
echo ""
echo "5️⃣ Starting all services..."
sudo docker-compose up -d

# Wait for services
echo ""
echo "6️⃣ Waiting 30 seconds for services to initialize..."
for i in {30..1}; do
  echo -ne "   $i seconds remaining...\r"
  sleep 1
done
echo ""

# Check status
echo ""
echo "📊 Service Status:"
echo "=================="
sudo docker-compose ps

echo ""
echo "🔍 LiveKit Logs (last 15 lines):"
echo "================================="
sudo docker logs fluentfly-livekit --tail 15

echo ""
echo "🔍 API Logs (last 10 lines):"
echo "============================="
sudo docker logs fluentfly-api --tail 10

echo ""
echo "🧪 Testing Endpoints:"
echo "===================="
echo -n "API Health: "
curl -s http://localhost:3000/api/health > /dev/null && echo "✅ OK" || echo "❌ FAILED"
echo -n "LiveKit: "
curl -s http://localhost:7880 > /dev/null && echo "✅ OK" || echo "❌ FAILED"

echo ""
echo "✅ Fix complete! Check status above."
echo ""
echo "If LiveKit still fails, run: sudo docker logs fluentfly-livekit"
