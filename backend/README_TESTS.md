# Integration Tests - Quick Start

## 🎯 Sabse Pehle Ye Karein

### 1. Docker Start Karein
```bash
open -a Docker
# Wait 2-3 minutes
```

### 2. Setup Script Run Karein
```bash
cd backend
chmod +x setup-tests.sh
./setup-tests.sh
```

### 3. Tests Run Karein
```bash
npm run test:e2e
```

## 📚 Detailed Guides

- **Quick Fix**: `QUICK_FIX_GUIDE.md` - Step-by-step troubleshooting
- **Complete Setup**: `TEST_SETUP_GUIDE.md` - Detailed setup instructions
- **Test Summary**: `TEST_INTEGRATION_SUMMARY.md` - What tests do

## ⚡ Common Commands

```bash
# All tests
npm run test:e2e

# Specific test file
npm run test:e2e -- lessons.e2e-spec.ts

# With coverage
npm run test:cov

# Reset database
docker-compose down
docker-compose up -d postgres
sleep 10
npm run migration:run
docker-compose exec postgres psql -U postgres -d fluentfly < database/seeds/lessons.seed.sql
```

## 🎯 Expected Results

**With Database + Seeds**: 43 tests pass ✅
**With Firebase + APIs**: 56 tests pass ✅

## 🆘 Problems?

1. Check `QUICK_FIX_GUIDE.md`
2. Run: `docker-compose ps` (PostgreSQL should be "Up")
3. Run: `docker-compose logs postgres` (check for errors)
