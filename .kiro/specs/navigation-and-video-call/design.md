# Design Document

## Overview

This document outlines the technical design for implementing bottom navigation and AI video call features in the FluentFly application. The design focuses on creating a seamless user experience with efficient real-time communication.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile App (Flutter)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Home Screen  │  │Progress Screen│  │Profile Screen│     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│           └──────────────┬──────────────┘                   │
│                  Bottom Navigation Bar                       │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Video Call Screen (Speaking Practice)         │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐     │  │
│  │  │ Video View │  │ AI Avatar  │  │  Controls  │     │  │
│  │  └────────────┘  └────────────┘  └────────────┘     │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                    LiveKit SDK                               │
└──────────────────────────┼──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend (NestJS)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ RTC Service  │  │  Chat AI     │  │    Speech    │     │
│  │              │  │   Service    │  │   Service    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│          │                 │                  │              │
│          └─────────────────┴──────────────────┘              │
│                          │                                   │
│                    LiveKit Server                            │
└──────────────────────────┼──────────────────────────────────┘
                           │
                           ▼
                    LiveKit Cloud/Self-hosted
```

## Components and Interfaces

### 1. Bottom Navigation Component

**File**: `mobile/lib/widgets/bottom_nav_bar.dart`

```dart
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  // Three tabs: Home (0), Progress (1), Profile (2)
  // Uses BottomNavigationBar widget
  // Theme-aware colors
}
```

**Integration**: Wrap main screens in a scaffold with bottom navigation

**File**: `mobile/lib/screens/main_screen.dart`

```dart
class MainScreen extends StatefulWidget {
  // Manages navigation state
  // Displays Home, Progress, or Profile based on selected index
  // Preserves state when switching tabs
}
```

### 2. Video Call Screen

**File**: `mobile/lib/screens/video_call_screen.dart`

```dart
class VideoCallScreen extends ConsumerStatefulWidget {
  final int lessonId;
  final String topic;
  
  // Manages LiveKit connection
  // Displays local video feed
  // Shows AI avatar overlay
  // Handles call controls
}
```

**State Management**:
```dart
class VideoCallState {
  bool isConnected;
  bool isMuted;
  bool isCameraOn;
  Duration callDuration;
  List<ConversationTurn> turns;
  ConnectionQuality quality;
}
```

### 3. LiveKit Integration Service

**File**: `mobile/lib/services/livekit_service.dart`

```dart
class LiveKitService {
  // Initialize LiveKit room
  Future<Room> connectToRoom(String token, String url);
  
  // Publish local audio/video
  Future<void> publishTracks(Room room);
  
  // Subscribe to remote tracks
  void subscribeToRemoteTracks(Room room);
  
  // Handle connection events
  void setupEventListeners(Room room);
  
  // Disconnect and cleanup
  Future<void> disconnect(Room room);
}
```

### 4. Backend RTC Controller

**File**: `backend/src/modules/rtc/rtc.controller.ts`

```typescript
@Controller('rtc')
export class RtcController {
  // Generate LiveKit token for user
  @Get('token')
  async getToken(@Query('lessonId') lessonId: number): Promise<TokenResponse>
  
  // Create AI agent for room
  @Post('agent')
  async createAgent(@Body() dto: CreateAgentDto): Promise<AgentResponse>
  
  // End session and save analytics
  @Post('end-session')
  async endSession(@Body() dto: EndSessionDto): Promise<void>
}
```

### 5. AI Agent Service

**File**: `backend/src/modules/rtc/ai-agent.service.ts`

```typescript
export class AiAgentService {
  // Spawn AI participant in LiveKit room
  async spawnAgent(roomName: string, lessonContext: any): Promise<void>
  
  // Process user speech and generate response
  async handleUserSpeech(audioBuffer: Buffer): Promise<string>
  
  // Convert AI text to speech
  async generateSpeech(text: string): Promise<Buffer>
  
  // Publish audio to room
  async publishAudio(room: Room, audioBuffer: Buffer): Promise<void>
}
```

## Data Models

### Video Call Session

```typescript
interface VideoCallSession {
  id: string;
  userId: number;
  lessonId: number;
  roomName: string;
  startTime: Date;
  endTime?: Date;
  duration: number; // seconds
  conversationTurns: ConversationTurn[];
  analytics: CallAnalytics;
}

interface ConversationTurn {
  speaker: 'user' | 'ai';
  text: string;
  timestamp: Date;
  audioUrl?: string;
}

