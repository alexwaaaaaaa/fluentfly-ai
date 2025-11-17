# Authentication System Implementation

## Overview
This document describes the authentication and authorization system implemented for FluentFly.

## Backend Implementation

### Features Implemented
1. **JWT-based Authentication**
   - Access tokens (7-day expiration)
   - Refresh tokens (30-day expiration)
   - Automatic token refresh on 401 errors

2. **Google OAuth Integration**
   - Firebase Admin SDK for ID token verification
   - Automatic user creation on first login
   - Profile image support

3. **Phone OTP Authentication**
   - 6-digit OTP generation
   - 10-minute OTP expiration
   - Rate limiting (5 attempts per 15 minutes)
   - Redis-based OTP storage

4. **Security Measures**
   - Input validation using class-validator
   - Rate limiting (100 req/min) with @nestjs/throttler
   - CORS configuration with restricted origins
   - Global exception filter for error handling
   - Request logging interceptor
   - JWT auth guard with @Public decorator support

### API Endpoints

#### POST /api/auth/google
Authenticate with Google OAuth
```json
Request:
{
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
}

Response:
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "xp": 0,
    "streak": 0,
    "level": "A1"
  }
}
```

#### POST /api/auth/phone/send-otp
Send OTP to phone number
```json
Request:
{
  "phone": "+919876543210"
}

Response:
{
  "success": true
}
```

#### POST /api/auth/phone/verify-otp
Verify OTP and authenticate
```json
Request:
{
  "phone": "+919876543210",
  "otp": "123456",
  "name": "John Doe" // Optional, for new users
}

Response:
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "phone": "+919876543210",
    "name": "John Doe",
    "xp": 0,
    "streak": 0,
    "level": "A1"
  }
}
```

#### POST /api/auth/refresh
Refresh access token
```json
Request:
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

Response:
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { ... }
}
```

### Environment Variables Required
```bash
# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-in-production
JWT_EXPIRATION=7d

# Firebase (for Google OAuth and Phone OTP)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# Google OAuth (optional, if using passport-google-oauth20)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_CALLBACK_URL=http://localhost:3000/api/auth/google/callback
```

### Guards and Decorators

#### @Public() Decorator
Mark endpoints as public (no authentication required)
```typescript
@Public()
@Get('public-endpoint')
async publicEndpoint() {
  return { message: 'This is public' };
}
```

#### @CurrentUser() Decorator
Get the authenticated user in controllers
```typescript
@Get('profile')
async getProfile(@CurrentUser() user: User) {
  return user;
}
```

## Flutter Mobile Implementation

### Features Implemented
1. **Login Screen**
   - Google Sign-In button
   - Phone number input with validation
   - E.164 format validation
   - Error handling and display

2. **OTP Verification Screen**
   - 6-digit OTP input with auto-focus
   - Auto-verify on complete input
   - Resend OTP functionality
   - Optional name field for new users

3. **Auth Service**
   - API communication with Dio
   - Secure token storage with flutter_secure_storage
   - Automatic token refresh on 401 errors
   - Logout functionality

4. **State Management**
   - Riverpod for auth state
   - Loading states
   - Error handling
   - User-friendly error messages

### Usage Example

```dart
// In your app
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

// Check authentication status
final authState = ref.watch(authProvider);
if (authState.isAuthenticated) {
  // Navigate to home
} else {
  // Show login screen
}

// Logout
await ref.read(authProvider.notifier).logout();
```

### API Configuration
Update the base URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://your-api-url/api';
```

## Testing

### Backend Testing
```bash
cd backend
npm test
```

### Manual Testing with cURL

#### Send OTP
```bash
curl -X POST http://localhost:3000/api/auth/phone/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+919876543210"}'
```

#### Verify OTP
```bash
curl -X POST http://localhost:3000/api/auth/phone/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+919876543210", "otp": "123456", "name": "Test User"}'
```

## Security Considerations

1. **Token Storage**: Tokens are stored securely using flutter_secure_storage on mobile
2. **Rate Limiting**: OTP requests are limited to 5 per 15 minutes per phone number
3. **Token Expiration**: Access tokens expire after 7 days, refresh tokens after 30 days
4. **HTTPS**: Always use HTTPS in production
5. **Environment Variables**: Never commit secrets to version control

## Next Steps

1. Integrate Google Sign-In SDK in Flutter app
2. Configure Firebase project for production
3. Set up SMS service for OTP delivery (Twilio, AWS SNS, etc.)
4. Add biometric authentication support
5. Implement account recovery flow
