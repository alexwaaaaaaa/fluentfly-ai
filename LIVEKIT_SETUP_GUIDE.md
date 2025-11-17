# LiveKit Setup Guide

LiveKit API keys kaise obtain karein aur configure karein - Complete guide in Hinglish.

## Step 1: LiveKit Cloud Account Banayein

### Option A: LiveKit Cloud (Recommended for Production)

1. **Website par jayein**: https://cloud.livekit.io/

2. **Sign Up karein**:
   - "Sign Up" button par click karein
   - Email aur password enter karein
   - Ya GitHub/Google se sign in karein

3. **Email Verify karein**:
   - Aapke email par verification link aayega
   - Link par click karke account activate karein

4. **Project Create karein**:
   - Dashboard mein "Create Project" par click karein
   - Project name enter karein (e.g., "FluentFly-Production")
   - Region select karein (closest to your users)

### Option B: Self-Hosted LiveKit (Free, for Development)

Agar aap development ke liye free option chahte hain:

```bash
# Docker se LiveKit server run karein
docker run --rm \
  -p 7880:7880 \
  -p 7881:7881 \
  -p 7882:7882/udp \
  -e LIVEKIT_KEYS="devkey: devsecret" \
  livekit/livekit-server \
  --dev
```

Development keys:
- API Key: `devkey`
- API Secret: `devsecret`
- WebSocket URL: `ws://localhost:7880`

## Step 2: API Keys Obtain Karein

### LiveKit Cloud se:

1. **Dashboard mein jayein**: https://cloud.livekit.io/projects

2. **Project select karein**: Apna project click karein

3. **Settings tab kholen**: Left sidebar mein "Settings" par click karein

4. **API Keys section mein jayein**:
   - "API Keys" tab par click karein
   - "Create API Key" button par click karein

5. **Keys copy karein**:
   ```
   API Key: APIxxxxxxxxxxxxxxx
   API Secret: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   WebSocket URL: wss://your-project.livekit.cloud
   ```

   ⚠️ **Important**: API Secret sirf ek baar dikhega, isko safely save kar lein!

## Step 3: Backend Configuration

### Environment Variables Set Karein

`backend/.env` file mein add karein:

```bash
# LiveKit Configuration
LIVEKIT_API_KEY=your_api_key_here
LIVEKIT_API_SECRET=your_api_secret_here
LIVEKIT_WS_URL=wss://your-project.livekit.cloud

# Development ke liye (self-hosted)
# LIVEKIT_API_KEY=devkey
# LIVEKIT_API_SECRET=devsecret
# LIVEKIT_WS_URL=ws://localhost:7880
```

### Verify Configuration

Backend start karke test karein:

```bash
cd backend
npm run start:dev
```

API endpoint test karein:
```bash
curl http://localhost:3000/api/rtc/token?lessonId=1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Step 4: Mobile App Configuration

Mobile app automatically backend se LiveKit URL fetch karega, koi extra configuration nahi chahiye.

Agar direct connection chahiye (testing ke liye):

`mobile/lib/config/constants.dart` mein:

```dart
class AppConstants {
  // ... existing constants
  
  // LiveKit Configuration (optional, for direct connection)
  static const String liveKitUrl = 'wss://your-project.livekit.cloud';
}
```

## Step 5: Testing

### Backend Test:

```bash
cd backend
npm test -- rtc.service.spec.ts
```

### Mobile Test:

```bash
cd mobile
flutter test test/services/livekit_service_test.dart
```

### Integration Test:

1. Backend start karein:
```bash
cd backend
npm run start:dev
```

2. Mobile app run karein:
```bash
cd mobile
flutter run
```

3. Video call feature test karein:
   - Login karein
   - Koi lesson select karein
   - "Start Video Call with AI Tutor" button par click karein
   - Video call connect hona chahiye

## Pricing & Limits

### LiveKit Cloud Free Tier:
- **50 GB bandwidth/month** (free)
- **Unlimited participants**
- **Unlimited rooms**
- **No credit card required** for free tier

### Paid Plans:
- **Starter**: $99/month - 500 GB bandwidth
- **Pro**: $299/month - 2 TB bandwidth
- **Enterprise**: Custom pricing

### Bandwidth Calculation:
- 1 hour video call (720p) ≈ 1-2 GB bandwidth
- 1 hour audio call ≈ 50-100 MB bandwidth
- Free tier = ~25-50 hours of video calls/month

## Troubleshooting

### Error: "LiveKit API credentials not configured"

**Solution**:
```bash
# Check .env file
cat backend/.env | grep LIVEKIT

# Restart backend
cd backend
npm run start:dev
```

### Error: "Connection failed"

**Solution**:
1. Check internet connection
2. Verify WebSocket URL is correct
3. Check firewall settings (ports 7880, 7881, 7882)

### Error: "Token generation failed"

**Solution**:
```bash
# Verify API keys are correct
# Test with curl:
curl -X POST https://cloud.livekit.io/token \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"room": "test-room"}'
```

### Mobile App: "Permission denied"

**Solution**:
- Android: Check `AndroidManifest.xml` has camera/microphone permissions
- iOS: Check `Info.plist` has camera/microphone usage descriptions
- Grant permissions in device settings

## Security Best Practices

1. **Never commit API keys to Git**:
   ```bash
   # .gitignore mein add karein
   echo "backend/.env" >> .gitignore
   ```

2. **Use environment-specific keys**:
   - Development: Self-hosted or separate project
   - Production: LiveKit Cloud with proper keys

3. **Rotate keys regularly**:
   - LiveKit dashboard mein new keys generate karein
   - Old keys disable karein

4. **Monitor usage**:
   - LiveKit dashboard mein usage check karein
   - Alerts set karein for high usage

## Additional Resources

- **LiveKit Documentation**: https://docs.livekit.io/
- **LiveKit GitHub**: https://github.com/livekit/livekit
- **LiveKit Discord**: https://livekit.io/discord
- **API Reference**: https://docs.livekit.io/reference/server/server-apis/

## Quick Start Commands

```bash
# 1. LiveKit Cloud account banayein
open https://cloud.livekit.io/

# 2. API keys copy karein aur .env mein paste karein
nano backend/.env

# 3. Backend start karein
cd backend && npm run start:dev

# 4. Mobile app run karein
cd mobile && flutter run

# 5. Video call test karein
# App mein login -> Lesson select -> Start Video Call
```

## Support

Agar koi problem aaye:
1. Check logs: `backend/logs/` folder
2. Check LiveKit dashboard: https://cloud.livekit.io/
3. Test with self-hosted version first
4. Contact LiveKit support: support@livekit.io

---

**Note**: Development ke liye self-hosted LiveKit use karein (free), production ke liye LiveKit Cloud use karein (better performance, reliability).
