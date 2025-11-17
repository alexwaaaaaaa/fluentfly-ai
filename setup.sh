#!/bin/bash

# FluentFly Setup Script
# This script sets up the development environment for FluentFly

set -e

echo "🚀 FluentFly Setup Script"
echo "=========================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check Docker
if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
    print_success "Docker installed: $DOCKER_VERSION"
else
    print_error "Docker is not installed"
    print_info "Install Docker from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Docker Compose
if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
    print_success "Docker Compose installed"
else
    print_error "Docker Compose is not installed"
    exit 1
fi

# Check Node.js
if command_exists node; then
    NODE_VERSION=$(node --version)
    print_success "Node.js installed: $NODE_VERSION"
else
    print_warning "Node.js is not installed (optional for local development)"
    print_info "Install Node.js from: https://nodejs.org/"
fi

# Check Flutter
if command_exists flutter; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_success "Flutter installed: $FLUTTER_VERSION"
else
    print_warning "Flutter is not installed (required for mobile development)"
    print_info "Install Flutter from: https://docs.flutter.dev/get-started/install"
fi

echo ""
echo "Setting up environment..."
echo ""

# Create .env file if it doesn't exist
if [ ! -f backend/.env ]; then
    print_info "Creating backend/.env from .env.example..."
    cp backend/.env.example backend/.env
    print_success "Created backend/.env"
    print_warning "Please edit backend/.env with your actual credentials"
else
    print_info "backend/.env already exists"
fi

# Make scripts executable
chmod +x backend/database/init.sh 2>/dev/null || true
chmod +x mobile/run_integration_tests.sh 2>/dev/null || true

echo ""
echo "Starting services with Docker Compose..."
echo ""

# Start Docker services
docker-compose up -d

echo ""
print_info "Waiting for services to be ready..."
sleep 10

# Check service health
echo ""
echo "Checking service health..."
echo ""

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
    print_success "PostgreSQL is ready"
else
    print_error "PostgreSQL is not ready"
fi

# Check Redis
if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
    print_success "Redis is ready"
else
    print_error "Redis is not ready"
fi

# Check API
sleep 5
if curl -f http://localhost:3000/health >/dev/null 2>&1; then
    print_success "API is ready"
else
    print_warning "API is not ready yet (may need more time to start)"
fi

echo ""
echo "=========================="
echo "✅ Setup Complete!"
echo "=========================="
echo ""
echo "Services running:"
echo "  • API:        http://localhost:3000"
echo "  • API Docs:   http://localhost:3000/api/docs"
echo "  • PostgreSQL: localhost:5432"
echo "  • Redis:      localhost:6379"
echo "  • LiveKit:    localhost:7880"
echo ""
echo "Next steps:"
echo "  1. Edit backend/.env with your API keys"
echo "  2. Restart services: docker-compose restart api"
echo "  3. View logs: docker-compose logs -f"
echo "  4. Run mobile app: cd mobile && flutter run"
echo ""
echo "Useful commands:"
echo "  • Stop services:    docker-compose down"
echo "  • View logs:        docker-compose logs -f api"
echo "  • Restart API:      docker-compose restart api"
echo "  • Database backup:  docker-compose exec postgres pg_dump -U postgres fluentfly > backup.sql"
echo ""
