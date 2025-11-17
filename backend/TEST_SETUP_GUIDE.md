# Integration Tests Setup Guide (Hindi + English)

## 🎯 Overview / सारांश

Integration tests ko successfully run karne ke liye aapko 2 main cheezein setup karni hongi:
1. **Database** - PostgreSQL with seeded data
2. **Firebase** (Optional) - Phone OTP authentication ke liye

## 📋 Step-by-Step Setup

### Step 1: Database Setup करें

#### Option A: Docker se (Recommended)

```bash
# 1. Docker Compose se PostgreSQL start karein
cd backend
docker-compose up -d postgres

# 2. Database ready hone ka wait karein (5-10 seconds)
sleep 10

# 3. Check karein ki database running hai
docker-compose ps
```

#### Option B: Local PostgreSQL

Agar aapke paas already PostgreSQL installed hai:

```bash
# PostgreSQL service start karein
# macOS:
brew services start postgresql

# Linux:
sudo systemctl start postgresql

# Database create karein
createdb fluentfly
```

### Step 2: Database Schema aur Data Load करें

```bash
# Backend directory mein jaayein
cd backend

# Method 1: TypeORM migrations se (Recommended)
npm run migration:run

# Method 2: Direct SQL file se
psql -U postgres -d fluentfly < database/schema.sql

# Seed data load karein (IMPORTANT!)
psql -U postgres -d fluentfly < database/seeds/lessons.seed.sql
```

**Note**: Seed data bahut important hai! Bina seed data ke lessons tests fail ho jayenge.

### Step 3: Environment Variables Setup करें

Test environment ke liye `.env.test` file banayein:

```bash
# .env.test file create karein
cat > backend/.env.test << 'EOF'
# Test Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/fluentfly

# JWT Secrets (test values)
JWT_SECRET=test-jwt-secret-key-for-integration-tests
JWT_REFRESH_SECRET=test-refresh-secret-key-for-integration-tests
JWT_EXPIRATION=7d

# Redis (optional for tests)
REDIS_URL=redis://localhost:6379

# Firebase (OPTIONAL - tests will handle missing config)
# Agar aapke paas Firebase credentials nahi hain, toh ye skip kar sakte hain
# Tests automatically handle missing Firebase
FIREBASE_PROJECT_ID=test-project
FIREBASE_PRIVATE_KEY=test-key
FIREBASE_CLIENT_EMAIL=test@test.com

# AI Services (OPTIONAL - tests will handle missing config)
GEMINI_API_KEY=test-key
OPENAI_API_KEY=test-key

# Azure Speech (OPTIONAL)
AZURE_SPEECH_KEY=test-key
AZURE_SPEECH_REGION=eastus

# Storage (OPTIONAL)
S3_ENDPOINT=http://localhost:9000
S3_ACCESS_KEY=test
S3_SECRET_KEY=test
S3_BUCKET_NAME=test-bucket
S3_REGION=auto

# LiveKit (OPTIONAL)
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
LIVEKIT_URL=ws://localhost:7880
EOF
```

### Step 4: Firebase Setup (Optional but Recommended)

Firebase setup karne ke liye:

#### 4.1 Firebase Console mein jaayein

1. https://console.firebase.google.com/ par jaayein
2. Naya project banayein ya existing project select karein
3. **Authentication** enable karein:
   - Phone authentication enable karein
   - Google Sign-In enable karein

#### 4.2 Service Account Key Download karein

1. Firebase Console mein **Project Settings** > **Service Accounts** par jaayein
2. **Generate New Private Key** button click karein
3. JSON file download ho jayegi

#### 4.3 Credentials Extract karein

Downloaded JSON file se ye values copy karein:

```json
{
  "project_id": "your-project-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com"
}
```

#### 4.4 .env file mein add karein

```bash
# backend/.env file mein ye values update karein
FIREBASE_PROJECT_ID=your-actual-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour actual key here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
```

**Important**: `FIREBASE_PRIVATE_KEY` ko quotes mein rakhein aur `\n` ko preserve karein!

### Step 5: Tests Run karein

```bash
# Backend directory mein
cd backend

# Sab tests run karein
npm run test:e2e

# Specific test file run karein
npm run test:e2e -- lessons.e2e-spec.ts

# Verbose output ke saath
npm run test:e2e -- --verbose
```

