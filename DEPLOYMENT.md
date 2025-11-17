# FluentFly Deployment Guide

This guide covers deploying the FluentFly application using Docker, Docker Compose, and CI/CD pipelines.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start with Docker Compose](#quick-start-with-docker-compose)
- [Environment Configuration](#environment-configuration)
- [Production Deployment](#production-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring and Health Checks](#monitoring-and-health-checks)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Docker**: 24.0+ ([Install Docker](https://docs.docker.com/get-docker/))
- **Docker Compose**: 2.20+ (included with Docker Desktop)
- **Node.js**: 20+ (for local development)
- **Flutter**: 3.24+ (for mobile development)

### Required Services

- **Azure Speech Services**: For TTS/STT functionality
- **Google Gemini API**: Primary AI provider
- **OpenAI API**: Fallback AI provider
- **Firebase**: For authentication (Google OAuth and Phone OTP)
- **S3/Cloudflare R2**: For audio file storage

## Quick Start with Docker Compose

### 1. Clone the Repository

```bash
git clone <repository-url>
cd fluentfly
```

### 2. Configure Environment Variables

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env` with your actual credentials:

```env
# Critical variables that MUST be set
AZURE_SPEECH_KEY=your-azure-speech-key
AZURE_SPEECH_REGION=eastus
GEMINI_API_KEY=your-gemini-api-key
OPENAI_API_KEY=your-openai-api-key
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-in-production

# Firebase credentials
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# Storage configuration
S3_ENDPOINT=https://your-account.r2.cloudflarestorage.com
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key
S3_BUCKET_NAME=fluentfly-audio
```

### 3. Start All Services

```bash
docker-compose up -d
```

This will start:
- **API**: Backend server on port 3000
- **PostgreSQL**: Database on port 5432
- **Redis**: Cache on port 6379
- **LiveKit**: RTC server on ports 7880-7882

### 4. Verify Deployment

```bash
# Check service status
docker-compose ps

# Check API health
curl http://localhost:3000/health

# View logs
docker-compose logs -f api
```

### 5. Access the Application

- **API**: http://localhost:3000
- **API Documentation**: http://localhost:3000/api/docs
- **Health Check**: http://localhost:3000/health

## Environment Configuration

### Backend Environment Variables

#### Application Configuration

```env
NODE_ENV=production          # Environment: development, production
PORT=3000                    # API server port
API_URL=http://localhost:3000
```

#### Database Configuration

```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/fluentfly
```

#### Redis Configuration

```env
REDIS_URL=redis://localhost:6379
```

#### JWT Authentication

```env
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-in-production
JWT_EXPIRATION=7d
```

#### Firebase (Authentication)

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
```

#### Azure Speech Services

```env
AZURE_SPEECH_KEY=your-azure-speech-key
AZURE_SPEECH_REGION=eastus
```

#### AI Providers

```env
# Gemini API (Primary)
GEMINI_API_KEY=your-gemini-api-key

# OpenAI API (Fallback)
OPENAI_API_KEY=your-openai-api-key
```

#### Storage (S3/Cloudflare R2)

```env
S3_ENDPOINT=https://your-account.r2.cloudflarestorage.com
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key
S3_BUCKET_NAME=fluentfly-audio
S3_REGION=auto
CDN_URL=https://cdn.fluentfly.app
```

#### LiveKit Configuration

```env
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
LIVEKIT_URL=ws://localhost:7880
```

#### CORS Configuration

```env
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
```

#### Rate Limiting

```env
RATE_LIMIT_TTL=60           # Time window in seconds
RATE_LIMIT_MAX=100          # Max requests per window
```

## Production Deployment

### Docker Compose Production Setup

1. **Update docker-compose.yml for production**:

```yaml
services:
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      - NODE_ENV=production
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

2. **Use environment file**:

```bash
docker-compose --env-file backend/.env up -d
```

3. **Enable SSL/TLS**:

Add a reverse proxy (nginx or traefik) for HTTPS:

```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - api
```

### Database Backup

```bash
# Backup database
docker-compose exec postgres pg_dump -U postgres fluentfly > backup.sql

# Restore database
docker-compose exec -T postgres psql -U postgres fluentfly < backup.sql
```

### Scaling Services

```bash
# Scale API instances
docker-compose up -d --scale api=3

# View scaled services
docker-compose ps
```

## CI/CD Pipeline

The project includes GitHub Actions workflows for automated testing and deployment.

### Backend CI/CD

**File**: `.github/workflows/backend-ci.yml`

- Runs on push to `main` and pull requests
- Executes unit tests and integration tests
- Builds Docker image
- Pushes to container registry (optional)

### Mobile CI/CD

**File**: `.github/workflows/mobile-ci.yml`

- Runs on push to `main` and pull requests
- Executes Flutter widget tests
- Runs integration tests
- Builds APK for Android
- Builds IPA for iOS (requires macOS runner)

### Deployment Workflow

**File**: `.github/workflows/deploy.yml`

- Triggers on tag creation (e.g., `v1.0.0`)
- Builds and pushes Docker images
- Deploys to production environment
- Runs smoke tests

### Setting Up CI/CD

1. **Add GitHub Secrets**:

Go to repository Settings → Secrets and add:

```
AZURE_SPEECH_KEY
GEMINI_API_KEY
OPENAI_API_KEY
JWT_SECRET
JWT_REFRESH_SECRET
FIREBASE_PROJECT_ID
FIREBASE_PRIVATE_KEY
FIREBASE_CLIENT_EMAIL
S3_ACCESS_KEY
S3_SECRET_KEY
DOCKER_USERNAME (optional)
DOCKER_PASSWORD (optional)
```

2. **Enable GitHub Actions**:

Workflows will run automatically on push/PR.

3. **Manual Deployment**:

```bash
# Tag a release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# This triggers the deployment workflow
```

## Monitoring and Health Checks

### Health Check Endpoint

```bash
curl http://localhost:3000/health
```

Response:
```json
{
  "status": "ok",
  "info": {
    "database": { "status": "up" },
    "redis": { "status": "up" }
  }
}
```

### Docker Health Checks

All services include health checks:

```bash
# Check service health
docker-compose ps

# View health check logs
docker inspect --format='{{json .State.Health}}' fluentfly-api
```

### Logging

View logs for all services:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api

# Last 100 lines
docker-compose logs --tail=100 api
```

### Metrics and Monitoring

For production, integrate with monitoring tools:

- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **Sentry**: Error tracking
- **DataDog**: APM and logging

## Troubleshooting

### API Won't Start

**Problem**: API container exits immediately

**Solution**:
```bash
# Check logs
docker-compose logs api

# Common issues:
# 1. Database not ready - wait for postgres health check
# 2. Missing environment variables - check .env file
# 3. Port already in use - change PORT in docker-compose.yml
```

### Database Connection Errors

**Problem**: `ECONNREFUSED` or connection timeout

**Solution**:
```bash
# Check if postgres is running
docker-compose ps postgres

# Check postgres logs
docker-compose logs postgres

# Verify connection string
docker-compose exec api env | grep DATABASE_URL

# Test connection manually
docker-compose exec postgres psql -U postgres -d fluentfly -c "SELECT 1"
```

### Redis Connection Errors

**Problem**: Redis connection refused

**Solution**:
```bash
# Check redis status
docker-compose ps redis

# Test redis connection
docker-compose exec redis redis-cli ping

# Should return: PONG
```

### Out of Memory Errors

**Problem**: Container crashes with OOM

**Solution**:
```bash
# Increase memory limits in docker-compose.yml
services:
  api:
    deploy:
      resources:
        limits:
          memory: 2G
```

### Slow Performance

**Problem**: API responds slowly

**Solution**:
```bash
# Check resource usage
docker stats

# Optimize database queries
# Add indexes to frequently queried columns

# Increase Redis cache TTL
# Check REDIS_URL and cache configuration
```

### Build Failures

**Problem**: Docker build fails

**Solution**:
```bash
# Clear Docker cache
docker-compose build --no-cache

# Check Dockerfile syntax
docker build -t test ./backend

# Verify all files are present
ls -la backend/
```

### Port Conflicts

**Problem**: Port already in use

**Solution**:
```bash
# Find process using port
lsof -i :3000

# Kill process or change port in docker-compose.yml
services:
  api:
    ports:
      - "3001:3000"  # Use different host port
```

## Security Best Practices

### Production Checklist

- [ ] Change default passwords in docker-compose.yml
- [ ] Use strong JWT secrets (32+ characters)
- [ ] Enable HTTPS with valid SSL certificates
- [ ] Restrict CORS origins to your domain
- [ ] Use environment variables for all secrets
- [ ] Enable rate limiting
- [ ] Set up database backups
- [ ] Configure firewall rules
- [ ] Use non-root user in containers (already configured)
- [ ] Keep dependencies updated
- [ ] Enable Docker security scanning
- [ ] Set up monitoring and alerting

### Secrets Management

Never commit secrets to version control. Use:

- **Docker Secrets** (Docker Swarm)
- **Kubernetes Secrets** (K8s)
- **AWS Secrets Manager** (AWS)
- **HashiCorp Vault** (Multi-cloud)

## Additional Resources

- [NestJS Documentation](https://docs.nestjs.com/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)

## Support

For deployment issues:
1. Check logs: `docker-compose logs -f`
2. Review this guide
3. Open an issue on GitHub
4. Contact the development team

---

**Last Updated**: 2025-01-13
