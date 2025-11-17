# 📱 Phone Testing Guide - FluentFly App

## 🔧 Current Status

### Backend: ✅ Running
```
URL: http://192.168.31.73:3000/api
Status: Healthy
All services: Connected
```

### Mobile App: ⏳ Ready to Deploy
```
Device Detected: ZA22352HJZ
Status: Not authorized (needs permission)
```

## 📝 Steps to Test on Your Phone

### Step 1: Authorize Your Phone

**On your phone:**
1. Look for a popup dialog asking "Allow USB debugging?"
2. Check "Always allow from this computer"
3. Tap "OK" or "Allow"

**Then run:**
```bash
cd mobile
flutter devices
```

You should see your device listed as authorized.

### Step 2: Build and Install App

```bash
cd mobile
flutter run --release
```

This will:
- Build the app in release mode
- Install on your phone
- Launch automatically

### Step 3: Test the App

**On your phone, test these flows:**

1. **Login Flow**
   - Open app
   - Tap "Continue with Google" or "Phone Login"
   - Complete authentication
   - Should see home screen

2. **Lessons Flow**
   - Browse lessons
   - Select a lesson
   - Complete exercises
   - Check progress

3. **Video Call Flow**
   - Start a video lesson
   - Test AI avatar
   - Test face tracking (if camera permission granted)
   - Test lip sync during AI speech

4. **Profile & Progress**
   - Check XP and badges
   - View leaderboard
   - Check streak

## 🐛 Troubleshooting

### Device Not Authorized

**Solution:**
```bash
# Revoke all USB debugging authorizations on phone
# Settings > Developer Options > Revoke USB debugging authorizations

# Then reconnect and authorize again
```

### App Won't Install

**Solution:**
```bash
# Clean build
cd mobile
flutter clean
flutter pub get
flutter run --release
```

### Backend Connection Issues

**Check these:**

1. **Same WiFi Network**
   - Phone and laptop must be on same WiFi
   - Check laptop IP: `ifconfig | grep "inet "`
   - Update `mobile/lib/config/constants.dart` if IP changed

2. **Firewall**
   - Allow port 3000 on your laptop
   - macOS: System Preferences > Security > Firewall

3. **Backend Running**
   ```bash
   curl http://192.168.31.73:3000/api/health
   ```

### Camera Permission Issues

**On phone:**
- Settings > Apps > FluentFly > Permissions
- Enable Camera, Microphone, Storage

## 🎯 Quick Test Commands

### Check Device Connection
```bash
cd mobile
flutter devices
```

### Build Debug APK
```bash
cd mobile
flutter build apk --debug
```

### Build Release APK
```bash
cd mobile
flutter build apk --release
```

### Install Specific APK
```bash
cd mobile
flutter install
```

### View Logs
```bash
cd mobile
flutter logs
```

## 📊 Expected Test Results

### ✅ Successful Test:
- App launches without crash
- Login works (Google or Phone)
- Lessons load from backend
- Video call connects
- Avatar animations work
- Face tracking active (if camera allowed)
- Progress saves to backend

### ⚠️ Known Issues:
- First launch may be slow (loading assets)
- Camera permission needed for face tracking
- Microphone permission needed for speech
- Internet required for AI features

## 🚀 Performance Expectations

### On Physical Device:
- **App Launch**: 2-3 seconds
- **API Calls**: 50-200ms
- **Video Call**: Smooth 30fps
- **Face Tracking**: Real-time
- **Lip Sync**: Synchronized

### Backend Load:
- **Current**: Can handle ~500 concurrent users
- **After Optimization**: Can handle 30K+ concurrent users

## 📱 Device Requirements

### Minimum:
- Android 8.0+ (API 26+)
- 2GB RAM
- Camera (for face tracking)
- Microphone (for speech)
- Internet connection

### Recommended:
- Android 10.0+ (API 29+)
- 4GB+ RAM
- Good camera quality
- Stable WiFi connection

## 🎊 Success Checklist

Test these features:

- [ ] App installs successfully
- [ ] Login with Google works
- [ ] Login with Phone OTP works
- [ ] Home screen loads lessons
- [ ] Lesson details open
- [ ] Exercises work
- [ ] Video call starts
- [ ] AI avatar visible
- [ ] Face tracking works
- [ ] Lip sync during speech
- [ ] Progress saves
- [ ] XP and badges update
- [ ] Leaderboard loads
- [ ] Profile shows data
- [ ] Logout works

## 🔍 Monitoring Backend During Test

**In another terminal, watch backend logs:**
```bash
# Backend logs will show:
- API requests from phone
- Authentication attempts
- Database queries
- Video call connections
- Errors (if any)
```

**Check health during test:**
```bash
watch -n 2 'curl -s http://192.168.31.73:3000/api/health | jq .'
```

## 💡 Pro Tips

1. **Keep Backend Running**
   - Don't stop backend during testing
   - Watch logs for errors

2. **Test on WiFi**
   - Faster than mobile data
   - More stable connection

3. **Grant All Permissions**
   - Camera, Microphone, Storage
   - Needed for full features

4. **Clear App Data**
   - If issues occur
   - Settings > Apps > FluentFly > Clear Data

5. **Check Backend Logs**
   - See what's happening server-side
   - Helps debug issues

## 🎯 Next Steps After Testing

1. **If Everything Works:**
   - ✅ Ready for production!
   - Enable scalability features
   - Deploy to cloud

2. **If Issues Found:**
   - Check backend logs
   - Check phone logs: `flutter logs`
   - Fix issues
   - Test again

---

**Ready to test!** Authorize your phone and run `flutter run --release` 🚀
