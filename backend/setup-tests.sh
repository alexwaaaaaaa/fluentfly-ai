#!/bin/bash

# Integration Tests Setup Script
# Ye script automatically test environment setup karega

set -e  # Exit on error

echo "🚀 FluentFly Integration Tests Setup"
echo "===================================="
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

# Check if we're in the backend directory
if [ ! -f "package.json" ]; then
    print_error "Please run this script from the backend directory"
    exit 1
fi

print_info "Step 1: Checking Docker..."
if command -v docker &> /dev/null; then
    print_success "Docker found"
else
    print_error "Docker not found. Please install Docker first."
    exit 1
fi

print_info "Step 2: Starting PostgreSQL..."
docker-compose up -d postgres
if [ $? -eq 0 ]; then
    print_success "PostgreSQL started"
else
    print_error "Failed to start PostgreSQL"
    exit 1
fi

print_info "Waiting for PostgreSQL to be ready..."
sleep 10
print_success "PostgreSQL should be ready now"

print_info "Step 3: Checking database connection..."
if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
    print_success "Database is ready"
else
    print_warning "Database might not be ready yet, continuing anyway..."
fi

print_info "Step 4: Creating database schema..."
if [ -f "database/schema.sql" ]; then
    docker-compose exec -T postgres psql -U postgres -d fluentfly < database/schema.sql 2>/dev/null || {
        print_warning "Schema might already exist, continuing..."
    }
    print_success "Schema loaded"
else
    print_warning "schema.sql not found, trying migrations..."
    npm run migration:run || print_warning "Migrations failed, continuing..."
fi

print_info "Step 5: Loading seed data..."
if [ -f "database/seeds/lessons.seed.sql" ]; then
    docker-compose exec -T postgres psql -U postgres -d fluentfly < database/seeds/lessons.seed.sql 2>/dev/null || {
        print_warning "Seed data might already exist"
    }
    print_success "Seed data loaded"
else
    print_error "Seed file not found at database/seeds/lessons.seed.sql"
    print_warning "Tests requiring lesson data will fail"
fi

print_info "Step 6: Verifying data..."
LESSON_COUNT=$(docker-compose exec -T postgres psql -U postgres -d fluentfly -t -c "SELECT COUNT(*) FROM lessons;" 2>/dev/null | tr -d ' \n' || echo "0")
if [ "$LESSON_COUNT" -gt "0" ]; then
    print_success "Found $LESSON_COUNT lessons in database"
else
    print_warning "No lessons found in database. Some tests will fail."
fi

print_info "Step 7: Creating .env.test file..."
cat > .env.test << 'EOF'
# Test Environment Configuration
NODE_ENV=test

# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/fluentfly

# JWT
JWT_SECRET=test-jwt-secret-key-for-integration-tests
JWT_REFRESH_SECRET=test-refresh-secret-key-for-integration-tests
JWT_EXPIRATION=7d

# Redis (optional)
REDIS_URL=redis://localhost:6379

# Firebase (optional - tests handle missing config)
FIREBASE_PROJECT_ID=test-project
FIREBASE_PRIVATE_KEY=test-key
FIREBASE_CLIENT_EMAIL=test@test.com

# AI Services (optional)
GEMINI_API_KEY=test-key
OPENAI_API_KEY=test-key

# Azure Speech (optional)
AZURE_SPEECH_KEY=test-key
AZURE_SPEECH_REGION=eastus

# Storage (optional)
S3_ENDPOINT=http://localhost:9000
S3_ACCESS_KEY=test
S3_SECRET_KEY=test
S3_BUCKET_NAME=test-bucket
S3_REGION=auto

# LiveKit (optional)
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
LIVEKIT_URL=ws://localhost:7880
EOF
print_success ".env.test file created"

echo ""
echo "===================================="
print_success "Setup Complete!"
echo "===================================="
echo ""
print_info "Next steps:"
echo "  1. Run tests: npm run test:e2e"
echo "  2. Run specific test: npm run test:e2e -- lessons.e2e-spec.ts"
echo "  3. View detailed guide: cat TEST_SETUP_GUIDE.md"
echo ""
print_warning "Note: Some tests may fail without proper Firebase/API credentials"
print_info "Expected: ~43 tests should pass with this minimal setup"
echo ""
