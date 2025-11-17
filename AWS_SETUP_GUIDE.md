# AWS Deployment Guide - FluentFly App
## $200 Credits ke saath Complete Setup

---

## 📋 Overview
Ye guide tumhe step-by-step batayega ki kaise:
- EC2 instance setup karein (Backend ke liye)
- RDS PostgreSQL database setup karein
- ElastiCache Redis setup karein
- Security groups configure karein
- Domain aur SSL setup karein

**Estimated Monthly Cost:** $50-70 (3 months tak free with credits)

---

## 🎯 Phase 1: VPC aur Security Groups Setup

### Step 1.1: VPC Create Karein (Optional - Default bhi use kar sakte ho)

1. AWS Console mein login karein
2. **Services** → **VPC** par jaayein
3. **Create VPC** click karein
4. Settings:
   ```
   Name: fluentfly-vpc
   IPv4 CIDR: 10.0.0.0/16
   Tenancy: Default
   ```
5. **Create VPC** click karein

### Step 1.2: Security Groups Banayein

#### A) Backend Security Group
1. **EC2 Dashboard** → **Security Groups** → **Create Security Group**
2. Settings:
   ```
   Name: fluentfly-backend-sg
   Description: Security group for FluentFly backend server
   VPC: Select your VPC (ya default)
   ```

3. **Inbound Rules** add karein:
   ```
   Type: SSH
   Port: 22
   Source: My IP (tumhara current IP)
   Description: SSH access
   
   Type: Custom TCP
   Port: 3000
   Source: 0.0.0.0/0
   Description: Backend API
   
   Type: HTTPS
   Port: 443
   Source: 0.0.0.0/0
   Description: HTTPS traffic
   
   Type: HTTP
   Port: 80
   Source: 0.0.0.0/0
   Description: HTTP traffic (redirect to HTTPS)
   ```

4. **Outbound Rules**: Default (All traffic) rakhein

#### B) Database Security Group
1. **Create Security Group** again
2. Settings:
   ```
   Name: fluentfly-db-sg
   Description: Security group for RDS PostgreSQL
   VPC: Same as backend
   ```

3. **Inbound Rules**:
   ```
   Type: PostgreSQL
   Port: 5432
   Source: fluentfly-backend-sg (select the backend security group)
   Description: Allow backend to access database
   ```

#### C) Redis Security Group
1. **Create Security Group** again
2. Settings:
   ```
   Name: fluentfly-redis-sg
   Description: Security group for ElastiCache Redis
   VPC: Same as backend
   ```

3. **Inbound Rules**:
   ```
   Type: Custom TCP
   Port: 6379
   Source: fluentfly-backend-sg
   Description: Allow backend to access Redis
   ```

---

## 🗄️ Phase 2: RDS PostgreSQL Database Setup

### Step 2.1: RDS Instance Create Karein

1. **Services** → **RDS** → **Create database**

2. **Engine Options**:
   ```
   Engine type: PostgreSQL
   Version: PostgreSQL 15.x (latest stable)
   Templates: Free tier (agar eligible ho) ya Dev/Test
   ```

3. **Settings**:
   ```
   DB instance identifier: fluentfly-db
   Master username: fluentfly_admin
   Master password: [Strong password - save this!]
   Confirm password: [Same password]
   ```

4. **Instance Configuration**:
   ```
   DB instance class: db.t3.micro (Free tier) ya db.t3.small
   Storage type: General Purpose SSD (gp3)
   Allocated storage: 20 GB
   Enable storage autoscaling: Yes
   Maximum storage threshold: 100 GB
   ```

5. **Connectivity**:
   ```
   VPC: Select your VPC
   Public access: No (security ke liye)
   VPC security group: Choose existing → fluentfly-db-sg
   Availability Zone: No preference
   ```

6. **Database Authentication**:
   ```
   Password authentication: Selected
   ```

7. **Additional Configuration**:
   ```
   Initial database name: fluentfly
   Backup retention: 7 days
   Enable encryption: Yes
   Enable Enhanced monitoring: No (cost bachane ke liye)
   Enable auto minor version upgrade: Yes
   ```

8. **Create database** click karein (5-10 minutes lagenge)

### Step 2.2: Database Endpoint Note Karein

1. Database create hone ke baad, **Connectivity & security** tab mein jaayein
2. **Endpoint** copy karein (example: `fluentfly-db.xxxxx.us-east-1.rds.amazonaws.com`)
3. Ye endpoint tumhe backend .env mein use karna hai

---

## 💾 Phase 3: ElastiCache Redis Setup

### Step 3.1: Redis Cluster Create Karein

1. **Services** → **ElastiCache** → **Redis clusters** → **Create**

2. **Cluster Settings**:
   ```
   Cluster mode: Disabled (simple setup)
   Name: fluentfly-redis
   Description: Redis cache for FluentFly
   Engine version: 7.x (latest)
   Port: 6379
   Parameter group: default.redis7
   Node type: cache.t3.micro (cheapest)
   Number of replicas: 0 (cost bachane ke liye)
   ```

3. **Subnet Group**:
   ```
   Create new subnet group
   Name: fluentfly-redis-subnet
   VPC: Select your VPC
   Subnets: Select at least 2 subnets
   ```

4. **Security**:
   ```
   Security groups: fluentfly-redis-sg
   Encryption at rest: Yes
   Encryption in transit: No (optional)
   ```

5. **Backup**:
   ```
   Enable automatic backups: Yes
   Backup retention: 1 day
   ```

