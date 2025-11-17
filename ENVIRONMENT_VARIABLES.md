# Environment Variables Documentation

This document describes all environment variables required to run FluentFly in different environments.

## Table of Contents

1. [Backend Environment Variables](#backend-environment-variables)
2. [Mobile Environment Variables](#mobile-environment-variables)
3. [Environment-Specific Configurations](#environment-specific-configurations)
4. [Security Best Practices](#security-best-practices)

## Backend Environment Variables

### Required Variables

#### Application Configuration

```bash
# Node environment (development, production, test)
NODE_ENV=production

# Server port
PORT=3000

# API base URL
API_URL=https://api.fluentfly.app

# Frontend URL (for CORS)
FRONTEND_URL=https://fluentfly.app

# JWT secret for additional token signing (optional)
JWT_SECRET=your-super-secret-jwt-key-change-this
```

#### Database Configuration

```bash
# PostgreSQL connection
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=fluentfly
DATABASE_USER=postgres
DATABASE_PASSWORD=your-secure-password

# Database URL (alternative to individual vars)
DATABASE_URL=postgresql://user:password@host:5432/fluentfly

# Connection pool settings
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10
```

#### Redis Configuration

```bash
# Redis connection
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# Redis URL (alternative)
REDIS_URL=redis://:password@host:6379

# Redis TTL defaults (seconds)
REDIS_DEFAULT_TTL=3600
```

#### Firebase Configuration

```bash
# Firebase Admin SDK
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Or use service account file path
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

#### AI Services

```bash
# OpenAI API
OPENAI_API_KEY=sk-...your-openai-key

# Google Gemini API
GEMINI_API_KEY=your-gemini-api-key

# AI model selection
AI_PROVIDER=gemini  # or 'openai'
AI_MODEL=gemini-pro  # or 'gpt-4'
```

#### Speech Services

```bash
# Google Cloud Speech-to-Text
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=./google-credentials.json

# ElevenLabs Text-to-Speech
ELEVENLABS_API_KEY=your-elevenlabs-key
ELEVENLABS_VOICE_ID=21m00Tcm4TlvDq8ikWAM  # Default voice

# Speech service selection
TTS_PROVIDER=elevenlabs  # or 'google'
STT_PROVIDER=google
```

#### Storage Configuration

```bash
# Cloudflare R2 / S3 Compatible Storage
R2_ACCOUNT_ID=your-account-id
R2_ACCESS_KEY_ID=your-access-key
R2_SECRET_ACCESS_KEY=your-secret-key
R2_BUCKET_NAME=fluentfly-assets
R2_PUBLIC_URL=https://assets.fluentfly.app

# Or AWS S3
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
S3_BUCKET_NAME=fluentfly-assets
```

#### Rate Limiting

```bash
# Rate limit configuration
RATE_LIMIT_TTL=60  # seconds
RATE_LIMIT_MAX=100  # requests per TTL
RATE_LIMIT_AI_MAX=20  # AI endpoint limit
RATE_LIMIT_SPEECH_MAX=30  # Speech endpoint limit
```

#### Logging

```bash
# Log level (error, warn, info, debug)
LOG_LEVEL=info

# Log format (json, pretty)
LOG_FORMAT=json

# Enable request logging
LOG_REQUESTS=true
```

### Optional Variables

```bash
# Sentry error tracking
SENTRY_DSN=https://...@sentry.io/...

# Email service (for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@fluentfly.app
SMTP_PASSWORD=your-email-password

# Webhook configuration
WEBHOOK_SECRET=your-webhook-secret
WEBHOOK_ENABLED=true

# Feature flags
ENABLE_AI_CHAT=true
ENABLE_SPEECH_RECOGNITION=true
ENABLE_LEADERBOARD=true
```

## Mobile Environment Variables

### Flutter Environment Configuration

Create `.env` files for different environments:

#### `.env.development`

```bash
# API Configuration
API_BASE_URL=http://localhost:3000
API_TIMEOUT=30000

# Firebase Configuration
FIREBASE_API_KEY=your-api-key
FIREBASE_APP_ID=your-app-id
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-bucket

# Feature Flags
ENABLE_ANALYTICS=false
ENABLE_CRASHLYTICS=false
ENABLE_DEBUG_LOGGING=true

# App Configuration
APP_NAME=FluentFly Dev
APP_ENVIRONMENT=development
```

#### `.env.production`

```bash
# API Configuration
API_BASE_URL=https://api.fluentfly.app
API_TIMEOUT=30000

# Firebase Configuration
FIREBASE_API_KEY=your-production-api-key
FIREBASE_APP_ID=your-production-app-id
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_PROJECT_ID=your-production-project-id
FIREBASE_STORAGE_BUCKET=your-production-bucket

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
ENABLE_DEBUG_LOGGING=false

# App Configuration
APP_NAME=FluentFly
APP_ENVIRONMENT=production
```

### Android Configuration

#### `android/local.properties`

```properties
sdk.dir=/Users/username/Library/Android/sdk
flutter.sdk=/Users/username/flutter
```

#### `android/key.properties` (for release builds)

```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=fluentfly
storeFile=/path/to/keystore.jks
```

### iOS Configuration

Configure in Xcode or `ios/Flutter/Release.xcconfig`:

```
FLUTTER_BUILD_MODE=release
FLUTTER_BUILD_NAME=1.0.0
FLUTTER_BUILD_NUMBER=1
```

## Environment-Specific Configurations

### Development Environment

```bash
# .env.development
NODE_ENV=development
PORT=3000
DATABASE_HOST=localhost
REDIS_HOST=localhost
LOG_LEVEL=debug
LOG_FORMAT=pretty
ENABLE_SWAGGER=true
```

### Staging Environment

```bash
# .env.staging
NODE_ENV=production
PORT=3000
DATABASE_HOST=staging-db.fluentfly.app
REDIS_HOST=staging-redis.fluentfly.app
LOG_LEVEL=info
LOG_FORMAT=json
ENABLE_SWAGGER=true
```

### Production Environment

```bash
# .env.production
NODE_ENV=production
PORT=3000
DATABASE_HOST=prod-db.fluentfly.app
REDIS_HOST=prod-redis.fluentfly.app
LOG_LEVEL=warn
LOG_FORMAT=json
ENABLE_SWAGGER=false
```

### Test Environment

```bash
# .env.test
NODE_ENV=test
PORT=3001
DATABASE_HOST=localhost
DATABASE_NAME=fluentfly_test
REDIS_HOST=localhost
LOG_LEVEL=error
```

## Docker Configuration

### docker-compose.yml Environment

```yaml
environment:
  - NODE_ENV=production
  - DATABASE_HOST=postgres
  - REDIS_HOST=redis
  - PORT=3000
```

### Using .env file with Docker

```bash
# docker-compose.yml
env_file:
  - .env.production
```

## Security Best Practices

### 1. Never Commit Secrets

```bash
# .gitignore
.env
.env.*
!.env.example
*.key
*.pem
firebase-service-account.json
google-credentials.json
android/key.properties
```

### 2. Use Environment-Specific Files

- `.env.example` - Template with dummy values (committed)
- `.env.development` - Local development (not committed)
- `.env.production` - Production secrets (not committed)

### 3. Rotate Secrets Regularly

- Change API keys every 90 days
- Rotate database passwords quarterly
- Update JWT secrets periodically

### 4. Use Secret Management

**For Production:**
- AWS Secrets Manager
- Google Cloud Secret Manager
- HashiCorp Vault
- Kubernetes Secrets

**Example with AWS Secrets Manager:**
```bash
# Fetch secrets at runtime
aws secretsmanager get-secret-value \
  --secret-id fluentfly/production \
  --query SecretString \
  --output text
```

### 5. Validate Environment Variables

```typescript
// backend/src/config/env.validation.ts
import { plainToClass } from 'class-transformer';
import { IsString, IsNumber, validateSync } from 'class-validator';

class EnvironmentVariables {
  @IsString()
  NODE_ENV: string;

  @IsNumber()
  PORT: number;

  @IsString()
  DATABASE_URL: string;

  // ... more validations
}

export function validate(config: Record<string, unknown>) {
  const validatedConfig = plainToClass(
    EnvironmentVariables,
    config,
    { enableImplicitConversion: true },
  );
  
  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    throw new Error(errors.toString());
  }
  
  return validatedConfig;
}
```

### 6. Minimum Required Permissions

Grant only necessary permissions:
- Database user: Read/write to specific tables only
- Storage: Access to specific buckets only
- API keys: Restrict by IP or domain when possible

## Setup Instructions

### Backend Setup

1. **Copy example file:**
   ```bash
   cp .env.example .env
   ```

2. **Fill in values:**
   ```bash
   nano .env
   ```

3. **Validate configuration:**
   ```bash
   npm run validate:env
   ```

4. **Start application:**
   ```bash
   npm run start
   ```

### Mobile Setup

1. **Copy example files:**
   ```bash
   cp .env.example .env.development
   cp .env.example .env.production
   ```

2. **Configure Firebase:**
   - Download `google-services.json` (Android)
   - Download `GoogleService-Info.plist` (iOS)
   - Place in respective directories

3. **Build application:**
   ```bash
   flutter build apk --dart-define-from-file=.env.production
   ```

## Troubleshooting

### Common Issues

#### "Environment variable not found"

**Solution:**
1. Check `.env` file exists
2. Verify variable name spelling
3. Restart application after changes

#### "Invalid Firebase credentials"

**Solution:**
1. Verify `FIREBASE_PROJECT_ID` is correct
2. Check private key format (includes `\n`)
3. Ensure service account has proper permissions

#### "Database connection failed"

**Solution:**
1. Verify `DATABASE_HOST` is accessible
2. Check firewall rules
3. Confirm credentials are correct
4. Test connection: `psql -h $DATABASE_HOST -U $DATABASE_USER`

#### "Redis connection timeout"

**Solution:**
1. Verify Redis is running: `redis-cli ping`
2. Check `REDIS_HOST` and `REDIS_PORT`
3. Verify password if required

## Environment Variable Checklist

### Before Deployment

- [ ] All required variables are set
- [ ] Secrets are not committed to git
- [ ] Production uses strong passwords
- [ ] API keys have proper restrictions
- [ ] Database credentials are secure
- [ ] Redis password is set
- [ ] Firebase service account is configured
- [ ] Storage credentials are valid
- [ ] CORS origins are configured
- [ ] Rate limits are appropriate
- [ ] Logging level is correct
- [ ] Error tracking is enabled

### After Deployment

- [ ] Test all API endpoints
- [ ] Verify database connectivity
- [ ] Check Redis caching works
- [ ] Confirm Firebase auth works
- [ ] Test file uploads
- [ ] Verify AI services respond
- [ ] Check speech services work
- [ ] Monitor error logs
- [ ] Validate rate limiting
- [ ] Test mobile app connectivity

## Support

For environment configuration help:
- Email: devops@fluentfly.app
- Documentation: https://docs.fluentfly.app/environment
- Slack: #infrastructure channel
