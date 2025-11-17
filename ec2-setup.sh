#!/bin/bash

# FluentFly Backend - EC2 Automated Setup Script
# Run this script on your EC2 instance after SSH connection

set -e  # Exit on any error

echo "🚀 FluentFly Backend EC2 Setup Starting..."
echo "================================================"

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

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Step 1: System Update
echo ""
print_info "Step 1: Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_success "System updated"

# Step 2: Install Node.js
echo ""
print_info "Step 2: Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
NODE_VERSION=$(node --version)
print_success "Node.js installed: $NODE_VERSION"

# Step 3: Install PostgreSQL
echo ""
print_info "Step 3: Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
print_success "PostgreSQL installed and started"

# Step 4: Install Redis
echo ""
print_info "Step 4: Installing Redis..."
sudo apt install -y redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
print_success "Redis installed and started"

# Step 5: Install Git
echo ""
print_info "Step 5: Installing Git..."
sudo apt install -y git
GIT_VERSION=$(git --version)
print_success "Git installed: $GIT_VERSION"

# Step 6: Install PM2
echo ""
print_info "Step 6: Installing PM2..."
sudo npm install -g pm2
PM2_VERSION=$(pm2 --version)
print_success "PM2 installed: $PM2_VERSION"

# Step 7: Install Nginx
echo ""
print_info "Step 7: Installing Nginx..."
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
print_success "Nginx installed and started"

# Step 8: Install useful tools
echo ""
print_info "Step 8: Installing additional tools..."
sudo apt install -y htop curl wget unzip
print_success "Additional tools installed"

# Step 9: Setup PostgreSQL Database
echo ""
print_info "Step 9: Setting up PostgreSQL database..."
echo ""
echo "Please enter database details:"
read -p "Database name [fluentfly_prod]: " DB_NAME
DB_NAME=${DB_NAME:-fluentfly_prod}

read -p "Database user [fluentfly_user]: " DB_USER
DB_USER=${DB_USER:-fluentfly_user}

read -sp "Database password: " DB_PASSWORD
echo ""

# Create database and user
sudo -u postgres psql <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\q
EOF

print_success "Database created: $DB_NAME"
print_success "User created: $DB_USER"

# Step 10: Create application directory
echo ""
print_info "Step 10: Creating application directory..."
mkdir -p ~/apps
cd ~/apps
print_success "Application directory created: ~/apps"

# Step 11: Setup swap (for low memory instances)
echo ""
print_info "Step 11: Setting up swap memory..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    print_success "2GB swap memory created"
else
    print_info "Swap file already exists"
fi

# Step 12: Configure firewall
echo ""
print_info "Step 12: Configuring firewall..."
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3000/tcp  # Backend API
echo "y" | sudo ufw enable
print_success "Firewall configured"

# Step 13: Create .env template
echo ""
print_info "Step 13: Creating .env template..."
cat > ~/apps/.env.template <<'EOF'
# Server
NODE_ENV=production
PORT=3000
API_PREFIX=api/v1

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=your_db_user
DB_PASSWORD=your_db_password
DB_NAME=your_db_name

# JWT
JWT_SECRET=change-this-to-a-secure-random-string-min-32-characters
JWT_EXPIRES_IN=7d

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account-email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour-Key-Here\n-----END PRIVATE KEY-----\n"

# Google AI
GOOGLE_AI_API_KEY=your-gemini-api-key

# ElevenLabs (Optional)
ELEVENLABS_API_KEY=your-elevenlabs-key

# LiveKit (Optional)
LIVEKIT_API_KEY=your-livekit-key
LIVEKIT_API_SECRET=your-livekit-secret
LIVEKIT_WS_URL=wss://your-livekit-url

# CORS
CORS_ORIGIN=*
EOF
print_success ".env template created at ~/apps/.env.template"

# Step 14: Create Nginx configuration template
echo ""
print_info "Step 14: Creating Nginx configuration..."
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
sudo tee /etc/nginx/sites-available/fluentfly > /dev/null <<EOF
server {
    listen 80;
    server_name $PUBLIC_IP;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/fluentfly /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
print_success "Nginx configured for IP: $PUBLIC_IP"

# Step 15: Setup automatic security updates
echo ""
print_info "Step 15: Setting up automatic security updates..."
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
print_success "Automatic security updates enabled"

# Final Summary
echo ""
echo "================================================"
echo -e "${GREEN}✓ EC2 Setup Complete!${NC}"
echo "================================================"
echo ""
echo "📋 Summary:"
echo "  • Node.js: $NODE_VERSION"
echo "  • PM2: $PM2_VERSION"
echo "  • PostgreSQL: Running"
echo "  • Redis: Running"
echo "  • Nginx: Running"
echo "  • Database: $DB_NAME"
echo "  • Public IP: $PUBLIC_IP"
echo ""
echo "📝 Next Steps:"
echo "  1. Upload your backend code to ~/apps/backend"
echo "  2. Copy .env.template to backend/.env and update values"
echo "  3. Run: cd ~/apps/backend && npm install"
echo "  4. Run: npm run build"
echo "  5. Run: npm run migration:run"
echo "  6. Run: pm2 start dist/main.js --name fluentfly-backend"
echo "  7. Run: pm2 save && pm2 startup"
echo ""
echo "🔗 Access your API at:"
echo "  • http://$PUBLIC_IP/api/v1/health"
echo "  • http://$PUBLIC_IP/api/docs"
echo ""
echo "📚 Useful Commands:"
echo "  • pm2 status              - Check app status"
echo "  • pm2 logs fluentfly-backend - View logs"
echo "  • pm2 restart fluentfly-backend - Restart app"
echo "  • sudo systemctl status nginx - Check Nginx"
echo ""
print_success "Happy Deploying! 🚀"
