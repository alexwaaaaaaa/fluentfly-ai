# Android Emulator Connection Fix

## Problem
App is unable to connect to backend server running on `localhost:3000` from Android emulator.

## Root Cause
Android emulator runs in isolated network. `localhost` or `127.0.0.1` refers to emulator itself, not host machine.

## Solutions Tried

### ✅ 1. Changed API URL to 10.0.2.2
- Updated `mobile/lib/config/constants.dart`
- Changed from `http://localhost:3000/api` to `http://10.0.2.2:3000/api`
- `10.0.2.2` is special alias for host machine's localhost in Android emulator

### ✅ 2. Backend listening on 0.0.0.0
- Updated `backend/src/main.ts`
- Changed from `app.listen(port)` to `app.listen(port, '0.0.0.0')`
- This allows connections from external sources (including emulator)

## Current Status
- Backend is running on `0.0.0.0:3000` ✅
- Mobile app is configured to use `10.0.2.2:3000` ✅
- Connection still timing out ❌

## Additional Troubleshooting Steps

### Option 1: Test Network Connectivity from Emulator

Run this from emulator's terminal (adb shell):
```bash
adb shell
curl http://10.0.2.2:3000/api/health
```

If this works, the issue is in the app. If not, it's a network/firewall issue.

### Option 2: Check Firewall Settings

macOS Firewall might be blocking connections:
1. System Preferences → Security & Privacy → Firewall
2. Click "Firewall Options"
3. Ensure Node.js is allowed to accept incoming connections

### Option 3: Use ngrok for Testing

Temporarily expose backend via ngrok:
```bash
# Install ngrok
brew install ngrok

# Expose backend
ngrok http 3000

# Update mobile app to use ngrok URL
# e.g., https://abc123.ngrok.io/api
```

### Option 4: Restart Emulator with Network Reset

```bash
# Stop emulator
adb emu kill

# Start fresh emulator
flutter emulators --launch <emulator-id>

# Or from Android Studio
# Tools → AVD Manager → Cold Boot Now
```

### Option 5: Use Physical Device

Connect physical Android device via USB:
```bash
# Enable USB debugging on device
# Connect via USB
adb devices

# Run app
flutter run
```

Device will use WiFi to connect to backend on same network.

### Option 6: Bypass Auth for Testing

Temporarily disable authentication to test if connection works:

1. Comment out JWT guard in backend
2. Test with `/api/lessons` endpoint (no auth required)
3. If this works, issue is specifically with auth endpoint

## Recommended Next Steps

1. **Test with ngrok** - Quickest way to verify if issue is network-related
2. **Try physical device** - Most reliable for development
3. **Check firewall** - Common issue on macOS
4. **Cold boot emulator** - Reset network stack

## Alternative: Use Google OAuth

Since Firebase Phone OTP is not configured, use Google OAuth instead:
1. Tap "Continue with Google" button
2. This uses Firebase Google Auth which is configured
3. Bypasses phone OTP entirely

## Commands to Run

```bash
# Check if backend is accessible from host
curl http://localhost:3000/api/health

# Check if backend is accessible on 0.0.0.0
curl http://0.0.0.0:3000/api/health

# Check from emulator (run in separate terminal)
adb shell
curl http://10.0.2.2:3000/api/health
```

## Expected Behavior

When working correctly:
- Backend logs should show incoming requests
- Mobile app should receive responses within 1-2 seconds
- No timeout errors

## Current Logs Show

- ❌ Connection timeout after 30 seconds
- ❌ No requests reaching backend
- ❌ Retry attempts all failing

This indicates network is not reaching backend at all.
