# AWS Deployment - Complete Beginner Guide
## Bilkul Basic Se Step-by-Step

---

## 🎯 STEP 1: AWS Console Mein Login Karo

1. Browser mein jao: **https://aws.amazon.com**
2. Top right corner mein **"Sign In to the Console"** button par click karo
3. Apna email aur password dalo
4. Login ho jao

**Tip:** Agar pehli baar hai to "Root user" select karo

---

## 🔐 STEP 2: Security Groups Banao (Sabse Pehle!)

### 2.1: EC2 Dashboard Mein Jao

1. AWS Console ke top mein **search bar** hai
2. Usme type karo: **"EC2"**
3. **EC2** service par click karo
4. Left sidebar mein scroll karo aur **"Security Groups"** dhundo
5. **"Security Groups"** par click karo

### 2.2: Backend Security Group Banao

1. Orange button **"Create security group"** par click karo

2. **Basic details** fill karo:
   ```
   Security group name: fluentfly-backend-sg
   Description: Backend server security
   VPC: Default VPC (already selected hoga)
   ```

3. **Inbound rules** section mein jao
4. **"Add rule"** button par 4 baar click karke ye 4 rules banao:

   **Rule 1:**
   ```
   Type: SSH (dropdown se select karo)
   Source: My IP (dropdown se select karo - automatically tumhara IP aa jayega)
   Description: SSH access
   ```

   **Rule 2:**
   ```
   Type: Custom TCP
   Port range: 3000
   Source: Anywhere-IPv4 (0.0.0.0/0)
   Description: Backend API
   ```

   **Rule 3:**
   ```
   Type: HTTP
   Source: Anywhere-IPv4 (0.0.0.0/0)
   Description: HTTP traffic
   ```

   **Rule 4:**
   ```
   Type: HTTPS
   Source: Anywhere-IPv4 (0.0.0.0/0)
   Description: HTTPS traffic
   ```

5. Neeche orange button **"Create security group"** par click karo

✅ **Backend Security Group ban gaya!**

### 2.3: Database Security Group Banao

1. Wapas **"Create security group"** par click karo

2. **Basic details**:
   ```
   Security group name: fluentfly-db-sg
   Description: Database security
   VPC: Default VPC
   ```

3. **Inbound rules** - Sirf 1 rule:
   ```
   Type: PostgreSQL (dropdown se select karo)
   Source: Custom (dropdown se select karo)
   ```
   
4. Source field mein **"fluentfly-backend-sg"** type karo aur select karo
   - Ye dropdown mein aa jayega
   - Description: Backend to database

5. **"Create security group"** click karo

✅ **Database Security Group ban gaya!**

### 2.4: Redis Security Group Banao

1. Phir se **"Create security group"** click karo

2. **Basic details**:
   ```
   Security group name: fluentfly-redis-sg
   Description: Redis cache security
   VPC: Default VPC
   ```

3. **Inbound rules** - 1 rule:
   ```
   Type: Custom TCP
   Port range: 6379
   Source: Custom → fluentfly-backend-sg (select karo)
   Description: Backend to Redis
   ```

4. **"Create security group"** click karo

✅ **Redis Security Group ban gaya!**

---

## 🗄️ STEP 3: Database (RDS) Banao

### 3.1: RDS Service Mein Jao

1. Top search bar mein **"RDS"** type karo
2. **RDS** service par click karo
3. Left sidebar mein **"Databases"** par click karo
4. Orange button **"Create database"** par click karo

### 3.2: Database Settings

**Choose a database creation method:**
- **Standard create** select karo (already selected hoga)

**Engine options:**
1. **PostgreSQL** icon par click karo
2. Version: Latest (15.x) - default rakhne do

**Templates:**
- **Free tier** select karo (agar available hai)
- Nahi to **Dev/Test** select karo

**Settings:**
```
DB instance identifier: fluentfly-db
Master username: fluentfly_admin
Master password: [Koi strong password banao - YAAD RAKHNA!]
Confirm password: [Same password phir se]
```

**💡 Password Example:** `FluentFly@2024#Secure`
**⚠️ IMPORTANT:** Ye password kahin note kar lo!

**Instance configuration:**
```
DB instance class: Burstable classes → db.t3.micro
```

**Storage:**
```
Storage type: General Purpose SSD (gp3)
Allocated storage: 20 GB
✅ Enable storage autoscaling (checkbox check karo)
Maximum storage threshold: 100 GB
```

