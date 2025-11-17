# LiveKit Local Setup for Development

## Problem
Production LiveKit server (`fluentfly-dzxttvr1.livekit.cloud`) is not responding.

## Solution: Use Local LiveKit Server

### Option 1: Docker (Recommended)

1. **Start Local LiveKit Server**:
```bash
docker run --rm -p 7880:7880 -p 7881:7881 -p 7882:7882/udp \
  -e LIVEKIT_KEYS="devkey: secret" \
  livekit/livekit-server:latest \
  --dev
```

2. **Update Backend .env**:
```bash
# Change these lines in backend/.env
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
LIVEKIT_URL=ws://localhost:7880
```

3. **Restart Backend**:
```bash
cd backend
npm run start:dev
```

4. **Test the App** - Video call should work now!

### Option 2: Use LiveKit Cloud (Free Tier)

1. **Sign up**: https://cloud.livekit.io/
2. **Create a project**
3. **Get credentials**:
   - API Key
   - API Secret
   - WebSocket URL

4. **Update backend/.env**:
```bash
LIVEKIT_API_KEY=your-api-key
LIVEKIT_API_SECRET=your-api-secret
LIVEKIT_URL=wss://your-project.livekit.cloud
```

### Quick Test

After setup, test with:
```bash
curl http://localhost:3000/api/rtc/token?lessonId=0
```

Should return a token with the new LiveKit URL.

## Current Issue

Your current LiveKit URL (`fluentfly-dzxttvr1.livekit.cloud`) is not responding:
- Ping: 100% packet loss
- DNS resolves to: 143.223.91.6
- Port 7880: Not accessible

## Recommended: Local Development

For development, use local LiveKit server (Option 1 above).
For production, sign up for LiveKit Cloud free tier.
