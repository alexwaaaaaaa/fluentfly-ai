.PHONY: help setup start stop restart logs clean test build deploy

# Default target
help:
	@echo "FluentFly - Available Commands"
	@echo "==============================="
	@echo ""
	@echo "Setup & Start:"
	@echo "  make setup      - Initial setup (create .env, start services)"
	@echo "  make start      - Start all services"
	@echo "  make stop       - Stop all services"
	@echo "  make restart    - Restart all services"
	@echo ""
	@echo "Development:"
	@echo "  make logs       - View logs from all services"
	@echo "  make logs-api   - View API logs only"
	@echo "  make shell-api  - Open shell in API container"
	@echo "  make shell-db   - Open PostgreSQL shell"
	@echo ""
	@echo "Database:"
	@echo "  make db-backup  - Backup database to backup.sql"
	@echo "  make db-restore - Restore database from backup.sql"
	@echo "  make db-reset   - Reset database (WARNING: deletes all data)"
	@echo ""
	@echo "Testing:"
	@echo "  make test       - Run all tests"
	@echo "  make test-backend - Run backend tests"
	@echo "  make test-mobile  - Run mobile tests"
	@echo ""
	@echo "Build:"
	@echo "  make build      - Build all Docker images"
	@echo "  make build-api  - Build API Docker image"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean      - Remove containers and volumes"
	@echo "  make clean-all  - Remove everything including images"
	@echo ""

# Setup
setup:
	@echo "Setting up FluentFly..."
	@if [ ! -f backend/.env ]; then \
		cp backend/.env.example backend/.env; \
		echo "Created backend/.env - Please edit with your credentials"; \
	fi
	@chmod +x setup.sh backend/database/init.sh mobile/run_integration_tests.sh 2>/dev/null || true
	@docker-compose up -d
	@echo "Setup complete! Services are starting..."
	@echo "Run 'make logs' to view logs"

# Start services
start:
	@echo "Starting services..."
	@docker-compose up -d
	@echo "Services started!"

# Stop services
stop:
	@echo "Stopping services..."
	@docker-compose down
	@echo "Services stopped!"

# Restart services
restart:
	@echo "Restarting services..."
	@docker-compose restart
	@echo "Services restarted!"

# View logs
logs:
	@docker-compose logs -f

logs-api:
	@docker-compose logs -f api

# Shell access
shell-api:
	@docker-compose exec api sh

shell-db:
	@docker-compose exec postgres psql -U postgres -d fluentfly

# Database operations
db-backup:
	@echo "Backing up database..."
	@docker-compose exec -T postgres pg_dump -U postgres fluentfly > backup.sql
	@echo "Database backed up to backup.sql"

db-restore:
	@echo "Restoring database from backup.sql..."
	@docker-compose exec -T postgres psql -U postgres fluentfly < backup.sql
	@echo "Database restored!"

db-reset:
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		docker-compose up -d; \
		echo "Database reset complete!"; \
	fi

# Testing
test: test-backend test-mobile

test-backend:
	@echo "Running backend tests..."
	@cd backend && npm test && npm run test:e2e

test-mobile:
	@echo "Running mobile tests..."
	@cd mobile && flutter test

# Build
build:
	@echo "Building all Docker images..."
	@docker-compose build

build-api:
	@echo "Building API Docker image..."
	@docker-compose build api

# Cleanup
clean:
	@echo "Cleaning up containers and volumes..."
	@docker-compose down -v
	@echo "Cleanup complete!"

clean-all:
	@echo "Removing everything including images..."
	@docker-compose down -v --rmi all
	@echo "Complete cleanup done!"

# Health check
health:
	@echo "Checking service health..."
	@curl -f http://localhost:3000/health || echo "API not responding"
	@docker-compose exec -T postgres pg_isready -U postgres || echo "PostgreSQL not ready"
	@docker-compose exec -T redis redis-cli ping || echo "Redis not responding"

# Status
status:
	@docker-compose ps
