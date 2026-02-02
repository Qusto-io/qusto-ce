#!/bin/bash
# ===========================================
# Reset Qusto Development Environment
# WARNING: Deletes all data!
# ===========================================

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}⚠️  WARNING: This will delete ALL development data!${NC}"
echo ""
read -p "Are you sure? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo "🛑 Stopping services..."
docker compose down --remove-orphans

echo "🗑️  Removing data volumes..."
docker volume rm qusto-postgres-data qusto-clickhouse-data qusto-redis-data 2>/dev/null || true

echo "🚀 Starting fresh environment..."
./scripts/dev-setup.sh

echo ""
echo -e "${YELLOW}✅ Development environment reset complete!${NC}"
echo "   Run: mix ecto.setup"
