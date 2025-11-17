#!/bin/bash

echo "🚀 FluentFly AI - AWS Deployment Script"
echo "========================================"
echo ""

# Configuration
REPO_URL="https://github.com/alexwaaaaaaa/fluentfly-ai.git"
APP_DIR="/home/ubuntu/fluentfly-ai"
BRANCH="main"

echo "📦 Step 1: Clone/Update Repository"
if [ -d "$APP_DIR" ]; then
    echo "Repository exists, pulling latest changes..."
    cd $APP_DIR
    git pull origin $BRANCH
else
    echo "Cloning repository..."
    git clone $REPO_URL $APP_DIR
    cd $APP_DIR
    git checkout $BRANCH
fi

echo ""
echo "📝 Step 2: Setup Environment Variables"
if [ ! -f backend/.env ]; then
    echo "Creating backend/.env from example..."
    cp backend/.env.example backend/.env
    echo ""
    echo "⚠️  IMPORTANT: Edit backend/.env with your credentials:"
    echo "   nano backend/.env"
    echo ""
    read -p "Press Enter after editing .env file..."
fi

echo ""
echo "🐳 Step 3: Install Docker & Docker Compose"
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
else
    echo "✅ Docker already installed"
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "✅ Docker Compose already installed"
fi

echo ""
echo "🔧 Step 4: Build and Start Services"
cd $APP_DIR

# Stop existing containers
echo "Stopping existing containers..."
docker-compose down

# Build and start
echo "Building and starting services..."
docker-compose up -d --build

echo ""
echo "⏳ Step 5: Wait for services to be ready..."
sleep 10

echo ""
echo "🔍 Step 6: Check Service Status"
docker-compose ps

echo ""
echo "📊 Step 7: View Logs"
docker-compose logs --tail=50

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "🌐 Your API should be running at:"
echo "   http://$(curl -s ifconfig.me):3000"
echo ""
echo "📝 Useful Commands:"
echo "   View logs:        cd $APP_DIR && docker-compose logs -f"
echo "   Restart:          cd $APP_DIR && docker-compose restart"
echo "   Stop:             cd $APP_DIR && docker-compose down"
echo "   Update & Deploy:  cd $APP_DIR && git pull && docker-compose up -d --build"
echo ""
echo "🔐 Security Reminder:"
echo "   1. Configure AWS Security Group to allow port 3000"
echo "   2. Set up SSL/HTTPS for production"
echo "   3. Use environment variables for secrets"
echo ""
