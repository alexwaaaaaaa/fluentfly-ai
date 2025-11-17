# EC2 Instance Setup & Backend Deployment Guide

## Step 1: EC2 Instance Launch Karo (10 mins)

### 1.1 EC2 Console Open Karo
```
AWS Console → Services → EC2 → Launch Instance
```

### 1.2 Instance Configuration
**Name:** `fluentfly-backend-prod`

**AMI Select Karo:**
- Ubuntu Server 22.04 LTS (Free tier eligible)
- 64-bit (x86)

**Instance Type:**
- t2.medium (4GB RAM, 2 vCPU) - Recommended for production
- Ya t2.small (2GB RAM) - Testing ke liye

**Key Pair:**
- "Create new key pair" click karo
- Name: `fluentfly-backend-key`
- Type: RSA
- Format: .pem (Mac/Linux) ya .ppk (Windows)
- Download karo aur safe jagah save karo

**Network Settings:**
- Create security group: YES
- Security group name: `fluentfly-backend-sg`
- Description: `FluentFly Backend Security Group`

**Inbound Rules Add Karo:**
1. SSH (Port 22) - Your IP
2. HTTP (Port 80) - Anywhere
3. HTTPS (Port 443) - Anywhere
4. Custom TCP (Port 3000) - Anywhere (Backend API)
5. Custom TCP (Port 5432) - Your IP only (PostgreSQL - temporary)

**Storage:**
- 20 GB gp3 (General Purpose SSD)

### 1.3 Launch Instance
- "Launch instance" button click karo
- 2-3 minutes wait karo

---

## Step 2: EC2 Instance Connect Karo (5 mins)

### 2.1 Key File Permissions Set Karo
```bash
# Downloaded key file ko secure karo
chmod 400 ~/Downloads/fluentfly-backend-key.pem

# Better location pe move karo
mkdir -p ~/.ssh
mv ~/Downloads/fluentfly-backend-key.pem ~/.ssh/
```

### 2.2 Public IP Copy Karo
```
EC2 Console → Instances → fluentfly-backend-prod → Public IPv4 address
Example: 54.123.45.67
```

### 2.3 SSH Connect Karo
```bash
ssh -i ~/.ssh/fluentfly-backend-key.pem ubuntu@YOUR_EC2_PUBLIC_IP

# Example:
# ssh -i ~/.ssh/fluentfly-backend-key.pem ubuntu@54.123.45.67
```

**First time warning aayega:**
```
Are you sure you want to continue connecting (yes/no)?
```
Type: `yes` aur Enter

---

## Step 3: Server Setup Karo (15 mins)

### 3.1 System Update Karo
```bash
sudo apt update && sudo apt upgrade -y
```

### 3.2 Node.js Install Karo
```bash
# Node.js 20.x install karo
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify karo
node --version  # Should show v20.x.x
npm --version   # Should show 10.x.x
```

### 3.3 PostgreSQL Install Karo
```bash
# PostgreSQL 15 install karo
sudo apt install -y postgresql postgresql-contrib

# Start karo
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify karo
sudo systemctl status postgresql
```

### 3.4 Redis Install Karo
```bash
sudo apt install -y redis-server

# Start karo
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verify karo
redis-cli ping  # Should return "PONG"
```

### 3.5 Git Install Karo
```bash
sudo apt install -y git
git --version
```

### 3.6 PM2 Install Karo (Process Manager)
```bash
sudo npm install -g pm2
pm2 --version
```

---

## Step 4: Database Setup Karo (10 mins)

### 4.1 PostgreSQL User Banao
```bash
# PostgreSQL user switch karo
sudo -u postgres psql

# Ab PostgreSQL console mein ho
```

### 4.2 Database aur User Create Karo
```sql
-- Database banao
CREATE DATABASE fluentfly_prod;

-- User banao with strong password
CREATE USER fluentfly_user WITH ENCRYPTED PASSWORD 'YourStrongPassword123!';

-- Permissions do
GRANT ALL PRIVILEGES ON DATABASE fluentfly_prod TO fluentfly_user;

-- Exit karo
\q
```

