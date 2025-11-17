#!/bin/bash

# FluentFly - Deploy Backend to EC2
# Run this script from your LOCAL machine

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }
print_step() { echo -e "${BLUE}▶ $1${NC}"; }

echo "🚀 FluentFly Backend Deployment to EC2"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -d "backend" ]; then
    print_error "Error: backend directory not found!"
    echo "Please run this script from your project root directory"
    exit 1
fi

# Get deployment details
echo "Please provide deployment details:"
echo ""

read -p "EC2 Public IP: " EC2_IP
if [ -z "$EC2_IP" ]; then
    print_error "EC2 IP is required!"
    exit 1
fi

read -p "SSH Key Path [~/.ssh/fluentfly-backend-key.pem]: " SSH_KEY
SSH_KEY=${SSH_KEY:-~/.ssh/fluentfly-backend-key.pem}

# Expand tilde
SSH_KEY="${SSH_KEY/#\~/$HOME}"

if [ ! -f "$SSH_KEY" ]; then
    print_error "SSH key not found at: $SSH_KEY"
    exit 1
fi

read -p "EC2 User [ubuntu]: " EC2_USER
EC2_USER=${EC2_USER:-ubuntu}

echo ""
print_info "Deployment Configuration:"
echo "  • EC2 IP: $EC2_IP"
echo "  • SSH Key: $SSH_KEY"
echo "  • User: $EC2_USER"
echo ""

read -p "Continue with deployment? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    print_info "Deployment cancelled"
    exit 0
fi

# Step 1: Build backend locally
echo ""
print_step "Step 1: Building backend locally..."
cd backend
npm install
npm run build
print_success "Backend built successfully"
cd ..

# Step 2: Create deployment package
echo ""
print_step "Step 2: Creating deployment package..."
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/backend"

# Copy necessary files
cp -r backend/dist "$TEMP_DIR/backend/"
cp -r backend/node_modules "$TEMP_DIR/backend/" 2>/dev/null || print_info "Skipping node_modules (will install on server)"
cp backend/package*.json "$TEMP_DIR/backend/"
cp -r backend/database "$TEMP_DIR/backend/" 2>/dev/null || print_info "No database folder found"

# Copy .env if exists (with warning)
if [ -f "backend/.env" ]; then
    print_info "Found .env file - copying to deployment package"
    cp backend/.env "$TEMP_DIR/backend/"
fi

print_success "Deployment package created"

# Step 3: Upload to EC2
echo ""
print_step "Step 3: Uploading to EC2..."

# Create backup of existing deployment
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" "
    if [ -d ~/apps/backend ]; then
        echo 'Creating backup of existing deployment...'
        mv ~/apps/backend ~/apps/backend.backup.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    fi
    mkdir -p ~/apps
"

# Upload files
scp -i "$SSH_KEY" -r "$TEMP_DIR/backend" "$EC2_USER@$EC2_IP:~/apps/"
print_success "Files uploaded to EC2"

# Cleanup temp directory
rm -rf "$TEMP_DIR"

# Step 4: Install dependencies on server
echo ""
print_step "Step 4: Installing dependencies on EC2..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" "
    cd ~/apps/backend
    npm install --production
"
print_success "Dependencies installed"

# Step 5: Run migrations
echo ""
print_step "Step 5: Running database migrations..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" "
    cd ~/apps/backend
    npm run migration:run 2>/dev/null || echo 'Migration command not found or failed'
"
print_success "Migrations completed"

# Step 6: Restart application with PM2
echo ""
print_step "Step 6: Restarting application..."
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" "
    cd ~/apps/backend
    
    # Check if app is already running
    if pm2 list | grep -q 'fluentfly-backend'; then
        echo 'Restarting existing application...'
        pm2 restart fluentfly-backend
    else
        echo 'Starting new application...'
        pm2 start dist/main.js --name fluentfly-backend
        pm2 save
    fi
    
    # Show status
    pm2 status
"
print_success "Application restarted"

# Step 7: Health check
echo ""
print_step "Step 7: Running health check..."
sleep 3  # Wait for app to start

HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP:3000/api/v1/health" || echo "000")

if [ "$HEALTH_CHECK" = "200" ]; then
    print_success "Health check passed!"
else
    print_error "Health check failed (HTTP $HEALTH_CHECK)"
    echo ""
    print_info "Checking application logs..."
    ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" "pm2 logs fluentfly-backend --lines 20 --nostream"
fi

# Final summary
echo ""
echo "========================================"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo "========================================"
echo ""
echo "🔗 Your API is available at:"
echo "  • Health: http://$EC2_IP:3000/api/v1/health"
echo "  • Docs: http://$EC2_IP:3000/api/docs"
echo "  • Base URL: http://$EC2_IP:3000/api/v1"
echo ""
echo "📝 Useful Commands:"
echo "  • SSH: ssh -i $SSH_KEY $EC2_USER@$EC2_IP"
echo "  • Logs: ssh -i $SSH_KEY $EC2_USER@$EC2_IP 'pm2 logs fluentfly-backend'"
echo "  • Status: ssh -i $SSH_KEY $EC2_USER@$EC2_IP 'pm2 status'"
echo ""
echo "🎉 Happy coding!"