**Connectivity:**
```
VPC: Default VPC
Public access: No (radio button select karo)
VPC security group: Choose existing
Existing VPC security groups: 
  - fluentfly-db-sg (select karo)
  - default (remove kar do - X par click karke)
```

**Database authentication:**
- **Password authentication** (already selected hoga)

**Additional configuration** (expand karo):
```
Initial database name: fluentfly
Backup retention period: 7 days
✅ Enable encryption (checkbox)
❌ Enable Enhanced monitoring (uncheck - cost bachane ke liye)
```

### 3.3: Database Create Karo

1. Neeche scroll karo
2. **Estimated monthly costs** dekho (around $15-20)
3. Orange button **"Create database"** par click karo
4. **⏰ Wait karo 5-10 minutes** - Database create ho raha hai

### 3.4: Database Endpoint Copy Karo

1. Database list mein **"fluentfly-db"** par click karo
2. **Status** "Available" hone ka wait karo
3. **Connectivity & security** tab mein jao
4. **Endpoint** copy karo (looks like: `fluentfly-db.xxxxx.us-east-1.rds.amazonaws.com`)
5. Ye endpoint **kahin save kar lo** - baad mein chahiye hoga!

✅ **Database ready hai!**

---

## 💾 STEP 4: Redis Cache (ElastiCache) Banao

### 4.1: ElastiCache Service Mein Jao

1. Top search bar mein **"ElastiCache"** type karo
2. **ElastiCache** service par click karo
3. Left sidebar mein **"Redis clusters"** par click karo
4. Orange button **"Create Redis cluster"** par click karo

### 4.2: Cluster Settings

**Cluster mode:**
- **Disabled** select karo (simple setup)

**Cluster info:**
```
Name: fluentfly-redis
Description: Redis cache for FluentFly
```

**Location:**
- **AWS Cloud** (already selected)

**Cluster settings:**
```
Engine version: 7.x (latest)
Port: 6379 (default)
Parameter group: default.redis7
Node type: cache.t3.micro
Number of replicas: 0
```

**Subnet group settings:**
```
Create new subnet group:
Name: fluentfly-redis-subnet
VPC: Default VPC
Subnets: Select at least 2 subnets (checkboxes check karo)
```

**Security:**
```
Security groups: fluentfly-redis-sg (select karo)
Encryption at rest: Yes
Encryption in-transit: No
```

**Backup:**
```
Enable automatic backups: Yes
Backup retention period: 1 day
```

### 4.3: Create Karo

1. Neeche scroll karo
2. **Total cost** dekho (around $12/month)
3. **"Create"** button par click karo
4. **⏰ Wait karo 5-10 minutes**

### 4.4: Redis Endpoint Copy Karo

1. Cluster list mein **"fluentfly-redis"** par click karo
2. **Status** "Available" hone ka wait karo
3. **Primary endpoint** copy karo
4. Format: `fluentfly-redis.xxxxx.cache.amazonaws.com:6379`
5. Ye bhi **save kar lo!**

✅ **Redis ready hai!**

---

## 🖥️ STEP 5: EC2 Server Banao

### 5.1: EC2 Dashboard Mein Jao

1. Top search bar mein **"EC2"** type karo
2. **EC2** service par click karo
3. Left sidebar mein **"Instances"** par click karo
4. Orange button **"Launch instances"** par click karo

### 5.2: Instance Configuration

**Name and tags:**
```
Name: fluentfly-backend
```

**Application and OS Images (AMI):**
```
Quick Start: Ubuntu (already selected)
Ubuntu Server 22.04 LTS (Free tier eligible)
Architecture: 64-bit (x86)
```

**Instance type:**
```
Instance type: t2.small (testing ke liye)
Ya t2.medium (production ke liye - recommended)
```

**Key pair (login):**
1. **"Create new key pair"** par click karo
2. Settings:
   ```
   Key pair name: fluentfly-key
   Key pair type: RSA
   Private key file format: .pem
   ```
3. **"Create key pair"** click karo
4. **File download hogi** - isko safe jagah save karo!
5. **⚠️ IMPORTANT:** Ye file harne par wapas nahi milegi!

**Network settings:**
```
VPC: Default
Auto-assign public IP: Enable
Firewall (security groups): Select existing security group
Common security groups: fluentfly-backend-sg (select karo)
```

**Configure storage:**
```
Size (GiB): 30
Volume type: gp3
```

### 5.3: Launch Instance