### 4.3 Test Connection
```bash
psql -U fluentfly_user -d fluentfly_prod -h localhost
# Password enter karo
# Successfully connect hona chahiye

# Exit karo
\q
```

---

## Step 5: Backend Code Deploy Karo (15 mins)

### 5.1 Application Directory Banao
```bash
cd ~
mkdir -p apps
cd apps
```

### 5.2 Code Clone Karo (Option A - Git)
```bash
# Agar GitHub pe code hai
git clone https://github.com/YOUR_USERNAME/fluentfly.git
cd fluentfly/backend
```

### 5.2 Alternative: Code Upload Karo (Option B - SCP)
```bash
# Apne local machine se (new terminal window mein)
cd /path/to/your/fluentfly/project

# Backend folder upload karo
scp -i ~/.ssh/fluentfly-backend-key.pem -r backend ubuntu@YOUR_EC2_IP:~/apps/

# Example:
# scp -i ~/.ssh/fluentfly-backend-key.pem -r backend ubuntu@54.123.45.67:~/apps/
```

### 5.3 Dependencies Install Karo
```bash
# EC2 terminal mein
cd ~/apps/backend
npm install --production
```

### 5.4 Environment Variables Setup Karo
```bash
# .env file banao
nano .env
```

**Paste karo (values update karo):**
```env
# Server
NODE_ENV=production
PORT=3000
API_PREFIX=api/v1

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=fluentfly_user
DB_PASSWORD=YourStrongPassword123!
DB_NAME=fluentfly_prod

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-min-32-chars
JWT_EXPIRES_IN=7d

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Firebase (from your existing setup)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account-email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour-Key-Here\n-----END PRIVATE KEY-----\n"

# Google AI
GOOGLE_AI_API_KEY=your-gemini-api-key

# ElevenLabs (Optional)
ELEVENLABS_API_KEY=your-elevenlabs-key

# LiveKit (Optional - for video calls)
LIVEKIT_API_KEY=your-livekit-key
LIVEKIT_API_SECRET=your-livekit-secret
LIVEKIT_WS_URL=wss://your-livekit-url

# CORS
CORS_ORIGIN=*
```

**Save karo:** `Ctrl + X`, then `Y`, then `Enter`

### 5.5 Build Application
```bash
npm run build
```

---

## Step 6: Database Migrations Run Karo (5 mins)

### 6.1 Run Migrations
```bash
npm run migration:run
```

### 6.2 Seed Data (Optional)
```bash
# Agar seed file hai
npm run seed
```

---

## Step 7: Application Start Karo with PM2 (5 mins)

### 7.1 PM2 se Start Karo
```bash
# Production mode mein start karo
pm2 start dist/main.js --name fluentfly-backend

# Auto-restart on server reboot
pm2 startup
# Jo command suggest kare, wo run karo

pm2 save
```

### 7.2 Check Status
```bash
pm2 status
pm2 logs fluentfly-backend
```

### 7.3 Useful PM2 Commands
```bash
pm2 restart fluentfly-backend  # Restart
pm2 stop fluentfly-backend     # Stop
pm2 delete fluentfly-backend   # Delete
pm2 logs fluentfly-backend     # View logs
pm2 monit                      # Monitor
```

---

## Step 8: Test Deployment (5 mins)

### 8.1 Health Check
```bash
# EC2 terminal se
curl http://localhost:3000/api/v1/health

# Should return: {"status":"ok"}
```

### 8.2 External Access Test
```bash
# Apne local machine se
curl http://YOUR_EC2_PUBLIC_IP:3000/api/v1/health

# Example:
# curl http://54.123.45.67:3000/api/v1/health
```

### 8.3 API Documentation Check
```
Browser mein open karo:
http://YOUR_EC2_PUBLIC_IP:3000/api/docs
```

---

## Step 9: Nginx Setup (Optional but Recommended) (10 mins)

### 9.1 Nginx Install Karo
```bash
sudo apt install -y nginx
```

### 9.2 Nginx Configuration
```bash
sudo nano /etc/nginx/sites-available/fluentfly
```