## 🔍 Common Issues aur Solutions

### Issue 1: Database Connection Failed

**Error**: `ECONNREFUSED` ya `database "fluentfly" does not exist`

**Solution**:
```bash
# Check PostgreSQL running hai ya nahi
docker-compose ps
# ya
pg_isready

# Database create karein
createdb fluentfly

# Connection test karein
psql -U postgres -d fluentfly -c "SELECT 1;"
```

### Issue 2: Firebase Authentication Failed

**Error**: `Failed to parse private key: Error: Invalid PEM formatted message`

**Solution**:
```bash
# Option 1: Firebase credentials ko properly format karein
# Private key mein \n characters hone chahiye

# Option 2: Tests ko bina Firebase ke run karein
# Tests automatically handle missing Firebase
# Auth tests expected failures show karenge but baaki tests pass honge
```

### Issue 3: No Lessons Found

**Error**: Tests fail with "No lessons found in database"

**Solution**:
```bash
# Seed data load karein
psql -U postgres -d fluentfly < database/seeds/lessons.seed.sql

# Verify data loaded hai
psql -U postgres -d fluentfly -c "SELECT COUNT(*) FROM lessons;"
```

### Issue 4: Redis Connection Failed

**Error**: `ECONNREFUSED localhost:6379`

**Solution**:
```bash
# Redis start karein
docker-compose up -d redis

# Ya Redis ko disable karein test environment mein
# .env.test se REDIS_URL comment out kar dein
```

## 📊 Expected Test Results

### With Full Setup (Database + Firebase + External Services)
```
Test Suites: 5 passed, 5 total
Tests:       56 passed, 56 total
```

### With Minimal Setup (Only Database)
```
Test Suites: 4 failed, 1 passed, 5 total
Tests:       33 failed, 23 passed, 56 total
```

**Failed tests breakdown**:
- 5 tests: Firebase authentication (expected without Firebase)
- 8 tests: External AI services (expected without API keys)
- 12 tests: Database seeding (need to run seed script)
- 8 tests: Other external services

### With Database + Seeds (Minimum for Core Tests)
```
Test Suites: 2 failed, 3 passed, 5 total
Tests:       13 failed, 43 passed, 56 total
```

## ✅ Quick Start (Minimal Setup)

Agar aap sirf basic tests run karna chahte hain:

```bash
# 1. Database start karein
docker-compose up -d postgres

# 2. Wait karein
sleep 10

# 3. Schema load karein
npm run migration:run

# 4. Seed data load karein
psql -U postgres -d fluentfly < database/seeds/lessons.seed.sql

# 5. Tests run karein
npm run test:e2e
```

Ye setup se kam se kam **43 tests pass** ho jayenge!

## 🎓 Test Categories

### ✅ Tests jo bina external services ke pass honge:
- Lessons retrieval (with seeded data)
- Progress tracking (with database)
- Basic authentication structure
- Input validation
- Error handling

### ⚠️ Tests jo external services chahiye:
- Firebase phone OTP
- Google OAuth
- AI chat responses
- Speech-to-text
- Text-to-speech

## 📝 Notes

1. **Test Database**: Production database use mat karein! Separate test database use karein.

2. **Data Cleanup**: Tests automatically cleanup karte hain `afterAll` hooks mein.

3. **Parallel Execution**: Tests parallel run hote hain, isliye isolated hone chahiye.

4. **CI/CD**: GitHub Actions ya Jenkins mein run karne ke liye Docker Compose use karein.

## 🆘 Help

Agar abhi bhi issues aa rahe hain:

1. Check logs:
   ```bash
   npm run test:e2e 2>&1 | tee test-output.log
   ```

2. Database state check karein:
   ```bash
   psql -U postgres -d fluentfly -c "\dt"  # Tables list
   psql -U postgres -d fluentfly -c "SELECT COUNT(*) FROM lessons;"
   psql -U postgres -d fluentfly -c "SELECT COUNT(*) FROM users;"
   ```

3. Environment variables verify karein:
   ```bash
   cat backend/.env | grep DATABASE_URL
   ```

## 🚀 Next Steps

Tests pass hone ke baad:
1. Coverage report generate karein: `npm run test:cov`
2. CI/CD pipeline mein integrate karein
3. Pre-commit hooks add karein
4. Test documentation update karein
