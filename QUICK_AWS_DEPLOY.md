# Quick AWS Deployment from GitHub

## Prerequisites
- AWS Account with $200 credits
- EC2 instance running (Ubuntu 22.04 recommended)
- SSH access to EC2 instance

## Step 1: Launch EC2 Instance

1. Go to AWS Console → EC2
2. Click "Launch Instance"
3. Choose:
   - **Name**: fluentfly-backend
   - **AMI**: Ubuntu Server 22.04 LTS
   - **Instance Type**: t2.medium (2 vCPU, 4GB RAM)
   - **Key Pair**: Create new or use existing
   - **Storage**: 30 GB gp3

4. Configure Security Group:
   - SSH (22) - Your IP
   - HTTP (80) - Anywhere
   - HTTPS (443) - Anywhere
   - Custom TCP (3000) - Anywhere (API)
   - Custom TCP (5432) - Your IP (PostgreSQL)
   - Custom TCP (6379) - Your IP (Redis)

5. Launch Instance

## Step 2: Connect to EC2

```bash
# Download your key pair (e.g., fluentfly-key.pem)
chmod 400 fluentfly-key.pem

# Connect to EC2
ssh -i fluentfly-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

## Step 3: Deploy from GitHub

```bash
# Download deployment script
curl -o aws-deploy.sh https://raw.githubusercontent.com/alexwaaaaaaa/fluentfly-ai/main/aws-deploy.sh

# Make it executable
chmod +x aws-deploy.sh

# Run deployment
./aws-deploy.sh
```

The script will:
1. ✅ Clone your GitHub repository
2. ✅ Install Docker & Docker Compose
3. ✅ Setup environment variables
4. ✅ Build and start all services
5. ✅ Show service status

## Step 4: Configure Environment Variables

Edit the `.env` file with your credentials:

```bash
cd /home/ubuntu/fluentfly-ai
nano backend/.env
```

Update these values:
```env
# Database
DATABASE_URL=postgresql://postgres:your_password@postgres:5432/fluentfly

# JWT Secrets
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# AI APIs
GEMINI_API_KEY=your-gemini-api-key
OPENAI_API_KEY=your-openai-api-key

# Azure Speech
AZURE_SPEECH_KEY=your-azure-speech-key
AZURE_SPEECH_REGION=eastus

# LiveKit
LIVEKIT_API_KEY=your-livekit-key
LIVEKIT_API_SECRET=your-livekit-secret
LIVEKIT_URL=wss://your-livekit-url
```

Save and exit (Ctrl+X, Y, Enter)

## Step 5: Restart Services

```bash
cd /home/ubuntu/fluentfly-ai
docker-compose restart
```

## Step 6: Verify Deployment

```bash
# Check if services are running
docker-compose ps

# View logs
docker-compose logs -f api

# Test API
curl http://localhost:3000/health
```

## Step 7: Access Your API

Your API is now live at:
```
http://YOUR_EC2_PUBLIC_IP:3000
```

Test endpoints:
- Health: `http://YOUR_EC2_PUBLIC_IP:3000/health`
- API Docs: `http://YOUR_EC2_PUBLIC_IP:3000/api/docs`

## Update Deployment (Future)

When you push changes to GitHub:

```bash
# SSH to EC2
ssh -i fluentfly-key.pem ubuntu@YOUR_EC2_PUBLIC_IP

# Update and redeploy
cd /home/ubuntu/fluentfly-ai
git pull origin main
docker-compose up -d --build
```

## Useful Commands

```bash
# View all logs
docker-compose logs -f

# View API logs only
docker-compose logs -f api

# Restart all services
docker-compose restart

# Stop all services
docker-compose down

# Start services
docker-compose up -d

# Check service status
docker-compose ps

# Access database
docker-compose exec postgres psql -U postgres -d fluentfly
```

## Cost Optimization

With $200 AWS credits:
- **t2.medium**: ~$0.05/hour = ~$36/month
- **30GB Storage**: ~$3/month
- **Data Transfer**: ~$5-10/month
- **Total**: ~$45-50/month
- **Credits last**: ~4 months

## Troubleshooting

### Services not starting?
```bash
docker-compose logs
```

### Port 3000 not accessible?
Check AWS Security Group allows port 3000

### Database connection error?
```bash
docker-compose restart postgres
docker-compose logs postgres
```

### Out of memory?
Upgrade to t2.large (4GB → 8GB RAM)

## Next Steps

1. ✅ Setup SSL/HTTPS with Let's Encrypt
2. ✅ Configure domain name
3. ✅ Setup monitoring (CloudWatch)
4. ✅ Configure backups
5. ✅ Setup CI/CD for auto-deployment

## Support

Issues? Check:
- GitHub: https://github.com/alexwaaaaaaa/fluentfly-ai/issues
- Logs: `docker-compose logs -f`
- AWS Console: EC2 → Instances → Your Instance
