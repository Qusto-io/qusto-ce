#!/bin/bash
# ===========================================
# Stop Qusto Development Services
# Preserves data volumes
# ===========================================

echo "🛑 Stopping Qusto Development Services..."
docker compose down
echo "✅ Services stopped. Data volumes preserved."
