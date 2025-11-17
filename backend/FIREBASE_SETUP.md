# Firebase Setup Guide for FluentFly Backend

## 📋 Aapke Firebase Project Details

```
Project ID: fluentfly-d442d
Project Number: 92913866663
Storage Bucket: fluentfly-d442d.firebasestorage.app
```

## 🔑 Step 1: Service Account Key Download Karein

Aapne jo JSON file share ki hai, wo **google-services.json** hai (mobile app ke liye). Backend ke liye aapko **Service Account Key** chahiye.

### Download Kaise Karein:

1. **Firebase Console mein jaayein**:
   ```
   https://console.firebase.google.com/project/fluentfly-d442d/settings/serviceaccounts/adminsdk
   ```

2. **"Generate New Private Key" button click karein**

3. Ek JSON file download hogi jisme ye fields honge:
   ```json
   {
     "type": "service_account",
     "project_id": "fluentfly-d442d",
     "private_key_id": "...",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-xxxxx@fluentfly-d442d.iam.gserviceaccount.com",
     "client_id": "...",
     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
     "token_uri": "https://oauth2.googleapis.com/token",
     ...
   }
   ```

## 🔧 Step 2: Backend mein Configure Karein

### Option A: Environment Variables (Recommended for Production)

Downloaded service account key se ye values copy karein aur `.env` file mein add karein:

```bash
# backend/.env file mein ye lines update karein

FIREBASE_PROJECT_ID=fluentfly-d442d
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour actual private key here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@fluentfly-d442d.iam.gserviceaccount.com
```

**Important Notes**:
- `FIREBASE_PRIVATE_KEY` ko double quotes mein rakhein
- `\n` characters ko preserve karein (replace mat karein)
- Private key ko exactly copy karein jaise download hui file mein hai

### Option B: JSON File (Easier for Development)

1. Downloaded service account key file ko save karein:
   ```bash
   # Backend directory mein
   cp ~/Downloads/fluentfly-d442d-firebase-adminsdk-xxxxx.json ./firebase-service-account.json
   ```

2. `.gitignore` mein add karein (security ke liye):
   ```bash
   echo "firebase-service-account.json" >> .gitignore
   ```

3. Code mein use karein (auth.service.ts already configured hai):
   ```typescript
   // Ye already implemented hai, bas file path check karein
   const serviceAccount = require('../../firebase-service-account.json');
   ```

## 🔐 Step 3: Authentication Enable Karein

Firebase Console mein authentication methods enable karein:

### Phone Authentication:

1. Firebase Console mein jaayein:
   ```
   https://console.firebase.google.com/project/fluentfly-d442d/authentication/providers
   ```

2. **Phone** provider enable karein

3. Test phone numbers add kar sakte hain (optional):
   - Settings > Phone numbers for testing
   - Example: `+15555555555` with OTP `123456`

### Google Sign-In:

1. Same page par **Google** provider enable karein

2. Support email add karein

3. OAuth client IDs automatically configure ho jayenge

## ✅ Step 4: Verify Setup

### Quick Test Script:

```bash
# Backend directory mein
cat > test-firebase.js << 'EOF'
const admin = require('firebase-admin');

// Option 1: Environment variables se
const serviceAccount = {
  projectId: process.env.FIREBASE_PROJECT_ID,
  privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
};

// Option 2: JSON file se (uncomment if using file)
// const serviceAccount = require('./firebase-service-account.json');

try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('✓ Firebase initialized successfully!');
  console.log('Project ID:', admin.app().options.projectId);
  process.exit(0);
} catch (error) {
  console.error('✗ Firebase initialization failed:', error.message);
  process.exit(1);
}
EOF

# Test run karein
node test-firebase.js

# Cleanup
rm test-firebase.js
```

## 🧪 Step 5: Integration Tests Run Karein

Ab aap tests run kar sakte hain:

```bash
# Setup script run karein (agar pehle nahi kiya)
./setup-tests.sh

# Tests run karein
npm run test:e2e

# Sirf auth tests run karein
npm run test:e2e -- auth.e2e-spec.ts
```

## 📝 Complete .env Example

Ye raha complete `.env` file ka example with your Firebase project:

```bash
# Application Configuration
NODE_ENV=development
PORT=3000
API_URL=http://localhost:3000

# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/fluentfly

# Redis Configuration
REDIS_URL=redis://localhost:6379

# JWT Authentication
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-in-production
JWT_EXPIRATION=7d

# Firebase Configuration (YOUR ACTUAL VALUES)
FIREBASE_PROJECT_ID=fluentfly-d442d
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nPASTE YOUR ACTUAL PRIVATE KEY HERE\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@fluentfly-d442d.iam.gserviceaccount.com

# Azure Speech Services (Optional)
AZURE_SPEECH_KEY=your-azure-speech-key
AZURE_SPEECH_REGION=eastus

# AI Providers (Optional)
GEMINI_API_KEY=your-gemini-api-key
OPENAI_API_KEY=your-openai-api-key

# Storage (Optional)
S3_ENDPOINT=https://your-account.r2.cloudflarestorage.com
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key
S3_BUCKET_NAME=fluentfly-audio
S3_REGION=auto
CDN_URL=https://cdn.fluentfly.app

# LiveKit Configuration (Optional)
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
LIVEKIT_URL=ws://localhost:7880

# CORS Configuration
CORS_ORIGIN=http://localhost:3000,http://localhost:8080

# Rate Limiting
RATE_LIMIT_TTL=60
RATE_LIMIT_MAX=100
```

## 🔍 Troubleshooting

### Error: "Failed to parse private key"

**Problem**: Private key format galat hai

**Solution**:
```bash
# Private key ko properly format karein
# Ensure \n characters are preserved
# Use double quotes around the entire key
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
```

### Error: "Project ID does not match"

**Problem**: Wrong project ID

**Solution**:
```bash
# Verify project ID
FIREBASE_PROJECT_ID=fluentfly-d442d  # Ye aapka correct project ID hai
```

### Error: "Client email is invalid"

**Problem**: Service account email galat hai

**Solution**:
```bash
# Service account key file se exact email copy karein
# Format: firebase-adminsdk-xxxxx@fluentfly-d442d.iam.gserviceaccount.com
```

## 🎯 Quick Setup Commands

Agar aap abhi turant setup karna chahte hain:

```bash
# 1. Firebase Console se service account key download karein
# URL: https://console.firebase.google.com/project/fluentfly-d442d/settings/serviceaccounts/adminsdk

# 2. File ko backend directory mein save karein
mv ~/Downloads/fluentfly-d442d-*.json backend/firebase-service-account.json

# 3. .gitignore mein add karein
echo "firebase-service-account.json" >> backend/.gitignore

# 4. Database setup karein
cd backend
./setup-tests.sh

# 5. Tests run karein
npm run test:e2e
```

## 📚 Additional Resources

- Firebase Admin SDK Docs: https://firebase.google.com/docs/admin/setup
- Phone Authentication: https://firebase.google.com/docs/auth/admin/verify-id-tokens
- Service Account Keys: https://cloud.google.com/iam/docs/service-accounts

## 🆘 Need Help?

Agar abhi bhi issues aa rahe hain:

1. Check Firebase Console: https://console.firebase.google.com/project/fluentfly-d442d
2. Verify authentication is enabled
3. Check service account permissions
4. Review error logs: `npm run test:e2e 2>&1 | grep Firebase`
