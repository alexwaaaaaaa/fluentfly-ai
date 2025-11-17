# FluentFly Deployment - Quick Start Guide

## 🚀 5-Minute Setup

### Prerequisites
- Docker Desktop installed
- Git installed

### Step 1: Clone and Setup
```bash
git clone <repository-url>
cd fluentfly
./setup.sh  # Linux/macOS
# OR
setup.bat   # Windows
```

### Step 2: Configure Environment
```bash
# Edit backend/.env with your API keys
nano backend/.env  # or use your favorite editor
```

**Required keys:**
- `AZURE_SPEECH_KEY` - Get from Azure Portal
- `GEMINI_API_KEY` - Get from Google AI Studio
- `OPENAI_API_KEY` - Get from OpenAI Platform
- `JWT_SECRET` - Generate: `openssl rand -base64 32`

### Step 3: Start Services
```bash
docker-compose up -d
```

### Step 4: Verify
```bash
# Check services
docker-compose ps

# Test API
curl http://localhost:3000/health

# View logs
docker-compose logs -f api
```

## 📱 Access Points

- **API**: http://localhost:3000
- **API Docs**: http://localhost:3000/api/docs
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **LiveKit**: localhost:7880

## 🛠️ Common Commands

### Using Makefile (Recommended)
```bash
make start      # Start all services
make stop       # Stop all services
make logs       # View logs
make test       # Run tests
make db-backup  # Backup database
make help       # Show all commands
```

### Using Docker Compose
```bash
docker-compose up -d          # Start services
docker-compose down           # Stop services
docker-compose logs -f api    # View API logs
docker-compose restart api    # Restart API
docker-compose ps             # Service status
```

## 🧪 Running Tests

### Backend Tests
```bash
cd backend
npm test              # Unit tests
npm run test:e2e      # Integration tests
npm run test:cov      # With coverage
```

### Mobile Tests
```bash
cd mobile
flutter test          # Widget tests
flutter test integration_test  # Integration tests
```

## 🚢 Deployment

### Development
```bash
docker-compose up -d
```

### Production
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### CI/CD Deployment
```bash
# Create a release
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# GitHub Actions will automatically:
# - Run tests
# - Build Docker images
# - Create GitHub release
# - Deploy to production
```

## 🔧 Troubleshooting

### Services Won't Start
```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart

# Clean restart
docker-compose down -v
docker-compose up -d
```

### Database Issues
```bash
# Reset database
make db-reset

# Backup database
make db-backup

# Restore database
make db-restore
```

### API Not Responding
```bash
# Check API logs
docker-compose logs api

# Check health
curl http://localhost:3000/health

# Restart API
docker-compose restart api
```

## 📚 Documentation

- **Full Deployment Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **CI/CD Documentation**: [.github/CICD.md](.github/CICD.md)
- **Main README**: [README.md](README.md)
- **Task Summary**: [TASK_19_DEPLOYMENT_SUMMARY.md](TASK_19_DEPLOYMENT_SUMMARY.md)

## 🔐 Security Checklist

Before deploying to production:

- [ ] Change default passwords in docker-compose.yml
- [ ] Use strong JWT secrets (32+ characters)
- [ ] Enable HTTPS with valid SSL certificates
- [ ] Restrict CORS origins to your domain
- [ ] Set up database backups
- [ ] Configure firewall rules
- [ ] Enable monitoring and alerting
- [ ] Review and update all environment variables

## 💡 Tips

1. **Use Makefile**: Simplifies common operations
2. **Check Logs**: Always check logs when troubleshooting
3. **Backup Regularly**: Use `make db-backup` before major changes
4. **Monitor Health**: Set up health check monitoring
5. **Keep Updated**: Regularly update dependencies

## 🆘 Getting Help

1. Check logs: `docker-compose logs -f`
2. Review [DEPLOYMENT.md](DEPLOYMENT.md)
3. Check [Troubleshooting section](DEPLOYMENT.md#troubleshooting)
4. Open an issue on GitHub

## 🎯 Next Steps

1. Configure all environment variables
2. Run tests to verify setup
3. Deploy mobile app: `cd mobile && flutter run`
4. Set up CI/CD secrets in GitHub
5. Configure production environment
6. Set up monitoring and alerts

---

**Quick Links:**
- [Full Deployment Guide](DEPLOYMENT.md)
- [CI/CD Setup](.github/CICD.md)
- [API Documentation](http://localhost:3000/api/docs)
- [GitHub Repository](https://github.com/your-org/fluentfly)
