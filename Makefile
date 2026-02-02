# ===========================================
# Qusto Development Makefile
# Shortcuts for common development tasks
# ===========================================

.PHONY: help setup start stop reset status logs migrate seed test

# Default target
help:
	@echo "Qusto Development Commands"
	@echo "=========================="
	@echo ""
	@echo "  make setup     - Initial setup (first time only)"
	@echo "  make start     - Start all services"
	@echo "  make stop      - Stop all services"
	@echo "  make reset     - Reset all data (DESTRUCTIVE)"
	@echo "  make status    - Check service status"
	@echo "  make logs      - View service logs"
	@echo "  make migrate   - Run database migrations"
	@echo "  make seed      - Seed database with test data"
	@echo "  make test      - Run test suite"
	@echo "  make server    - Start Phoenix server"
	@echo "  make console   - Open IEx console"
	@echo ""

# Initial setup
setup:
	@chmod +x scripts/*.sh
	@./scripts/dev-setup.sh

# Start services
start:
	@./scripts/dev-start.sh

# Stop services
stop:
	@./scripts/dev-stop.sh

# Reset environment
reset:
	@./scripts/dev-reset.sh

# Check status
status:
	@./scripts/health-check.sh

# View logs
logs:
	@docker compose logs -f

# Run migrations
migrate:
	@mix ecto.migrate
	@echo "✅ Migrations complete"

# Seed database
seed:
	@mix run priv/repo/seeds.exs
	@echo "✅ Database seeded"

# Run tests
test:
	@mix test

# Start Phoenix server
server:
	@mix phx.server

# Open console
console:
	@iex -S mix

# Full setup + migrate + seed
bootstrap: setup
	@sleep 5
	@mix deps.get
	@mix ecto.setup
	@echo "✅ Bootstrap complete! Run: make server"
