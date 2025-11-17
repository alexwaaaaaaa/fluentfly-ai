# Physical Device Setup Guide

## Current Configuration
- **Laptop IP**: 192.168.31.73
- **Backend API**: http://192.168.31.73:3000/api
- **LiveKit**: ws://192.168.31.73:7880

## Prerequisites
1. ✅ Phone aur laptop **same WiFi network** pe hone chahiye
2. ✅ USB debugging enabled ho (Settings > Developer Options > USB Debugging)
3. ✅ Phone USB se connected ho ya WiFi debugging enabled ho

## Setup Steps

### 1. Check Connected Devices
```bash
cd mobile
flutter devices
```

Tumhe apna phone dikhna chahiye list mein.

### 2. Run App on Physical Device
```bash
# If only one device connected
flutter run

# If multiple devices, specify device ID
flutter run -d <device-id>
```

### 3. Test Backend Connection
App open hone ke baad:
- Login karo
- Home screen pe lessons dikhnge chahiye
- Agar "Network Error" aaye toh check karo:
  - Phone aur laptop same WiFi pe hain
  - Backend running hai: `http://192.168.31.73:3000/health`

### 4. Test Video Call
- Koi bhi lesson open karo
- "Practice with AI" button click karo
- Video call screen open hoga
- Camera/mic permissions allow karo
- AI avatar connect hoga

## Troubleshooting

### Issue: "Network Error" / Cannot connect to backend
**Solution**:
```bash
# Check laptop IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Ping laptop from phone browser
# Open: http://192.168.31.73:3000/health
```

### Issue: Video call timeout
**Solution**:
- Check LiveKit running: `docker ps | grep livekit`
- Restart LiveKit: `docker-compose restart livekit`
- Check firewall not blocking ports 7880, 7881, 7882

### Issue: Camera/Mic not working
**Solution**:
- Go to phone Settings > Apps > FluentFly > Permissions
- Enable Camera and Microphone
- Restart app

## Switch Back to Emulator

Agar emulator pe wapas test karna ho:

1. **Update constants.dart**:
```dart
defaultValue: 'http://10.0.2.2:3000/api', // Emulator
```

2. **Update video_call_screen.dart**:
```dart
url = url.replaceAll('localhost', '10.0.2.2');
```

3. **Run on emulator**:
```bash
flutter run -d emulator-5554
```

## Current Status
✅ Rate limit: 100 tokens/day
✅ Backend running on: http://192.168.31.73:3000
✅ LiveKit running on: ws://192.168.31.73:7880
✅ Mobile app configured for physical device

## Next Steps
1. Connect phone via USB
2. Enable USB debugging
3. Run: `flutter run`
4. Test video call feature!