6. **Create** click karein (5-10 minutes)

### Step 3.2: Redis Endpoint Note Karein

1. Cluster ready hone ke baad, **Primary endpoint** copy karein
2. Format: `fluentfly-redis.xxxxx.cache.amazonaws.com:6379`

---

## 🖥️ Phase 4: EC2 Instance Setup

### Step 4.1: EC2 Instance Launch Karein

1. **Services** → **EC2** → **Launch Instance**

2. **Name and Tags**:
   ```
   Name: fluentfly-backend
   ```

3. **Application and OS Images**:
   ```
   AMI: Ubuntu Server 22.04 LTS (Free tier eligible)
   Architecture: 64-bit (x86)
   ```

4. **Instance Type**:
   ```
   Instance type: t2.medium (recommended for production)
   Ya t2.small (testing ke liye)
   ```

5. **Key Pair**:
   ```
   Create new key pair:
   - Name: fluentfly-key
   - Type: RSA
   - Format: .pem (for Mac/Linux) ya .ppk (for Windows)
   - Download and save securely!
   ```

6. **Network Settings**:
   ```
   VPC: Select your VPC
   Subnet: No preference
   Auto-assign public IP: Enable
   Firewall (security groups): Select existing → fluentfly-backend-sg
   ```

7. **Configure Storage**:
   ```
   Size: 30 GB
   Volume type: gp3
   Delete on termination: Yes
   ```

8. **Launch instance** click karein

### Step 4.2: EC2 Instance mein SSH Karein

1. Terminal open karein
2. Key file ko secure karein:
   ```bash
   chmod 400 ~/Downloads/fluentfly-key.pem
   ```

3. SSH connect karein:
   ```bash
   ssh -i ~/Downloads/fluentfly-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
   ```

4. Replace `YOUR_EC2_PUBLIC_IP` with actual IP (EC2 dashboard mein milega)

### Step 4.3: Server Setup Script

EC2 instance mein ye commands run karein:

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2
sudo npm install -g pm2

# Install Nginx
sudo apt-get install -y nginx

# Install certbot for SSL
sudo apt-get install -y certbot python3-certbot-nginx

# Create app directory
mkdir -p /home/ubuntu/fluentfly
```

---

## 🚀 Phase 5: Backend Deployment

### Step 5.1: Code Upload Karein

**Option A: Git se (Recommended)**
```bash
# EC2 instance mein
cd /home/ubuntu
git clone https://github.com/YOUR_USERNAME/fluentfly.git
cd fluentfly/backend
```

**Option B: SCP se local machine se**
```bash
# Local machine se
cd /path/to/fluentfly
scp -i ~/Downloads/fluentfly-key.pem -r backend ubuntu@YOUR_EC2_IP:/home/ubuntu/fluentfly/
```

### Step 5.2: Environment Variables Setup

```bash
# EC2 instance mein
cd /home/ubuntu/fluentfly/backend
nano .env
```

Ye configuration paste karein:

```env
# Server
NODE_ENV=production
PORT=3000
API_URL=http://YOUR_EC2_PUBLIC_IP:3000

# Database (RDS endpoint use karein)
DB_HOST=fluentfly-db.xxxxx.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_USERNAME=fluentfly_admin
DB_PASSWORD=YOUR_DB_PASSWORD
DB_NAME=fluentfly

# Redis (ElastiCache endpoint use karein)
REDIS_HOST=fluentfly-redis.xxxxx.cache.amazonaws.com
REDIS_PORT=6379

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRES_IN=7d

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-client-email
FIREBASE_PRIVATE_KEY=your-private-key

# OpenAI
OPENAI_API_KEY=your-openai-key

# ElevenLabs
ELEVENLABS_API_KEY=your-elevenlabs-key

# LiveKit
LIVEKIT_API_KEY=your-livekit-key
LIVEKIT_API_SECRET=your-livekit-secret
LIVEKIT_WS_URL=wss://your-livekit-url

# Gemini AI
GEMINI_API_KEY=your-gemini-key
```

Save: `Ctrl+X`, `Y`, `Enter`

### Step 5.3: Install aur Start

```bash
# Install dependencies
npm install

# Build
npm run build

# Run migrations
npm run migration:run

# Seed database
npm run seed

# Start with PM2
pm2 start dist/main.js --name fluentfly-backend

# Auto-restart on reboot
pm2 startup
pm2 save

# Check logs
pm2 logs fluentfly-backend
```

### Step 5.4: Test Karein

```bash
curl http://localhost:3000/health
```

---

## 💰 Cost Breakdown (Monthly)

```
EC2 t2.medium:        ~$35/month
RDS db.t3.micro:      ~$15/month
ElastiCache t3.micro: ~$12/month
Data transfer:        ~$5/month
Total:                ~$67/month

With $200 credits: ~3 months free!
```

---

## ✅ Quick Checklist

- [ ] Security Groups configured
- [ ] RDS PostgreSQL running
- [ ] ElastiCache Redis running
- [ ] EC2 instance running
- [ ] Backend deployed
- [ ] Environment variables set
- [ ] Migrations run
- [ ] PM2 running
- [ ] Health check passing

---

## 🆘 Troubleshooting

### Backend not starting?
```bash
pm2 logs fluentfly-backend --lines 100
```

### Database connection failed?
```bash
# Check security group
# Verify RDS endpoint in .env
telnet YOUR_RDS_ENDPOINT 5432
```

### Redis connection failed?
```bash
# Check security group
# Verify Redis endpoint
```

---

Deployment complete! 🎉