**Paste karo:**
```nginx
server {
    listen 80;
    server_name YOUR_EC2_PUBLIC_IP;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 9.3 Enable Configuration
```bash
# Symlink banao
sudo ln -s /etc/nginx/sites-available/fluentfly /etc/nginx/sites-enabled/

# Default config disable karo
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### 9.4 Test Nginx
```bash
# Ab port 80 pe access kar sakte ho
curl http://YOUR_EC2_PUBLIC_IP/api/v1/health
```

---

## Step 10: Mobile App Connect Karo (5 mins)

### 10.1 Update Mobile App Config
```dart
// mobile/lib/config/constants.dart

class ApiConstants {
  // Production URL
  static const String baseUrl = 'http://YOUR_EC2_PUBLIC_IP:3000/api/v1';
  
  // Ya agar Nginx setup kiya hai
  // static const String baseUrl = 'http://YOUR_EC2_PUBLIC_IP/api/v1';
}
```

### 10.2 Rebuild Mobile App
```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

### 10.3 Test Connection
- APK install karo phone pe
- Login try karo
- Check karo backend logs: `pm2 logs fluentfly-backend`

---

## Troubleshooting

### Issue 1: SSH Connection Failed
```bash
# Check security group
# Port 22 open hona chahiye for your IP

# Check key permissions
chmod 400 ~/.ssh/fluentfly-backend-key.pem
```

### Issue 2: Database Connection Error
```bash
# PostgreSQL running hai?
sudo systemctl status postgresql

# Password correct hai?
psql -U fluentfly_user -d fluentfly_prod -h localhost
```

### Issue 3: Port 3000 Not Accessible
```bash
# Security group check karo
# Port 3000 open hona chahiye

# Application running hai?
pm2 status
pm2 logs fluentfly-backend
```

### Issue 4: Out of Memory
```bash
# Swap memory add karo
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Permanent banao
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Issue 5: Build Failed
```bash
# Node version check karo
node --version  # Should be 20.x

# Dependencies reinstall karo
rm -rf node_modules package-lock.json
npm install
npm run build
```

---

## Monitoring Commands

```bash
# System resources
htop  # Install: sudo apt install htop

# Disk usage
df -h

# Memory usage
free -h

# Application logs
pm2 logs fluentfly-backend --lines 100

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

---

## Security Checklist

- [ ] SSH key secure hai (chmod 400)
- [ ] Strong database password use kiya
- [ ] JWT_SECRET change kiya production mein
- [ ] Security group properly configured
- [ ] PostgreSQL port (5432) sirf trusted IPs ke liye open
- [ ] Regular backups setup karo
- [ ] Firewall enable karo: `sudo ufw enable`
- [ ] Automatic security updates: `sudo apt install unattended-upgrades`

---

## Next Steps

1. **Domain Setup:** Route53 se domain connect karo
2. **SSL Certificate:** Let's Encrypt se free SSL setup karo
3. **Monitoring:** CloudWatch ya Datadog setup karo
4. **Backups:** Automated database backups setup karo
5. **CI/CD:** GitHub Actions se auto-deployment setup karo

---

## Cost Optimization

**Current Setup Monthly Cost (Approximate):**
- EC2 t2.medium: ~$35/month
- Data transfer: ~$5-10/month
- **Total: ~$40-45/month**

**Free Tier Benefits (First 12 months):**
- 750 hours/month EC2 t2.micro (free)
- 30 GB storage (free)
- Use t2.micro for testing to save costs!

---

## Quick Reference

**SSH Connect:**
```bash
ssh -i ~/.ssh/fluentfly-backend-key.pem ubuntu@YOUR_EC2_IP
```

**View Logs:**
```bash
pm2 logs fluentfly-backend
```

**Restart App:**
```bash
pm2 restart fluentfly-backend
```

**Update Code:**
```bash
cd ~/apps/backend
git pull
npm install
npm run build
pm2 restart fluentfly-backend
```

---

**Deployment Complete! 🚀**

Your backend is now live at: `http://YOUR_EC2_PUBLIC_IP:3000`
