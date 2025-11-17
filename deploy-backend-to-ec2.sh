#!/bin/bash
# Complete EC2 Backend Deployment Script
set -e

EC2_IP="13.203.24.72"
KEY_FILE="$HOME/.ssh/fluentfly-key.pem"

echo "🚀 Starting EC2 Backend Deployment..."
echo "=================================="

# Test SSH connection
echo "Testing SSH connection..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$EC2_IP "echo 'SSH connection successful!'"

echo ""
echo "📦 Installing dependencies on EC2..."
ssh -i "$KEY_FILE" ubuntu@$EC2_IP 'bash -s' << 'ENDSSH'
set -e

# Update system
echo "Updating system packages..."
sudo apt update -qq

# Install Node.js 20
if ! command -v node &> /dev/null; then
    echo "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Install PM2
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    sudo npm install -g pm2
fi

# Install Nginx
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt install -y nginx
fi

# Verify installations
echo ""
echo "✅ Installed versions:"
node --version
npm --version
pm2 --version
nginx -v

echo ""
echo "✅ EC2 setup complete!"
ENDSSH

echo ""
echo "=================================="
echo "✅ Deployment preparation complete!"
echo ""
echo "Next: Upload backend code"
