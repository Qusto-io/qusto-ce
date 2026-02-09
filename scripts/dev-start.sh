#!/bin/bash
# ===========================================
# Start Qusto Development Services
# Quick start for daily development
# ===========================================

set -e

echo "🚀 Starting Qusto Development Services..."

# Check Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Start services
docker compose up -d

# Quick health check
echo "⏳ Checking services..."
sleep 3

# Verify services
if curl -s http://localhost:8123/ping > /dev/null; then
    echo "✅ ClickHouse: Running"
else
    echo "❌ ClickHouse: Not responding"
fi

if docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ PostgreSQL: Running"
else
    echo "❌ PostgreSQL: Not responding"
fi

if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis: Running"
else
    echo "❌ Redis: Not responding"
fi

echo ""
echo "🎯 Ready for development!"
echo "   Start Phoenix: mix phx.server"