1. Right side mein **Summary** dekho
2. **Estimated cost** check karo
3. Orange button **"Launch instance"** par click karo
4. **"View all instances"** par click karo
5. **⏰ Wait karo 2-3 minutes** - Instance start ho raha hai

### 5.4: Instance Details Note Karo

1. Instance list mein **"fluentfly-backend"** par click karo
2. **Instance state** "Running" hone ka wait karo
3. **Public IPv4 address** copy karo (example: `54.123.45.67`)
4. Ye IP address **save kar lo!**

✅ **Server ready hai!**

---

## 🔌 STEP 6: Server Mein Connect Karo (SSH)

### 6.1: Terminal Open Karo

**Mac/Linux:**
- **Terminal** app open karo

**Windows:**
- **PowerShell** ya **Git Bash** open karo

### 6.2: Key File Ko Secure Karo

```bash
# Downloads folder mein jao
cd ~/Downloads

# Key file ko secure karo (Mac/Linux)
chmod 400 fluentfly-key.pem
```

**Windows PowerShell:**
```powershell
# Right click on file → Properties → Security → Advanced
# Remove all users except yourself
```

### 6.3: SSH Connect Karo

```bash
ssh -i fluentfly-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

**Replace `YOUR_EC2_PUBLIC_IP`** with actual IP (jo tumne copy kiya tha)

**Example:**
```bash
ssh -i fluentfly-key.pem ubuntu@54.123.45.67
```

**First time connect karne par:**
- "Are you sure you want to continue connecting?" - Type **yes** aur Enter

✅ **Server mein login ho gaye!**

---

## 🛠️ STEP 7: Server Setup Karo

Ab tum server ke andar ho. Ye commands ek-ek karke run karo:

### 7.1: System Update Karo

```bash
sudo apt-get update
sudo apt-get upgrade -y
```
**⏰ Wait:** 2-3 minutes

### 7.2: Node.js Install Karo

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Check karo:**
```bash
node --version
npm --version
```

### 7.3: PM2 Install Karo (Process Manager)

```bash
sudo npm install -g pm2
```

### 7.4: Git Install Karo

```bash
sudo apt-get install -y git
```

### 7.5: Nginx Install Karo (Web Server)

```bash
sudo apt-get install -y nginx
```

✅ **Server setup complete!**

---

## 📦 STEP 8: Backend Code Deploy Karo

### 8.1: Code Download Karo

**Option A: GitHub se (Recommended)**

Pehle apna code GitHub par push karo, phir:

```bash
cd /home/ubuntu
git clone https://github.com/YOUR_USERNAME/fluentfly.git
cd fluentfly/backend
```

**Option B: Local se Upload (SCP)**

Apne computer ke terminal mein (new tab):

```bash
cd /path/to/your/fluentfly/project
scp -i ~/Downloads/fluentfly-key.pem -r backend ubuntu@YOUR_EC2_IP:/home/ubuntu/fluentfly/
```

### 8.2: Environment Variables Setup

```bash
cd /home/ubuntu/fluentfly/backend
nano .env
```

**Nano editor open hoga.** Ye paste karo:

```env
NODE_ENV=production
PORT=3000

# Database (RDS endpoint jo tumne save kiya tha)
DB_HOST=fluentfly-db.xxxxx.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_USERNAME=fluentfly_admin
DB_PASSWORD=FluentFly@2024#Secure
DB_NAME=fluentfly

# Redis (ElastiCache endpoint)
REDIS_HOST=fluentfly-redis.xxxxx.cache.amazonaws.com
REDIS_PORT=6379

# JWT
JWT_SECRET=your-super-secret-key-change-this-123456
JWT_EXPIRES_IN=7d

# Firebase (apne existing values)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-email
FIREBASE_PRIVATE_KEY=your-key

# OpenAI
OPENAI_API_KEY=your-key

# ElevenLabs
ELEVENLABS_API_KEY=your-key

# LiveKit
LIVEKIT_API_KEY=your-key
LIVEKIT_API_SECRET=your-secret
LIVEKIT_WS_URL=wss://your-url

# Gemini
GEMINI_API_KEY=your-key
```

**⚠️ IMPORTANT:** 
- `DB_HOST` - Apna RDS endpoint dalo
- `REDIS_HOST` - Apna Redis endpoint dalo
- `DB_PASSWORD` - Apna database password dalo
- Baaki API keys apne existing values se copy karo

**Save karo:**
1. Press `Ctrl + X`
2. Press `Y`
3. Press `Enter`

### 8.3: Dependencies Install Karo

```bash
npm install
```
**⏰ Wait:** 3-5 minutes

### 8.4: Build Karo

```bash
npm run build
```
**⏰ Wait:** 1-2 minutes

### 8.5: Database Setup Karo

```bash
# Migrations run karo
npm run migration:run

