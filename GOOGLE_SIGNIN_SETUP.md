# Google Sign-In Setup Guide

## What I've Done

I've added Google Sign-In functionality to your app. Here's what was changed:

### 1. Added google_sign_in Package
- Updated `mobile/pubspec.yaml` to include `google_sign_in: ^6.2.1`

### 2. Implemented Google Sign-In in Login Screen
- Updated `mobile/lib/screens/auth/login_screen.dart` with full Google Sign-In implementation
- The button now properly triggers Google authentication flow
- Gets ID token from Google and sends it to your backend

## Manual Steps Required

Since I'm having issues running Flutter commands, please run these commands manually:

### Step 1: Install Dependencies
```bash
cd mobile
flutter pub get
```

### Step 2: Run the App
```bash
flutter run -d emulator-5554
```

## How It Works Now

1. **User clicks "Continue with Google"**
   - Opens Google account picker
   - User selects their Google account
   - Google returns an ID token

2. **App sends ID token to backend**
   - Calls `/api/auth/google` endpoint
   - Backend verifies token with Firebase Admin SDK
   - Backend creates/finds user and returns JWT tokens

3. **User is logged in**
   - App stores JWT tokens
   - Navigates to home screen

## Testing Google Sign-In

1. Make sure backend is running:
   ```bash
   cd backend
   npm run start:dev
   ```

2. Make sure emulator is running

3. Run the Flutter app:
   ```bash
   cd mobile
   flutter run -d emulator-5554
   ```

4. Click "Continue with Google" button

5. Select a Google account

6. Check backend logs for:
   ```
   [HTTP] info: → POST /api/auth/google
   [AuthService] info: New user created via Google OAuth: user@gmail.com
   [HTTP] info: ← POST /api/auth/google 201
   ```

## Current Configuration

### Backend (Already Configured ✅)
- Firebase Admin SDK initialized
- Google OAuth endpoint ready at `/api/auth/google`
- Verifies Google ID tokens

### Mobile (Just Updated ✅)
- Google Sign-In package added
- Login screen implements full flow
- Sends ID token to backend
- Handles authentication response

### Firebase (Already Configured ✅)
- `google-services.json` in place
- OAuth client IDs configured
- Package name: `com.fluentfly.fluentfly`

## Troubleshooting

### If Google Sign-In doesn't work:

1. **Check SHA-1 certificate**
   - The `google-services.json` has a certificate hash: `5947fac461a481dab8d679fdbd39ce87af046ac0`
   - This must match your debug keystore
   - Get your SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`

2. **Check Firebase Console**
   - Go to Firebase Console → Authentication → Sign-in method
   - Make sure Google is enabled
   - Check that SHA-1 is added to your Android app

3. **Check Backend Logs**
   - Look for "Invalid Google token" errors
   - Make sure Firebase Admin SDK is initialized

## Alternative: Use Phone OTP

If Google Sign-In still doesn't work, you can use Phone OTP authentication which is already working:

1. Enter phone number (e.g., +919876543210)
2. Click "Continue with Phone"
3. Check backend terminal for OTP code
4. Enter OTP in app
5. You're logged in!

## Summary

✅ Google Sign-In code is implemented
✅ Backend is ready to handle Google authentication
✅ Firebase is configured

**Next Step**: Run `flutter pub get` and `flutter run` to test it!
