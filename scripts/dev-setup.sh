#!/bin/bash
# ===========================================
# Qusto Development Environment Setup Script
# Run this once after cloning the repository
# ===========================================

set -e

echo "🚀 Qusto Development Environment Setup"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker is running${NC}"

# Check Docker Compose version
if ! docker compose version > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker Compose not found. Please install Docker Desktop.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker Compose available${NC}"

# Create required directories
echo "📁 Creating directory structure..."
mkdir -p docker/postgres/init
mkdir -p docker/clickhouse/init
mkdir -p docker/clickhouse/config

# Copy .env if not exists
if [ ! -f .env ]; then
    if [ -f .env.development ]; then
        cp .env.development .env
        echo -e "${GREEN}✅ Created .env from .env.development${NC}"
    else
        echo -e "${YELLOW}⚠️  No .env file found. Create one from .env.development${NC}"
    fi
fi

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker compose down --remove-orphans 2>/dev/null || true

# Remove old volumes if requested
if [ "$1" == "--fresh" ]; then
    echo -e "${YELLOW}⚠️  Removing existing data volumes (--fresh flag)${NC}"
    docker volume rm qusto-postgres-data qusto-clickhouse-data qusto-redis-data 2>/dev/null || true
fi

# Pull latest images
echo "📦 Pulling Docker images..."
docker compose pull

# Start services
echo "🚀 Starting services..."
docker compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."

# Wait for PostgreSQL
echo -n "   PostgreSQL: "
until docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e " ${GREEN}Ready${NC}"

# Wait for ClickHouse
echo -n "   ClickHouse: "
until curl -s http://localhost:8123/ping > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e " ${GREEN}Ready${NC}"

# Wait for Redis
echo -n "   Redis: "
until docker compose exec -T redis redis-cli ping > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e " ${GREEN}Ready${NC}"

echo ""
echo -e "${GREEN}✅ All services are running!${NC}"
echo ""
echo "📊 Service Status:"
docker compose ps
echo ""
echo "🔗 Connection URLs:"
echo "   PostgreSQL: postgres://postgres:postgres@localhost:5432/plausible_dev"
echo "   ClickHouse: http://localhost:8123 (HTTP) / localhost:9000 (Native)"
echo "   Redis:      redis://localhost:6379"
echo "   Adminer:    http://localhost:8080 (run: docker compose --profile tools up -d)"
echo ""
echo "📝 Next Steps:"
echo "   1. Run Elixir setup:    mix setup"
echo "   2. Run migrations:      mix ecto.migrate"
echo "   3. Start Phoenix:       mix phx.server"
echo ""
