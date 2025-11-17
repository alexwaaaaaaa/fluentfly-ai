# Quick Fix Guide - Integration Tests

## 🚨 Abhi Kya Karna Hai (Step by Step)

### Step 1: Docker Start Karein

```bash
# Docker Desktop app ko open karein
# Ya terminal se:
open -a Docker

# Wait karein jab tak Docker start na ho jaye (2-3 minutes)
# Docker icon menu bar mein green ho jayega
```

### Step 2: Database Setup (Automatic)

```bash
cd backend

# Setup script run karein
./setup-tests.sh
```

Ye script automatically:
- ✅ PostgreSQL start karega
- ✅ Database schema create karega
- ✅ Seed data load karega
- ✅ .env.test file banayega

### Step 3: Tests Run Karein

```bash
npm run test:e2e
```

---

## 🔧 Manual Setup (Agar Script Fail Ho)

Agar automatic script kaam nahi kare, toh ye manual steps follow karein:

### 1. PostgreSQL Start Karein

```bash
cd backend
docker-compose up -d postgres

# Wait karein (10 seconds)
sleep 10
```

### 2. Database Check Karein

```bash
# Check ki PostgreSQL running hai
docker-compose ps

# Output aisa hona chahiye:
# NAME                IMAGE               STATUS
# backend-postgres-1  postgres:16-alpine  Up
```

### 3. Schema Load Karein

```bash
# Option A: Migrations se (Recommended)
npm run migration:run

# Option B: Direct SQL se
docker-compose exec postgres psql -U postgres -d fluentfly < database/schema.sql
```

### 4. Seed Data Load Karein (IMPORTANT!)

```bash
docker-compose exec postgres psql -U postgres -d fluentfly < database/seeds/lessons.seed.sql
```

### 5. Verify Data

```bash
# Check kitne lessons load hue
docker-compose exec postgres psql -U postgres -d fluentfly -c "SELECT COUNT(*) FROM lessons;"

# Output: count should be > 0
```

### 6. .env.test File Banayein

```bash
cat > .env.test << 'EOF'
DATABASE_URL=postgresql://postgres:password@localhost:5432/fluentfly
JWT_SECRET=test-jwt-secret-key
JWT_REFRESH_SECRET=test-refresh-secret-key
JWT_EXPIRATION=7d
REDIS_URL=redis://localhost:6379
FIREBASE_PROJECT_ID=test-project
FIREBASE_PRIVATE_KEY=test-key
FIREBASE_CLIENT_EMAIL=test@test.com
GEMINI_API_KEY=test-key
OPENAI_API_KEY=test-key
AZURE_SPEECH_KEY=test-key
AZURE_SPEECH_REGION=eastus
EOF
```

### 7. Tests Run Karein

```bash
npm run test:e2e
```

---

## 📊 Expected Results

### Minimal Setup (Database + Seeds):
```
Tests:       43 passed, 13 failed, 56 total
```

**Passing Tests** (43):
- ✅ All lesson retrieval tests
- ✅ Progress tracking tests
- ✅ XP awarding tests
- ✅ Streak management tests
- ✅ Input validation tests
- ✅ Error handling tests

**Failing Tests** (13):
- ❌ Firebase authentication (5 tests) - Need real Firebase credentials
- ❌ AI chat responses (8 tests) - Need Gemini/OpenAI API keys

---

## 🔍 Troubleshooting

### Problem 1: Docker Not Running

**Error**: `Cannot connect to the Docker daemon`

**Fix**:
```bash
# macOS
open -a Docker

# Wait 2-3 minutes for Docker to start
# Check status:
docker ps
```

### Problem 2: Database Connection Failed

**Error**: `ECONNREFUSED` or `Connection refused`

**Fix**:
```bash
# Stop and restart PostgreSQL
docker-compose down
docker-compose up -d postgres
sleep 10

# Test connection
docker-compose exec postgres psql -U postgres -c "SELECT 1;"
```

### Problem 3: No Lessons Found

**Error**: Tests fail with "No lessons found"

**Fix**:
```bash
# Reload seed data
docker-compose exec postgres psql -U postgres -d fluentfly < database/seeds/lessons.seed.sql

# Verify
docker-compose exec postgres psql -U postgres -d fluentfly -c "SELECT COUNT(*) FROM lessons;"
```

### Problem 4: Migration Failed

**Error**: `relation "lessons" already exists`

**Fix**:
```bash
# Drop and recreate database
docker-compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS fluentfly;"
docker-compose exec postgres psql -U postgres -c "CREATE DATABASE fluentfly;"

# Run migrations again
npm run migration:run

# Load seeds
docker-compose exec postgres psql -U postgres -d fluentfly < database/seeds/lessons.seed.sql
```

### Problem 5: Port Already in Use

**Error**: `port 5432 is already allocated`

**Fix**:
```bash
# Check kya chal raha hai port 5432 par
lsof -i :5432

# Agar koi local PostgreSQL chal raha hai, use stop karein
brew services stop postgresql

# Ya docker-compose.yml mein port change karein:
# ports:
#   - "5433:5432"  # Host:Container

# Phir DATABASE_URL update karein:
# postgresql://postgres:password@localhost:5433/fluentfly
```

---

## 🎯 One-Line Commands

### Complete Setup (Copy-Paste)
```bash
cd backend && docker-compose up -d postgres && sleep 10 && npm run migration:run && docker-compose exec postgres psql -U postgres -d fluentfly < database/seeds/lessons.seed.sql && npm run test:e2e
```

### Quick Reset
```bash
docker-compose down && docker-compose up -d postgres && sleep 10 && npm run migration:run && docker-compose exec postgres psql -U postgres -d fluentfly < database/seeds/lessons.seed.sql
```

### Run Specific Test
```bash
npm run test:e2e -- lessons.e2e-spec.ts
```

---

## ✅ Success Checklist

Ye sab check karein tests run karne se pehle:

- [ ] Docker Desktop running hai
- [ ] PostgreSQL container running hai (`docker-compose ps`)
- [ ] Database "fluentfly" exists
- [ ] Tables created hain (`docker-compose exec postgres psql -U postgres -d fluentfly -c "\dt"`)
- [ ] Lessons data loaded hai (count > 0)
- [ ] .env.test file exists
- [ ] npm dependencies installed hain

---

## 📞 Still Having Issues?

Agar abhi bhi problem aa rahi hai, toh ye command run karein aur output share karein:

```bash
# System info
echo "=== Docker Status ==="
docker ps

echo "=== Database Status ==="
docker-compose exec postgres psql -U postgres -c "SELECT version();"

echo "=== Tables ==="
docker-compose exec postgres psql -U postgres -d fluentfly -c "\dt"

echo "=== Lesson Count ==="
docker-compose exec postgres psql -U postgres -d fluentfly -c "SELECT COUNT(*) FROM lessons;"

echo "=== Environment ==="
cat .env.test | grep DATABASE_URL
```

---

## 🚀 Next Steps After Tests Pass

1. **Coverage Report**:
   ```bash
   npm run test:cov
   ```

2. **Watch Mode** (development):
   ```bash
   npm run test:e2e -- --watch
   ```

3. **Specific Test File**:
   ```bash
   npm run test:e2e -- lessons.e2e-spec.ts
   ```

4. **Verbose Output**:
   ```bash
   npm run test:e2e -- --verbose
   ```