interface CallAnalytics {
  totalSpeakingTime: number; // seconds
  wordsPerMinute: number;
  pauseCount: number;
  averagePauseLength: number; // seconds
  fluencyScore: number; // 0-100
}
```

### LiveKit Token Response

```typescript
interface TokenResponse {
  token: string;
  url: string;
  roomName: string;
  expiresAt: Date;
}
```

## Error Handling

### Mobile App Errors

1. **Permission Denied**: Show dialog explaining why permissions are needed with link to settings
2. **Connection Failed**: Retry with exponential backoff (1s, 2s, 4s)
3. **Poor Network**: Display warning, reduce video quality
4. **Token Expired**: Request new token automatically
5. **Unexpected Disconnect**: Save session state, offer to reconnect

### Backend Errors

1. **LiveKit Server Unavailable**: Return 503 with retry-after header
2. **Token Generation Failed**: Log error, return 500
3. **AI Service Timeout**: Return cached response or generic fallback
4. **Invalid Room**: Return 404 with error message

## Testing Strategy

### Unit Tests

**Mobile**:
- Bottom navigation state management
- LiveKit service connection logic
- Video call state transitions
- Analytics calculation

**Backend**:
- Token generation with correct permissions
- AI agent spawning logic
- Session data persistence
- Error handling scenarios

### Integration Tests

**Mobile**:
- Navigation between tabs preserves state
- Video call connects to LiveKit successfully
- Audio/video tracks publish correctly
- Call controls work as expected

**Backend**:
- End-to-end token generation and validation
- AI agent joins room and responds to speech
- Session analytics saved correctly
- Multiple concurrent calls handled

### Manual Testing

1. **Navigation Flow**: Switch between all tabs, verify state persistence
2. **Video Call Happy Path**: Start call, speak, receive AI response, end call
3. **Network Interruption**: Disconnect WiFi during call, verify reconnection
4. **Permission Scenarios**: Deny permissions, verify error handling
5. **Long Call**: Test 30-minute call, verify auto-end
6. **Multiple Devices**: Test concurrent calls from different users

## Performance Considerations

### Mobile App

1. **Video Quality**: Adaptive bitrate based on network (360p to 720p)
2. **Battery Usage**: Optimize camera/microphone usage, pause when backgrounded
3. **Memory**: Limit conversation history to last 50 turns
4. **Startup Time**: Lazy load LiveKit SDK, preload on app start

### Backend

1. **Concurrent Calls**: Support up to 100 simultaneous video calls
2. **AI Response Time**: Target < 2 seconds for speech-to-response-to-speech
3. **Token Generation**: Cache LiveKit credentials, generate tokens in < 100ms
4. **Database**: Index session data by userId and lessonId for fast queries

## Security Considerations

1. **Token Security**: Short-lived tokens (1 hour), signed with secret key
2. **Room Access**: Validate user has access to lesson before generating token
3. **Data Privacy**: Encrypt audio/video streams in transit (WebRTC DTLS)
4. **Session Recording**: Only store transcripts, not raw audio/video
5. **Rate Limiting**: Max 10 video calls per user per day

## Deployment

### Mobile App

1. Add LiveKit Flutter SDK dependency: `livekit_client: ^2.0.0`
2. Update Android permissions in `AndroidManifest.xml`
3. Update iOS permissions in `Info.plist`
4. Build and test on physical devices (emulator has camera limitations)

### Backend

1. Install LiveKit server (Docker or cloud-hosted)
2. Configure LiveKit credentials in environment variables
3. Deploy AI agent service (can run as separate process)
4. Set up monitoring for call quality metrics
5. Configure CDN for serving AI avatar assets

## Migration Plan

### Phase 1: Bottom Navigation (Week 1)
- Implement navigation bar widget
- Create main screen wrapper
- Update routing logic
- Test navigation flows

### Phase 2: Video Call UI (Week 2)
- Implement video call screen
- Add LiveKit SDK integration
- Create call controls
- Test basic connectivity

### Phase 3: AI Agent (Week 3)
- Implement backend AI agent service
- Integrate speech-to-text and text-to-speech
- Connect to chat AI service
- Test conversation flow

### Phase 4: Polish & Testing (Week 4)
- Add analytics tracking
- Implement error handling
- Performance optimization
- End-to-end testing
- User acceptance testing

## Open Questions

1. Should we use LiveKit Cloud or self-host LiveKit server?
2. What's the budget for LiveKit usage (charged per minute)?
3. Should we record video calls for quality assurance?
4. Do we need to support group video calls (multiple users)?
5. Should AI avatar be animated 3D or 2D illustration?
