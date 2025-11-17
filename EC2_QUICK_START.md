# EC2 Deployment - Quick Start Guide

## 🚀 5-Minute Quick Deploy

### Option A: Automated Setup (Recommended)

**1. Launch EC2 Instance (AWS Console)**
```
- AMI: Ubuntu 22.04 LTS
- Type: t2.medium (or t2.small for testing)
- Key: Create & download fluentfly-backend-key.pem
- Security Group: Allow ports 22, 80, 443, 3000
- Storage: 20GB
```

**2. Connect to EC2**
```bash
chmod 400 ~/.ssh/fluentfly-backend-key.pem
ssh -i ~/.ssh/fluentfly-backend-key.pem ubuntu@YOUR_EC2_IP
```

**3. Run Setup Script**
```bash
# Download and run setup script
curl -o setup.sh https://raw.githubusercontent.com/YOUR_REPO/main/ec2-setup.sh
chmod +x setup.sh
./setup.sh
```

**4. Deploy Backend (From Your Local Machine)**
```bash
# Make deploy script executable
chmod +x deploy-to-ec2.sh

# Run deployment
./deploy-to-ec2.sh
```

**Done! 🎉**

---

### Option B: Manual Setup

**1. Connect to EC2**
```bash
ssh -i ~/.ssh/fluentfly-backend-key.pem ubuntu@YOUR_EC2_IP
```

**2. Install Dependencies**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install Redis
sudo apt install -y redis-server

# Install PM2
sudo npm install -g pm2

# Install Nginx
sudo apt install -y nginx
```

**3. Setup Database**
```bash
sudo -u postgres psql
```
```sql
CREATE DATABASE fluentfly_prod;
CREATE USER fluentfly_user WITH ENCRYPTED PASSWORD 'YourPassword123!';
GRANT ALL PRIVILEGES ON DATABASE fluentfly_prod TO fluentfly_user;
\q
```

**4. Upload Backend Code**
```bash
# From your local machine
scp -i ~/.ssh/fluentfly-backend-key.pem -r backend ubuntu@YOUR_EC2_IP:~/apps/
```

**5. Setup & Start Application**
```bash
# On EC2
cd ~/apps/backend
npm install --production
npm run build
npm run migration:run

# Start with PM2
pm2 start dist/main.js --name fluentfly-backend
pm2 startup
pm2 save
```

**6. Configure Nginx**
```bash
sudo nano /etc/nginx/sites-available/fluentfly
```
Paste configuration from EC2_DEPLOYMENT_GUIDE.md

```bash
sudo ln -s /etc/nginx/sites-available/fluentfly /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

---

## 📱 Update Mobile App

**Update API URL:**
```dart
// mobile/lib/config/constants.dart
static const String baseUrl = 'http://YOUR_EC2_IP/api/v1';
```

**Rebuild:**
```bash
cd mobile
flutter clean
flutter build apk --release
```

---

## 🔧 Common Commands

### SSH Connect
```bash
ssh -i ~/.ssh/fluentfly-backend-key.pem ubuntu@YOUR_EC2_IP
```

### Check Status
```bash
pm2 status
pm2 logs fluentfly-backend
```

### Restart App
```bash
pm2 restart fluentfly-backend
```

### Update Code
```bash
cd ~/apps/backend
git pull  # or upload new files
npm install
npm run build
pm2 restart fluentfly-backend
```

### View Logs
```bash
# Application logs
pm2 logs fluentfly-backend --lines 100

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

### Database Access
```bash
psql -U fluentfly_user -d fluentfly_prod -h localhost
```

---

## 🧪 Test Deployment

```bash
# Health check
curl http://YOUR_EC2_IP/api/v1/health

# API docs
open http://YOUR_EC2_IP/api/docs
```

---

## 🔥 Troubleshooting

### Can't Connect via SSH
```bash
# Check key permissions
chmod 400 ~/.ssh/fluentfly-backend-key.pem

# Check security group - Port 22 should be open
```

### App Not Starting
```bash
# Check logs
pm2 logs fluentfly-backend

# Check .env file
cat ~/apps/backend/.env

# Restart
pm2 restart fluentfly-backend
```

### Database Connection Error
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -U fluentfly_user -d fluentfly_prod -h localhost
```

### Port 3000 Not Accessible
```bash
# Check security group - Port 3000 should be open
# Check app is running
pm2 status

# Check Nginx
sudo systemctl status nginx
sudo nginx -t
```

---

## 💰 Cost Estimate

**t2.small (2GB RAM):** ~$17/month
**t2.medium (4GB RAM):** ~$35/month

**Free Tier (First 12 months):**
- 750 hours/month t2.micro FREE
- Perfect for testing!

---

## 📚 Full Documentation

For detailed step-by-step guide, see: **EC2_DEPLOYMENT_GUIDE.md**

---

## 🎯 Quick Links

- **Health Check:** http://YOUR_EC2_IP/api/v1/health
- **API Docs:** http://YOUR_EC2_IP/api/docs
- **AWS Console:** https://console.aws.amazon.com/ec2

---

**Need Help?** Check EC2_DEPLOYMENT_GUIDE.md for detailed instructions!
