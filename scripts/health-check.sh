#!/bin/bash
# ===========================================
# Health Check Script for Claude Code Automation
# Returns JSON status for programmatic use
# ===========================================

# Check all services and output JSON
check_postgres() {
    if docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        echo "true"
    else
        echo "false"
    fi
}

check_clickhouse() {
    if curl -s http://localhost:8123/ping > /dev/null 2>&1; then
        echo "true"
    else
        echo "false"
    fi
}

check_redis() {
    if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        echo "true"
    else
        echo "false"
    fi
}

# Output JSON
cat << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "services": {
    "postgres": {
      "healthy": $(check_postgres),
      "port": 5432,
      "url": "postgres://postgres:postgres@localhost:5432/plausible_dev"
    },
    "clickhouse": {
      "healthy": $(check_clickhouse),
      "http_port": 8123,
      "native_port": 9000,
      "url": "http://localhost:8123"
    },
    "redis": {
      "healthy": $(check_redis),
      "port": 6379,
      "url": "redis://localhost:6379"
    }
  },
  "all_healthy": $([ "$(check_postgres)" == "true" ] && [ "$(check_clickhouse)" == "true" ] && [ "$(check_redis)" == "true" ] && echo "true" || echo "false")
}
EOF