# Sample data dalo
npm run seed
```

### 8.6: Backend Start Karo

```bash
# PM2 se start karo
pm2 start dist/main.js --name fluentfly-backend

# Auto-restart setup karo
pm2 startup
# Jo command output mein aaye, wo run karo (copy-paste)

pm2 save
```

### 8.7: Test Karo

```bash
# Local test
curl http://localhost:3000/health

# Public test (apne browser mein)
http://YOUR_EC2_PUBLIC_IP:3000/health
```

**✅ Success response:**
```json
{
  "status": "ok",
  "timestamp": "2024-11-17T..."
}
```

✅ **Backend live hai!**

---

## 📱 STEP 9: Mobile App Configure Karo

### 9.1: API URL Update Karo

Apne computer par:

```bash
cd /path/to/fluentfly/mobile
```

File open karo: `lib/config/constants.dart`

```dart
class Constants {
  // Old
  // static const String apiBaseUrl = 'http://localhost:3000';
  
  // New - Replace with your EC2 IP
  static const String apiBaseUrl = 'http://54.123.45.67:3000';
}
```

### 9.2: App Rebuild Karo

```bash
flutter clean
flutter pub get
flutter build apk
```

### 9.3: Test Karo

App install karke test karo - ab backend AWS se connect hoga!

---

## ✅ FINAL CHECKLIST

Ye sab check karo:

- [ ] Security Groups bane (3 groups)
- [ ] RDS Database running
- [ ] ElastiCache Redis running
- [ ] EC2 Instance running
- [ ] SSH connection working
- [ ] Node.js installed
- [ ] Backend code deployed
- [ ] .env file configured
- [ ] Dependencies installed
- [ ] Build successful
- [ ] Migrations run
- [ ] PM2 process running
- [ ] Health endpoint responding
- [ ] Mobile app connected

---

## 🆘 COMMON PROBLEMS & SOLUTIONS

### Problem 1: SSH connection refused
```bash
# Check security group mein SSH rule hai ya nahi
# Check key file permissions: chmod 400 fluentfly-key.pem
```

### Problem 2: Backend not starting
```bash
# Logs dekho
pm2 logs fluentfly-backend

# Restart karo
pm2 restart fluentfly-backend
```

### Problem 3: Database connection failed
```bash
# .env file check karo
cat .env | grep DB_

# Security group check karo - backend SG database SG ko access kar sakta hai?
```

### Problem 4: Health endpoint not responding
```bash
# Check if process running
pm2 status

# Check logs
pm2 logs fluentfly-backend --lines 50

# Check port
sudo netstat -tulpn | grep 3000
```

---

## 💰 COST TRACKING

### Monthly Costs:
```
EC2 t2.small:         ~$17/month
EC2 t2.medium:        ~$35/month
RDS db.t3.micro:      ~$15/month
ElastiCache:          ~$12/month
Data Transfer:        ~$5/month
-----------------------------------
Total (t2.small):     ~$49/month
Total (t2.medium):    ~$67/month

With $200 credits:    3-4 months FREE!
```

### Cost Check Karo:
1. AWS Console → **Billing Dashboard**
2. **Bills** section mein current month ka bill dekho
3. **Budgets** mein alert setup karo

---

## 🎉 CONGRATULATIONS!

Tumhara FluentFly app ab AWS par live hai!

**Next Steps:**
1. Domain buy karo (optional)
2. SSL certificate setup karo (HTTPS)
3. Monitoring setup karo
4. Backup strategy implement karo

**Koi problem ho to:**
- PM2 logs dekho: `pm2 logs`
- System logs dekho: `sudo journalctl -xe`
- Mujhe batao!

---

## 📞 QUICK COMMANDS REFERENCE

```bash
# SSH connect
ssh -i fluentfly-key.pem ubuntu@YOUR_IP

# Backend restart
pm2 restart fluentfly-backend

# Logs dekho
pm2 logs fluentfly-backend

# System status
pm2 status
htop

# Database connect
psql -h YOUR_RDS_ENDPOINT -U fluentfly_admin -d fluentfly

# Nginx restart
sudo systemctl restart nginx

# Check disk space
df -h

# Check memory
free -h
```

---

Koi step mein problem aa rahi hai? Batao, main help karunga! 🚀
