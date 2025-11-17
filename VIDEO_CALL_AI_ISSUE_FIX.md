# 🔧 Video Call AI Response Issue - Fix Guide

## 🐛 Problem Identified

**Issue**: AI agent not responding during video call

**Root Cause**: Azure Speech Service failing
```
Speech synthesis failed: Unable to contact server. StatusCode: 1006
wss://eastus.tts.speech.microsoft.com/tts/cognitiveservices/websocket/v1
```

**Why**: Invalid Azure Speech key in `.env` file
```
AZURE_SPEECH_KEY=your-azure-speech-key  ❌ (placeholder, not real key)
```

## ✅ Solution Options

### Option 1: Use Valid Azure Speech Key (Recommended)

1. **Get Azure Speech Key**:
   - Go to https://portal.azure.com
   - Create "Speech Service" resource
   - Copy API key

2. **Update `.env`**:
   ```bash
   AZURE_SPEECH_KEY=your-actual-azure-key-here
   AZURE_SPEECH_REGION=eastus
   ```

3. **Restart Backend**:
   ```bash
   # Backend will auto-reload in dev mode
   # Or restart manually
   ```

### Option 2: Use ElevenLabs (Already Have Key!)

You already have ElevenLabs key in `.env`:
```
ELEVENLABS_API_KEY=sk_41451706253559468b0198d075811dcef7933c97170fde60
```

**Need to integrate ElevenLabs in code** (requires code changes)

### Option 3: Quick Test with Mock Response (Temporary)

For testing purposes, we can add a fallback that doesn't require TTS.

## 🚀 Quick Fix (Option 1 - Azure)

### Step 1: Get Free Azure Speech Key

1. Go to https://azure.microsoft.com/free/
2. Sign up for free account (gets $200 credit)
3. Create Speech Service:
   - Search "Speech Services"
   - Click "Create"
   - Select free tier (F0)
   - Copy Key 1

### Step 2: Update Backend

```bash
# Edit backend/.env
AZURE_SPEECH_KEY=<your-actual-key>
AZURE_SPEECH_REGION=eastus
```

### Step 3: Test

Backend will auto-reload. Try video call again!

## 📊 What's Working vs Not Working

### ✅ Working:
- Video call connection
- LiveKit integration
- AI agent initialization
- User authentication
- Room creation
- Session tracking

### ❌ Not Working:
- AI speech synthesis (TTS)
- AI greeting message
- AI responses to user speech

### ⏳ Partially Working:
- AI agent spawns successfully
- Ready to process audio
- But can't speak back (no TTS)

## 🔍 Backend Logs Analysis

```
✅ Token generated successfully
✅ AI agent spawn requested
✅ AI agent token generated
✅ Initializing greeting
❌ Speech synthesis failed (Azure connection error)
⚠️  AI agent initialized (but can't speak)
```

## 💡 Why This Happens

1. **AI Agent Flow**:
   ```
   User speaks → STT (Speech-to-Text) → AI processes → 
   TTS (Text-to-Speech) → AI speaks back
   ```

2. **Current State**:
   ```
   User speaks → ✅ STT works → ✅ AI processes → 
   ❌ TTS fails → ❌ No audio response
   ```

3. **Missing Link**: Text-to-Speech (TTS) service

## 🎯 Recommended Solution

**Use Azure Speech (Free Tier)**:
- 5 hours of audio/month free
- Good quality
- Low latency
- Already integrated in code

**Steps**:
1. Get Azure free account
2. Create Speech Service (F0 tier)
3. Copy key to `.env`
4. Restart backend
5. Test video call

## 📝 Alternative: Integrate ElevenLabs

If you prefer ElevenLabs (you already have the key):

### Code Changes Needed:

1. **Install ElevenLabs SDK** (already installed):
   ```bash
   # Already in package.json
   @elevenlabs/elevenlabs-js: ^2.23.0
   ```

2. **Update `speech.service.ts`**:
   ```typescript
   import { ElevenLabsClient } from '@elevenlabs/elevenlabs-js';
   
   // Add ElevenLabs client
   private elevenLabsClient: ElevenLabsClient;
   
   constructor() {
     this.elevenLabsClient = new ElevenLabsClient({
       apiKey: process.env.ELEVENLABS_API_KEY,
     });
   }
   
   // Use ElevenLabs for TTS
   async textToSpeech(text: string) {
     const audio = await this.elevenLabsClient.generate({
       voice: "Rachel",
       text: text,
       model_id: "eleven_monolingual_v1"
     });
     return audio;
   }
   ```

## 🎊 Expected Result After Fix

### Before Fix:
```
User: "Hello"
AI: [silence] ❌
```

### After Fix:
```
User: "Hello"
AI: "Hello! I'm your AI tutor. How can I help you today?" ✅
```

## 🔧 Testing After Fix

1. **Start Video Call**
2. **Wait for AI greeting** (should hear voice)
3. **Speak something**
4. **AI should respond** with voice

## 📚 Additional Notes

### Free Tier Limits:

**Azure Speech (F0)**:
- 5 hours audio/month
- 1 concurrent request
- Perfect for testing

**ElevenLabs (Free)**:
- 10,000 characters/month
- ~2-3 hours of audio
- Good quality voices

### Cost for Production:

**Azure Speech (S0)**:
- $1 per hour of audio
- Unlimited concurrent
- Pay as you go

**ElevenLabs (Starter)**:
- $5/month
- 30,000 characters
- Better voice quality

## 🎯 Quick Action Items

**Right Now**:
1. Get Azure Speech key (5 mins)
2. Update `.env` file
3. Test video call

**Later** (Optional):
1. Integrate ElevenLabs
2. Add fallback logic
3. Implement caching

---

**Current Status**: Video call works, AI agent ready, just needs TTS service! 🎤
